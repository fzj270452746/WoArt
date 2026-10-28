import Foundation

enum MediaKind: String, Codable {
    case image
    case video
}

struct MediaItem: Codable, Hashable {
    var assetName: String
    var fileName: String?
    var videoFileName: String? = nil
    var bundledVideoName: String?
    var kind: MediaKind
    var aspect: Double
    /// Remote image, or remote video when `kind == .video`.
    var remoteURL: String? = nil
    /// Remote cover image for a remote video.
    var remotePosterURL: String? = nil

    init(
        assetName: String,
        fileName: String? = nil,
        videoFileName: String? = nil,
        bundledVideoName: String? = nil,
        kind: MediaKind = .image,
        aspect: Double = 0.8,
        remoteURL: String? = nil,
        remotePosterURL: String? = nil
    ) {
        self.assetName = assetName
        self.fileName = fileName
        self.videoFileName = videoFileName
        self.bundledVideoName = bundledVideoName
        self.kind = kind
        self.aspect = aspect
        self.remoteURL = remoteURL
        self.remotePosterURL = remotePosterURL
    }

    /// What to paint in a card or carousel.
    var thumbnailRemoteURL: String? {
        if kind == .video { return remotePosterURL }
        return remoteURL
    }

    var hasRemoteImage: Bool { thumbnailRemoteURL != nil }
}

struct Maker: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var handle: String
    var bio: String
    var craft: String
    var location: String
    var avatarAsset: String
    var avatarFile: String? = nil
    var coverAsset: String
    var followers: Int
    var following: Int
    var isCurrentUser: Bool = false
    /// Server identifier (the local `id` is "me" for the signed-in maker).
    var apiID: String? = nil
    var avatarRemoteURL: String? = nil
    var coverRemoteURL: String? = nil

    var resolvedApiID: String { apiID ?? id }
}

struct Post: Codable, Hashable, Identifiable {
    var id: String
    var authorID: String
    var title: String
    var body: String
    var media: [MediaItem]
    var tags: [String]
    var likeCount: Int
    var createdAt: Date
    var commentCount: Int? = nil
}

struct Comment: Codable, Hashable, Identifiable {
    var id: String
    var postID: String
    var authorID: String
    var text: String
    var createdAt: Date
}

struct StudioEvent: Codable, Hashable, Identifiable {
    var id: String
    var hostID: String
    var title: String
    var summary: String
    var details: String
    var location: String
    var date: Date
    var capacity: Int
    var reservedCount: Int
    var posterAsset: String
    var posterFile: String? = nil
    var tags: [String]
    var posterRemoteURL: String? = nil
}

struct UserProfile: Codable, Hashable {
    var displayName: String
    var handle: String
    var bio: String
    var location: String
    var craft: String
    var avatarAsset: String
    var avatarFile: String?
    var avatarRemoteURL: String? = nil
    var coverRemoteURL: String? = nil

    static let empty = UserProfile(
        displayName: "Your name",
        handle: "maker",
        bio: "",
        location: "",
        craft: "",
        avatarAsset: "avatar_me",
        avatarFile: nil
    )
}

enum FriendState: String, Codable {
    case none
    case requested
    case friends
}

struct StudioState: Codable {
    var makers: [Maker]
    var posts: [Post]
    var comments: [Comment]
    var events: [StudioEvent]
    var likedPostIDs: Set<String>
    var followedMakerIDs: Set<String>
    var friendStates: [String: FriendState]
    var reservedEventIDs: Set<String>
    var profiles: [String: UserProfile]
}

enum StudioNamespace {
    static let currentUserID = "me"
    static let guestHandle = "guest"
}

extension Notification.Name {
    static let studioDidChange = Notification.Name("woart.studioDidChange")
    static let showHomeTab = Notification.Name("woart.showHomeTab")
}
