import Foundation

extension Notification.Name {
    static let apiSessionExpired = Notification.Name("woart.apiSessionExpired")
}

enum APIConfig {
    /// Override for local testing, e.g.
    /// UserDefaults.standard.set("http://127.0.0.1:8787/v1", forKey: "woart.apiBase")
    static var baseURL: URL {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["WOART_API_BASE"],
           let url = URL(string: raw) {
            return url
        }
        if let raw = UserDefaults.standard.string(forKey: "woart.apiBase"),
           let url = URL(string: raw) {
            return url
        }
        #endif
        return URL(string: "https://api.woart.app/v1")!
    }

    /// Keeps media URLs usable when the API points at a local Worker.
    static func resolveMediaURL(_ raw: String?) -> URL? {
        guard let raw, var components = URLComponents(string: raw) else { return nil }
        #if DEBUG
        if components.host == "api.woart.app",
           let override = URL(string: baseURL.absoluteString),
           let host = override.host {
            components.scheme = override.scheme
            components.host = host
            components.port = override.port
        }
        #endif
        return components.url
    }
}

enum SessionTokenStore {
    private static let service = "com.woart.session"
    private static let account = "bearer-token"
    private static let debugFallbackKey = "woart.debug.token"

    static var token: String? {
        if let data = KeychainStore.read(service: service, account: account),
           let value = String(data: data, encoding: .utf8),
           !value.isEmpty {
            return value
        }
        #if DEBUG
        // Unsigned simulator builds have no keychain entitlement (-34018);
        // this fallback never ships in Release.
        let fallback = UserDefaults.standard.string(forKey: debugFallbackKey)
        return (fallback?.isEmpty ?? true) ? nil : fallback
        #else
        return nil
        #endif
    }

    static func write(_ token: String) {
        let saved = KeychainStore.write(Data(token.utf8), service: service, account: account)
        #if DEBUG
        if !saved {
            UserDefaults.standard.set(token, forKey: debugFallbackKey)
        }
        #else
        _ = saved
        #endif
    }

    static func clear() {
        KeychainStore.delete(service: service, account: account)
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: debugFallbackKey)
        #endif
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        configuration.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024,
            diskPath: "woart-api-cache"
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        session = URLSession(configuration: configuration)
    }

    /// JSONDecoder is not documented as thread-safe; requests can overlap, so
    /// each response gets a fresh decoder.
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = APIClient.fractionalFormatter.date(from: raw) ?? APIClient.plainFormatter.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown ISO 8601 date: \(raw)"
            )
        }
        return decoder
    }

    private static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plainFormatter = ISO8601DateFormatter()

    // MARK: - Auth

    func register(username: String, password: String, displayName: String?) async throws -> APISession {
        var body: [String: Any] = ["username": username, "password": password]
        if let displayName, !displayName.isEmpty { body["displayName"] = displayName }
        return try await request("auth/register", method: "POST", body: body, authorized: false)
    }

    func login(username: String, password: String) async throws -> APISession {
        try await request(
            "auth/login",
            method: "POST",
            body: ["username": username, "password": password],
            authorized: false
        )
    }

    func signInWithApple(identityToken: String, fullName: String?) async throws -> APISession {
        var body: [String: Any] = ["identityToken": identityToken]
        if let fullName, !fullName.isEmpty { body["fullName"] = fullName }
        return try await request("auth/apple", method: "POST", body: body, authorized: false)
    }

    func currentSession() async throws -> APIUser {
        let envelope: APIUserEnvelope = try await request("auth/session")
        return envelope.user
    }

    func logout(token: String) async {
        _ = try? await send(
            "auth/logout",
            method: "POST",
            body: nil,
            token: token,
            authorized: false
        )
    }

    func deleteAccount() async throws {
        _ = try await send("me", method: "DELETE", body: nil, token: SessionTokenStore.token, authorized: true)
    }

    func usernameAvailable(_ username: String) async throws -> APIAvailabilityResponse {
        try await request(
            "auth/username-available",
            query: [URLQueryItem(name: "username", value: username)],
            authorized: false
        )
    }

    // MARK: - Me

    func me() async throws -> APIUser {
        let envelope: APIUserEnvelope = try await request("me")
        return envelope.user
    }

    func updateMe(
        displayName: String?,
        bio: String?,
        location: String?,
        craft: String?,
        avatarUrl: String?
    ) async throws -> APIUser {
        var body: [String: Any] = [:]
        if let displayName { body["displayName"] = displayName }
        if let bio { body["bio"] = bio }
        if let location { body["location"] = location }
        if let craft { body["craft"] = craft }
        if let avatarUrl { body["avatarUrl"] = avatarUrl }
        let envelope: APIUserEnvelope = try await request("me", method: "PATCH", body: body)
        return envelope.user
    }

    func myPosts() async throws -> APIList<APIPost> {
        try await request("me/posts")
    }

    func myLikes() async throws -> APIList<APIPost> {
        try await request("me/likes")
    }

    func myFollowing() async throws -> APIList<APIUser> {
        try await request("me/following")
    }

    func myEvents() async throws -> APIList<APIEvent> {
        try await request("me/events")
    }

    func myFriendRequests() async throws -> APIList<APIFriendRequest> {
        try await request("me/friend-requests")
    }

    func myBlocks() async throws -> APIList<APIUser> {
        try await request("me/blocks")
    }

    // MARK: - Feed & posts

    func feed(limit: Int = 50, cursor: String? = nil) async throws -> APIList<APIPost> {
        var query = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
        return try await request("feed", query: query)
    }

    func post(id: String) async throws -> APIPost {
        let envelope: APIPostEnvelope = try await request("posts/\(encode(id))")
        return envelope.post
    }

    func createPost(title: String, body: String, tags: [String], mediaIds: [String]) async throws -> APIPost {
        let media = mediaIds.map { ["mediaId": $0] }
        let payload: [String: Any] = [
            "title": title,
            "body": body,
            "tags": tags,
            "media": media
        ]
        let envelope: APIPostEnvelope = try await request("posts", method: "POST", body: payload)
        return envelope.post
    }

    func deletePost(id: String) async throws {
        _ = try await send("posts/\(encode(id))", method: "DELETE", body: nil, token: SessionTokenStore.token, authorized: true)
    }

    func like(postID: String) async throws -> APILikeResponse {
        try await request("posts/\(encode(postID))/like", method: "POST", body: nil)
    }

    func unlike(postID: String) async throws -> APILikeResponse {
        try await request("posts/\(encode(postID))/like", method: "DELETE", body: nil)
    }

    func comments(postID: String, limit: Int = 100) async throws -> APIList<APIComment> {
        try await request(
            "posts/\(encode(postID))/comments",
            query: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }

    func createComment(postID: String, text: String) async throws -> APIComment {
        let envelope: APICommentEnvelope = try await request(
            "posts/\(encode(postID))/comments",
            method: "POST",
            body: ["text": text]
        )
        return envelope.comment
    }

    func deleteComment(id: String) async throws {
        _ = try await send("comments/\(encode(id))", method: "DELETE", body: nil, token: SessionTokenStore.token, authorized: true)
    }

    // MARK: - Makers

    func makers(query: String? = nil, limit: Int = 50) async throws -> APIList<APIUser> {
        var items = [URLQueryItem(name: "limit", value: String(limit))]
        if let query, !query.isEmpty { items.append(URLQueryItem(name: "query", value: query)) }
        return try await request("makers", query: items)
    }

    func maker(id: String) async throws -> APIUser {
        let envelope: APIMakerEnvelope = try await request("makers/\(encode(id))")
        return envelope.maker
    }

    func makerPosts(id: String, limit: Int = 50) async throws -> APIList<APIPost> {
        try await request(
            "makers/\(encode(id))/posts",
            query: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }

    func follow(makerID: String) async throws -> APIFollowResponse {
        try await request("makers/\(encode(makerID))/follow", method: "POST", body: nil)
    }

    func unfollow(makerID: String) async throws -> APIFollowResponse {
        try await request("makers/\(encode(makerID))/follow", method: "DELETE", body: nil)
    }

    func requestFriend(makerID: String) async throws -> APIFriendStateResponse {
        try await request("makers/\(encode(makerID))/friend-request", method: "POST", body: nil)
    }

    func acceptFriend(makerID: String) async throws -> APIFriendStateResponse {
        try await request("makers/\(encode(makerID))/friend-accept", method: "POST", body: nil)
    }

    func removeFriend(makerID: String) async throws -> APIFriendStateResponse {
        try await request("makers/\(encode(makerID))/friend", method: "DELETE", body: nil)
    }

    func block(makerID: String) async throws {
        _ = try await send("makers/\(encode(makerID))/block", method: "POST", body: nil, token: SessionTokenStore.token, authorized: true)
    }

    func unblock(makerID: String) async throws {
        _ = try await send("makers/\(encode(makerID))/block", method: "DELETE", body: nil, token: SessionTokenStore.token, authorized: true)
    }

    // MARK: - Events

    func events(scope: String = "upcoming", limit: Int = 50) async throws -> APIList<APIEvent> {
        try await request(
            "events",
            query: [
                URLQueryItem(name: "scope", value: scope),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }

    func event(id: String) async throws -> APIEvent {
        let envelope: APIEventEnvelope = try await request("events/\(encode(id))")
        return envelope.event
    }

    func createEvent(
        title: String,
        summary: String,
        details: String,
        location: String,
        startAt: Date,
        capacity: Int,
        tags: [String],
        posterMediaId: String?
    ) async throws -> APIEvent {
        var payload: [String: Any] = [
            "title": title,
            "summary": summary,
            "details": details,
            "location": location,
            "startAt": APIClient.fractionalFormatter.string(from: startAt),
            "capacity": capacity,
            "tags": tags
        ]
        if let posterMediaId { payload["posterMediaId"] = posterMediaId }
        let envelope: APIEventEnvelope = try await request("events", method: "POST", body: payload)
        return envelope.event
    }

    func deleteEvent(id: String) async throws {
        _ = try await send("events/\(encode(id))", method: "DELETE", body: nil, token: SessionTokenStore.token, authorized: true)
    }

    func reserve(eventID: String) async throws -> APIReservationResponse {
        try await request("events/\(encode(eventID))/reservation", method: "POST", body: nil)
    }

    func cancelReservation(eventID: String) async throws -> APIReservationResponse {
        try await request("events/\(encode(eventID))/reservation", method: "DELETE", body: nil)
    }

    // MARK: - Media

    func uploadMedia(
        fileURL: URL,
        mimeType: String,
        kind: MediaKind,
        width: Int?,
        height: Int?,
        aspect: Double?,
        posterURL: URL?
    ) async throws -> APIMediaUpload {
        let fileData: Data
        do {
            fileData = try Data(contentsOf: fileURL)
        } catch {
            throw APIError(statusCode: -1, code: "file_missing", message: "That file could not be read. Try choosing it again.")
        }

        let boundary = "WoArt-\(UUID().uuidString)"
        var body = Data()

        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        func appendFile(_ name: String, fileName: String, mime: String, data: Data) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!
            )
            body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }

        if let width { appendField("width", String(width)) }
        if let height { appendField("height", String(height)) }
        if let aspect { appendField("aspect", String(format: "%.3f", aspect)) }
        appendFile("file", fileName: fileURL.lastPathComponent, mime: mimeType, data: fileData)

        if let posterURL, let posterData = try? Data(contentsOf: posterURL), !posterData.isEmpty {
            appendFile("poster", fileName: posterURL.lastPathComponent, mime: "image/jpeg", data: posterData)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = try makeRequest(path: "media", method: "POST", query: [])
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
        request.httpBody = body
        if let token = SessionTokenStore.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await perform(request, authorized: true)
        try validate(response, data: data, authorized: true)
        let envelope: APIMediaEnvelope = try APIClient.makeDecoder().decode(APIMediaEnvelope.self, from: data)
        return envelope.media
    }

    // MARK: - Reports

    func report(targetType: String, targetId: String, reason: String, details: String?) async throws -> APIReportResponse {
        var body: [String: Any] = [
            "targetType": targetType,
            "targetId": targetId,
            "reason": reason
        ]
        if let details, !details.isEmpty { body["details"] = details }
        return try await request("reports", method: "POST", body: body)
    }

    // MARK: - Core

    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Any? = nil,
        authorized: Bool = true
    ) async throws -> T {
        let request = try makeRequest(path: path, method: method, query: query, body: body)
        let (data, response) = try await perform(request, authorized: authorized)
        try validate(response, data: data, authorized: authorized)
        do {
            return try APIClient.makeDecoder().decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("WoArtAPI decode error for \(path):", error)
            #endif
            throw APIError(statusCode: response.statusCode, code: "decode", message: "The atelier sent something unexpected. Please try again.")
        }
    }

    private func send(
        _ path: String,
        method: String,
        body: Any?,
        token: String?,
        authorized: Bool
    ) async throws -> Data {
        var request = try makeRequest(path: path, method: method, query: [], body: body)
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await perform(request, authorized: authorized)
        try validate(response, data: data, authorized: authorized)
        return data
    }

    private func makeRequest(
        path: String,
        method: String,
        query: [URLQueryItem],
        body: Any? = nil
    ) throws -> URLRequest {
        var components = URLComponents(
            url: APIConfig.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        if !query.isEmpty { components?.queryItems = query }
        guard let url = components?.url else {
            throw APIError(statusCode: -1, code: "bad_url", message: "Could not build the request.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = SessionTokenStore.token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    private func perform(_ request: URLRequest, authorized: Bool) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError(statusCode: -1, code: "bad_response", message: "The atelier did not answer properly.")
            }
            return (data, http)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError(
                statusCode: -1,
                code: "network",
                message: "You're offline or the atelier can't be reached. Check your connection and try again."
            )
        }
    }

    private func validate(_ response: HTTPURLResponse, data: Data, authorized: Bool) throws {
        guard (200..<300).contains(response.statusCode) else {
            let parsed = try? APIClient.makeDecoder().decode(APIErrorEnvelope.self, from: data)
            let error = APIError(
                statusCode: response.statusCode,
                code: parsed?.error.code ?? "http_\(response.statusCode)",
                message: parsed?.error.message ?? "Something went wrong. Please try again."
            )
            if error.isUnauthorized && authorized {
                NotificationCenter.default.post(name: .apiSessionExpired, object: nil)
            }
            throw error
        }
    }

    private func encode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }

}

private struct APIMakerEnvelope: Codable {
    let maker: APIUser
}

struct APIFriendRequest: Codable {
    let maker: APIUser
    let createdAt: Date
}

struct APIReportResponse: Codable {
    let report: APIReport
    let hidden: Bool
    let blocked: Bool
}

struct APIReport: Codable {
    let id: String
    let targetType: String
    let targetId: String
    let reason: String
    let status: String
    let createdAt: Date
}
