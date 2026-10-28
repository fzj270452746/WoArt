import Foundation

// MARK: - Users

struct APIUser: Codable, Hashable {
    let id: String
    let username: String
    let handle: String
    let displayName: String
    let bio: String
    let location: String
    let craft: String
    let avatarUrl: String?
    let coverUrl: String?
    let followerCount: Int
    let followingCount: Int
    let postCount: Int
    let isSeed: Bool
    let isMe: Bool
    let isFollowing: Bool
    let friendState: String

    var isCurrentUser: Bool { isMe }
}

struct APIMedia: Codable, Hashable {
    let id: String
    let kind: String
    let url: String
    let posterUrl: String?
    let aspect: Double
    let width: Int?
    let height: Int?
}

struct APIPost: Codable, Hashable {
    let id: String
    let author: APIUser
    let title: String
    let body: String
    let media: [APIMedia]
    let tags: [String]
    let likeCount: Int
    let commentCount: Int
    let liked: Bool
    let createdAt: Date
}

struct APIComment: Codable, Hashable {
    let id: String
    let postId: String
    let author: APIUser
    let text: String
    let createdAt: Date
}

struct APIEvent: Codable, Hashable {
    let id: String
    let host: APIUser
    let title: String
    let summary: String
    let details: String
    let location: String
    let startAt: Date
    let capacity: Int
    let reservedCount: Int
    let seatsLeft: Int
    let isReserved: Bool
    let posterUrl: String?
    let tags: [String]
    let createdAt: Date
}

// MARK: - Envelopes

struct APIErrorBody: Codable {
    let code: String
    let message: String
}

struct APIErrorEnvelope: Codable {
    let error: APIErrorBody
}

struct APIList<T: Codable>: Codable {
    let items: [T]
    let nextCursor: String?
}

struct APIUserEnvelope: Codable {
    let user: APIUser
}

struct APISession: Codable {
    let token: String
    let expiresAt: Date?
    let user: APIUser
}

struct APIPostEnvelope: Codable {
    let post: APIPost
}

struct APICommentEnvelope: Codable {
    let comment: APIComment
}

struct APIEventEnvelope: Codable {
    let event: APIEvent
}

struct APIMediaEnvelope: Codable {
    let media: APIMediaUpload
}

struct APIMediaUpload: Codable {
    let id: String
    let kind: String
    let url: String
    let posterUrl: String?
    let aspect: Double
    let width: Int?
    let height: Int?
    let bytes: Int?
    let mime: String?
}

struct APILikeResponse: Codable {
    let liked: Bool
    let likeCount: Int
}

struct APIFollowResponse: Codable {
    let following: Bool
    let followerCount: Int
}

struct APIFriendStateResponse: Codable {
    let friendState: String
}

struct APIReservationResponse: Codable {
    let reserved: Bool
    let reservedCount: Int
    let seatsLeft: Int
}

struct APIAvailabilityResponse: Codable {
    let available: Bool
    let reason: String?
}

struct APIEmptyResponse: Codable {}

// MARK: - Errors

struct APIError: LocalizedError {
    let statusCode: Int
    let code: String
    let message: String

    var errorDescription: String? { message }

    var isUnauthorized: Bool { statusCode == 401 }
    var isNotFound: Bool { statusCode == 404 }
    var isConflict: Bool { statusCode == 409 }
}
