import Foundation

extension Notification.Name {
    static let authDidChange = Notification.Name("woart.authDidChange")
}

/// Server-backed session. The bearer token lives in the keychain; the last
/// known profile is cached so the app can paint the signed-in UI immediately
/// on launch and then reconcile with `GET /v1/auth/session`.
final class AuthService {
    static let shared = AuthService()

    private let userCacheKey = "woart.currentUser.v2"
    private(set) var currentUser: APIUser?
    private(set) var token: String?

    var isSignedIn: Bool { token != nil && currentUser != nil }
    var currentUsername: String? { currentUser?.username }

    private init() {
        token = SessionTokenStore.token
        if let data = UserDefaults.standard.data(forKey: userCacheKey),
           let user = try? JSONDecoder().decode(APIUser.self, from: data) {
            currentUser = user
        }
        if token == nil {
            currentUser = nil
            UserDefaults.standard.removeObject(forKey: userCacheKey)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionExpired),
            name: .apiSessionExpired,
            object: nil
        )
    }

    // MARK: - Entry points

    @discardableResult
    func register(username: String, password: String, displayName: String?) async throws -> APIUser {
        let session = try await APIClient.shared.register(
            username: username.lowercased(),
            password: password,
            displayName: displayName
        )
        apply(session)
        return session.user
    }

    @discardableResult
    func signIn(username: String, password: String) async throws -> APIUser {
        let session = try await APIClient.shared.login(
            username: username.lowercased(),
            password: password
        )
        apply(session)
        return session.user
    }

    @discardableResult
    func signInWithApple(identityToken: String, fullName: String?) async throws -> APIUser {
        let session = try await APIClient.shared.signInWithApple(
            identityToken: identityToken,
            fullName: fullName
        )
        apply(session)
        return session.user
    }

    /// Reconciles the cached profile with the server. A 401 clears the session;
    /// a network failure keeps the cached view.
    func validateSession() async {
        guard token != nil else { return }
        do {
            let user = try await APIClient.shared.currentSession()
            updateCurrentUser(user)
        } catch let error as APIError where error.isUnauthorized {
            clearLocalSession()
        } catch {
            // Offline: keep the cached profile.
        }
    }

    func updateCurrentUser(_ user: APIUser) {
        guard token != nil else { return }
        currentUser = user
        persistUser()
        NotificationCenter.default.post(name: .authDidChange, object: nil)
    }

    func signOut() {
        let oldToken = token
        clearLocalSession()
        if let oldToken {
            Task { await APIClient.shared.logout(token: oldToken) }
        }
    }

    func deleteAccount() async throws {
        try await APIClient.shared.deleteAccount()
        clearLocalSession()
    }

    // MARK: - Internals

    private func apply(_ session: APISession) {
        SessionTokenStore.write(session.token)
        token = session.token
        currentUser = session.user
        persistUser()
        NotificationCenter.default.post(name: .authDidChange, object: nil)
    }

    private func clearLocalSession() {
        SessionTokenStore.clear()
        token = nil
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userCacheKey)
        NotificationCenter.default.post(name: .authDidChange, object: nil)
    }

    private func persistUser() {
        guard let user = currentUser, let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: userCacheKey)
    }

    @objc private func sessionExpired() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.token != nil else { return }
            self.clearLocalSession()
        }
    }
}
