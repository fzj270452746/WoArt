import Foundation
import UIKit

extension Notification.Name {
    static let studioRequestFailed = Notification.Name("woart.studioRequestFailed")
}

/// The app's single data door.
///
/// Reads stay synchronous so the existing UIKit screens do not need to become
/// async: the store keeps a local cache of the server's atelier and republishes
/// `.studioDidChange` when it changes. Writes hit the API, usually optimistically
/// with a rollback when the server refuses.
final class StudioStore {
    static let shared = StudioStore()

    private(set) var state: StudioState
    private let storeFolder: URL
    private let stateURL: URL
    private var lastFullRefresh = Date.distantPast
    private var isRefreshingAll = false

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        storeFolder = base.appendingPathComponent("WoArt", isDirectory: true)
        try? FileManager.default.createDirectory(at: storeFolder, withIntermediateDirectories: true)
        stateURL = storeFolder.appendingPathComponent("studio-state-v2.json")

        if
            let data = try? Data(contentsOf: stateURL),
            let decoded = try? JSONDecoder().decode(StudioState.self, from: data)
        {
            state = decoded
        } else {
            state = StudioState.empty
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(authChanged),
            name: .authDidChange,
            object: nil
        )
    }

    // MARK: - Session

    var isSignedIn: Bool { AuthService.shared.isSignedIn }
    var currentUsername: String? { AuthService.shared.currentUsername }
    private var myRemoteID: String? { AuthService.shared.currentUser?.id }

    var currentProfile: UserProfile {
        guard let user = AuthService.shared.currentUser else { return .empty }
        return UserProfile(
            displayName: user.displayName,
            handle: user.handle,
            bio: user.bio,
            location: user.location,
            craft: user.craft,
            avatarAsset: "avatar_me",
            avatarFile: nil,
            avatarRemoteURL: user.avatarUrl,
            coverRemoteURL: user.coverUrl
        )
    }

    var currentMaker: Maker {
        guard let user = AuthService.shared.currentUser else {
            return Maker(
                id: StudioNamespace.currentUserID,
                name: "Your name",
                handle: "maker",
                bio: "",
                craft: "",
                location: "",
                avatarAsset: "avatar_me",
                coverAsset: "cover_me",
                followers: 0,
                following: 0,
                isCurrentUser: true,
                apiID: nil,
                avatarRemoteURL: nil,
                coverRemoteURL: nil
            )
        }
        return Maker(
            id: StudioNamespace.currentUserID,
            name: user.displayName,
            handle: user.handle,
            bio: user.bio,
            craft: user.craft,
            location: user.location,
            avatarAsset: "avatar_me",
            avatarFile: nil,
            coverAsset: "cover_me",
            followers: user.followerCount,
            following: user.followingCount,
            isCurrentUser: true,
            apiID: user.id,
            avatarRemoteURL: user.avatarUrl,
            coverRemoteURL: user.coverUrl
        )
    }

    /// Kept for the existing auth gate. The profile now comes from the server.
    func ensureCurrentProfile(suggestedName: String? = nil) {
        _ = suggestedName
    }

    // MARK: - Startup & refresh

    func start() {
        Task { @MainActor in
            await AuthService.shared.validateSession()
            refreshAll(force: true)
        }
    }

    func refreshHome(completion: (() -> Void)? = nil) {
        Task { @MainActor in
            async let feedTask = APIClient.shared.feed(limit: 50)
            async let eventsTask = APIClient.shared.events(scope: "upcoming", limit: 50)
            let feedPage = try? await feedTask
            let eventPage = try? await eventsTask

            if let feedPage { applyFeed(feedPage.items) }
            if let eventPage { applyEvents(eventPage.items, replacingUpcoming: true) }
            if let feedPage, let eventPage {
                applyUsers(feedPage.items.map(\.author) + eventPage.items.map(\.host))
            }
            if feedPage == nil && eventPage == nil {
                fail(APIError(statusCode: -1, code: "network", message: "The atelier can't be reached right now. Pull to try again."))
            }
            persist()
            notify()
            completion?()
        }
    }

    func refreshAll(force: Bool = false, completion: (() -> Void)? = nil) {
        if isRefreshingAll {
            completion?()
            return
        }
        if !force, Date().timeIntervalSince(lastFullRefresh) < 20 {
            completion?()
            return
        }
        isRefreshingAll = true

        Task { @MainActor in
            defer { isRefreshingAll = false }
            do {
                async let feedTask = APIClient.shared.feed(limit: 50)
                async let eventsTask = APIClient.shared.events(scope: "upcoming", limit: 50)
                async let makersTask = APIClient.shared.makers(limit: 50)
                let feedPage = try? await feedTask
                let eventPage = try? await eventsTask
                let makerPage = try? await makersTask

                if let feedPage { applyFeed(feedPage.items) }
                if let eventPage { applyEvents(eventPage.items, replacingUpcoming: true) }
                applyUsers(
                    (makerPage?.items ?? [])
                        + (feedPage?.items.map(\.author) ?? [])
                        + (eventPage?.items.map(\.host) ?? [])
                )
                if feedPage == nil && eventPage == nil && makerPage == nil {
                    fail(APIError(statusCode: -1, code: "network", message: "The atelier can't be reached right now. Try again in a moment."))
                }

                if AuthService.shared.isSignedIn {
                    async let meTask = APIClient.shared.me()
                    async let followingTask = APIClient.shared.myFollowing()
                    async let likesTask = APIClient.shared.myLikes()
                    async let myPostsTask = APIClient.shared.myPosts()
                    async let myEventsTask = APIClient.shared.myEvents()

                    // These are best-effort: one failing list should not stop
                    // the rest of the studio from refreshing.
                    let me = try? await meTask
                    let following = try? await followingTask
                    let likes = try? await likesTask
                    let mine = try? await myPostsTask
                    let hosted = try? await myEventsTask

                    if let me {
                        AuthService.shared.updateCurrentUser(me)
                        applyUsers([me])
                    }
                    if let following {
                        applyUsers(following.items)
                        state.followedMakerIDs = Set(following.items.map(\.id))
                    }
                    if let likes { applyLikes(likes.items) }
                    if let mine { applyMyPosts(mine.items) }
                    if let hosted { applyEvents(hosted.items) }
                } else {
                    clearPrivateState()
                }

                lastFullRefresh = Date()
                persist()
                notify()
            } catch {
                fail(error)
            }
            completion?()
        }
    }

    func loadPost(id: String) async throws {
        let remote = try await APIClient.shared.post(id: id)
        let commentsPage = try await APIClient.shared.comments(postID: id, limit: 100)
        await MainActor.run {
            upsertPost(map(remote))
            applyUsers([remote.author] + commentsPage.items.map(\.author))
            let mapped = commentsPage.items.map(map)
            state.comments.removeAll { $0.postID == id }
            state.comments.append(contentsOf: mapped)
            if let index = state.posts.firstIndex(where: { $0.id == id }) {
                state.posts[index].commentCount = mapped.count
            }
            persist()
            notify()
        }
    }

    func loadMaker(id: String) async throws {
        let remoteID = apiID(for: id)
        async let userTask = APIClient.shared.maker(id: remoteID)
        async let postsTask = APIClient.shared.makerPosts(id: remoteID, limit: 50)
        let (user, posts) = try await (userTask, postsTask)
        await MainActor.run {
            applyUsers([user] + posts.items.map(\.author))
            applyMyPosts(posts.items)
            if user.isFollowing {
                state.followedMakerIDs.insert(user.id)
            } else {
                state.followedMakerIDs.remove(user.id)
            }
            applyFriendState(user.friendState, for: user.id)
            persist()
            notify()
        }
    }

    func loadEvent(id: String) async throws {
        let remote = try await APIClient.shared.event(id: id)
        await MainActor.run {
            applyUsers([remote.host])
            upsertEvent(map(remote))
            persist()
            notify()
        }
    }

    // MARK: - Lookups

    func maker(id: String) -> Maker? {
        if id == StudioNamespace.currentUserID { return currentMaker }
        return state.makers.first { $0.id == id }
    }

    func post(id: String) -> Post? {
        state.posts.first { $0.id == id }
    }

    func event(id: String) -> StudioEvent? {
        state.events.first { $0.id == id }
    }

    func comment(id: String) -> Comment? {
        state.comments.first { $0.id == id }
    }

    func comments(for postID: String) -> [Comment] {
        state.comments
            .filter { $0.postID == postID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func commentCount(for postID: String) -> Int {
        if let post = post(id: postID), let count = post.commentCount { return count }
        return state.comments.reduce(0) { $0 + ($1.postID == postID ? 1 : 0) }
    }

    func posts(by makerID: String) -> [Post] {
        state.posts
            .filter { $0.authorID == makerID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func events(hostedBy makerID: String) -> [StudioEvent] {
        state.events
            .filter { $0.hostID == makerID }
            .sorted { $0.date < $1.date }
    }

    var feed: [Post] {
        var ordered = state.posts.sorted { $0.createdAt > $1.createdAt }
        // The first moving picture sits third in the whole list, the viewer's
        // own pieces included. Trading timestamps with whatever holds that
        // slot keeps one honest order instead of moving the film aside.
        guard
            ordered.count > 2,
            let videoIndex = ordered.firstIndex(where: { post in
                post.media.contains { $0.kind == .video }
            }),
            videoIndex != 2
        else { return ordered }

        let third = ordered[2].createdAt
        ordered[2].createdAt = ordered[videoIndex].createdAt
        ordered[videoIndex].createdAt = third
        ordered.sort { $0.createdAt > $1.createdAt }
        return ordered
    }

    var upcomingEvents: [StudioEvent] {
        let now = Date().addingTimeInterval(-1800)
        return state.events
            .filter { $0.date >= now }
            .sorted { $0.date < $1.date }
    }

    var followingMakers: [Maker] {
        state.makers
            .filter { state.followedMakerIDs.contains($0.id) }
            .sorted { $0.name < $1.name }
    }

    var likedPosts: [Post] {
        state.posts
            .filter { state.likedPostIDs.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func isLiked(_ postID: String) -> Bool {
        state.likedPostIDs.contains(postID)
    }

    func likeCount(for post: Post) -> Int {
        post.likeCount
    }

    func isFollowing(_ makerID: String) -> Bool {
        makerID != StudioNamespace.currentUserID && state.followedMakerIDs.contains(makerID)
    }

    func followerCount(for maker: Maker) -> Int {
        maker.followers
    }

    func friendState(for makerID: String) -> FriendState {
        state.friendStates[makerID] ?? .none
    }

    func isReserved(_ eventID: String) -> Bool {
        state.reservedEventIDs.contains(eventID)
    }

    func seatsLeft(for event: StudioEvent) -> Int {
        max(0, event.capacity - event.reservedCount)
    }

    func reservedCount(for event: StudioEvent) -> Int {
        event.reservedCount
    }

    // MARK: - Small mutations (optimistic)

    @discardableResult
    func toggleLike(postID: String) -> Bool {
        guard let index = state.posts.firstIndex(where: { $0.id == postID }) else { return false }
        let becameLiked = !state.likedPostIDs.contains(postID)
        if becameLiked {
            state.likedPostIDs.insert(postID)
            state.posts[index].likeCount += 1
        } else {
            state.likedPostIDs.remove(postID)
            state.posts[index].likeCount = max(0, state.posts[index].likeCount - 1)
        }
        persist()
        notify()

        Task { @MainActor in
            do {
                let response = becameLiked
                    ? try await APIClient.shared.like(postID: postID)
                    : try await APIClient.shared.unlike(postID: postID)
                if let current = state.posts.firstIndex(where: { $0.id == postID }) {
                    state.posts[current].likeCount = response.likeCount
                }
                persist()
                notify()
            } catch {
                if let current = state.posts.firstIndex(where: { $0.id == postID }) {
                    state.posts[current].likeCount = max(0, state.posts[current].likeCount + (becameLiked ? -1 : 1))
                }
                if becameLiked {
                    state.likedPostIDs.remove(postID)
                } else {
                    state.likedPostIDs.insert(postID)
                }
                persist()
                notify()
                fail(error)
            }
        }
        return becameLiked
    }

    @discardableResult
    func toggleFollow(makerID: String) -> Bool {
        guard makerID != StudioNamespace.currentUserID,
              let maker = maker(id: makerID) else { return false }

        let becameFollowing = !state.followedMakerIDs.contains(makerID)
        if becameFollowing {
            state.followedMakerIDs.insert(makerID)
        } else {
            state.followedMakerIDs.remove(makerID)
        }
        adjustFollowerCount(makerID, by: becameFollowing ? 1 : -1)
        persist()
        notify()

        let remoteID = maker.resolvedApiID
        Task { @MainActor in
            do {
                let response = becameFollowing
                    ? try await APIClient.shared.follow(makerID: remoteID)
                    : try await APIClient.shared.unfollow(makerID: remoteID)
                if let index = state.makers.firstIndex(where: { $0.id == makerID }) {
                    state.makers[index].followers = response.followerCount
                }
                persist()
                notify()
            } catch {
                if becameFollowing {
                    state.followedMakerIDs.remove(makerID)
                } else {
                    state.followedMakerIDs.insert(makerID)
                }
                adjustFollowerCount(makerID, by: becameFollowing ? -1 : 1)
                persist()
                notify()
                fail(error)
            }
        }
        return becameFollowing
    }

    func requestFriend(makerID: String) {
        guard makerID != StudioNamespace.currentUserID,
              let maker = maker(id: makerID),
              friendState(for: makerID) == .none else { return }
        state.friendStates[makerID] = .requested
        persist()
        notify()

        let remoteID = maker.resolvedApiID
        Task { @MainActor in
            do {
                let response = try await APIClient.shared.requestFriend(makerID: remoteID)
                applyFriendState(response.friendState, for: makerID)
                persist()
                notify()
            } catch {
                state.friendStates[makerID] = .none
                persist()
                notify()
                fail(error)
            }
        }
    }

    func reserve(eventID: String) {
        guard let event = event(id: eventID), !isReserved(eventID), seatsLeft(for: event) > 0 else { return }
        state.reservedEventIDs.insert(eventID)
        adjustReservedCount(eventID, by: 1)
        persist()
        notify()

        Task { @MainActor in
            do {
                let response = try await APIClient.shared.reserve(eventID: eventID)
                if let index = state.events.firstIndex(where: { $0.id == eventID }) {
                    state.events[index].reservedCount = response.reservedCount
                }
                state.reservedEventIDs.insert(eventID)
                persist()
                notify()
            } catch {
                state.reservedEventIDs.remove(eventID)
                adjustReservedCount(eventID, by: -1)
                persist()
                notify()
                fail(error)
            }
        }
    }

    func cancelReservation(eventID: String) {
        guard isReserved(eventID) else { return }
        state.reservedEventIDs.remove(eventID)
        adjustReservedCount(eventID, by: -1)
        persist()
        notify()

        Task { @MainActor in
            do {
                let response = try await APIClient.shared.cancelReservation(eventID: eventID)
                if let index = state.events.firstIndex(where: { $0.id == eventID }) {
                    state.events[index].reservedCount = response.reservedCount
                }
                persist()
                notify()
            } catch {
                state.reservedEventIDs.insert(eventID)
                adjustReservedCount(eventID, by: 1)
                persist()
                notify()
                fail(error)
            }
        }
    }

    // MARK: - Publishing

    @discardableResult
    func addPost(title: String, body: String, media: [MediaItem], tags: [String]) async throws -> Post {
        var mediaIds: [String] = []
        for item in media {
            let upload = try await uploadMedia(item)
            mediaIds.append(upload.id)
        }

        let remote = try await APIClient.shared.createPost(
            title: title,
            body: body,
            tags: tags,
            mediaIds: mediaIds
        )
        let mapped = map(remote)
        await MainActor.run {
            upsertPost(mapped)
            applyUsers([remote.author])
            persist()
            notify()
        }
        media.forEach {
            MediaLibrary.removeMedia(named: $0.fileName)
            MediaLibrary.removeMedia(named: $0.videoFileName)
        }
        return mapped
    }

    func deletePost(id: String) {
        guard let index = state.posts.firstIndex(where: { $0.id == id }) else { return }
        let removed = state.posts.remove(at: index)
        let removedComments = state.comments.filter { $0.postID == id }
        state.comments.removeAll { $0.postID == id }
        state.likedPostIDs.remove(id)
        persist()
        notify()

        Task { @MainActor in
            do {
                try await APIClient.shared.deletePost(id: id)
            } catch {
                if !state.posts.contains(where: { $0.id == id }) {
                    state.posts.insert(removed, at: min(index, state.posts.count))
                }
                state.comments.append(contentsOf: removedComments)
                persist()
                notify()
                fail(error)
            }
        }
    }

    @discardableResult
    func addComment(postID: String, text: String) -> Comment? {
        let trimmed = text.trimmed
        guard !trimmed.isEmpty,
              AuthService.shared.isSignedIn,
              let postIndex = state.posts.firstIndex(where: { $0.id == postID }) else { return nil }

        let local = Comment(
            id: "local_\(UUID().uuidString)",
            postID: postID,
            authorID: StudioNamespace.currentUserID,
            text: trimmed,
            createdAt: Date()
        )
        state.comments.append(local)
        state.posts[postIndex].commentCount = (state.posts[postIndex].commentCount ?? comments(for: postID).count - 1) + 1
        persist()
        notify()

        Task { @MainActor in
            do {
                let remote = try await APIClient.shared.createComment(postID: postID, text: trimmed)
                applyUsers([remote.author])
                if let index = state.comments.firstIndex(where: { $0.id == local.id }) {
                    state.comments[index] = map(remote)
                }
                persist()
                notify()
            } catch {
                state.comments.removeAll { $0.id == local.id }
                if let index = state.posts.firstIndex(where: { $0.id == postID }) {
                    state.posts[index].commentCount = max(0, (state.posts[index].commentCount ?? 1) - 1)
                }
                persist()
                notify()
                fail(error)
            }
        }
        return local
    }

    func deleteComment(id: String) {
        guard let index = state.comments.firstIndex(where: { $0.id == id }) else { return }
        let removed = state.comments.remove(at: index)
        if let postIndex = state.posts.firstIndex(where: { $0.id == removed.postID }) {
            state.posts[postIndex].commentCount = max(0, (state.posts[postIndex].commentCount ?? 1) - 1)
        }
        persist()
        notify()

        Task { @MainActor in
            do {
                try await APIClient.shared.deleteComment(id: id)
            } catch {
                state.comments.insert(removed, at: min(index, state.comments.count))
                if let postIndex = state.posts.firstIndex(where: { $0.id == removed.postID }) {
                    state.posts[postIndex].commentCount = (state.posts[postIndex].commentCount ?? 0) + 1
                }
                persist()
                notify()
                fail(error)
            }
        }
    }

    @discardableResult
    func addEvent(
        title: String,
        summary: String,
        details: String,
        location: String,
        date: Date,
        capacity: Int,
        posterFile: String?
    ) async throws -> StudioEvent {
        var posterMediaId: String?
        if let posterFile {
            let url = MediaLibrary.url(for: posterFile)
            let image = UIImage(contentsOfFile: url.path)
            let upload = try await APIClient.shared.uploadMedia(
                fileURL: url,
                mimeType: "image/jpeg",
                kind: .image,
                width: image.map { Int($0.size.width * $0.scale) },
                height: image.map { Int($0.size.height * $0.scale) },
                aspect: image.map { Double($0.size.width / max(1, $0.size.height)) },
                posterURL: nil
            )
            posterMediaId = upload.id
        }

        let remote = try await APIClient.shared.createEvent(
            title: title,
            summary: summary,
            details: details,
            location: location,
            startAt: date,
            capacity: capacity,
            tags: ["Gathering"],
            posterMediaId: posterMediaId
        )
        let mapped = map(remote)
        await MainActor.run {
            upsertEvent(mapped)
            applyUsers([remote.host])
            persist()
            notify()
        }
        MediaLibrary.removeMedia(named: posterFile)
        return mapped
    }

    func deleteEvent(id: String) {
        guard let index = state.events.firstIndex(where: { $0.id == id }) else { return }
        let removed = state.events.remove(at: index)
        state.reservedEventIDs.remove(id)
        persist()
        notify()

        Task { @MainActor in
            do {
                try await APIClient.shared.deleteEvent(id: id)
            } catch {
                if !state.events.contains(where: { $0.id == id }) {
                    state.events.insert(removed, at: min(index, state.events.count))
                }
                persist()
                notify()
                fail(error)
            }
        }
    }

    // MARK: - Profile

    func updateProfile(
        displayName: String,
        bio: String,
        location: String,
        craft: String,
        avatarFile: String?
    ) async throws {
        var avatarURL: String?
        if let avatarFile {
            let url = MediaLibrary.url(for: avatarFile)
            let image = UIImage(contentsOfFile: url.path)
            let upload = try await APIClient.shared.uploadMedia(
                fileURL: url,
                mimeType: "image/jpeg",
                kind: .image,
                width: image.map { Int($0.size.width * $0.scale) },
                height: image.map { Int($0.size.height * $0.scale) },
                aspect: image.map { Double($0.size.width / max(1, $0.size.height)) },
                posterURL: nil
            )
            avatarURL = upload.url
        }

        let user = try await APIClient.shared.updateMe(
            displayName: displayName,
            bio: bio,
            location: location,
            craft: craft,
            avatarUrl: avatarURL
        )
        await MainActor.run {
            AuthService.shared.updateCurrentUser(user)
            MediaLibrary.removeMedia(named: avatarFile)
            persist()
            notify()
        }
    }

    // MARK: - Reporting and moderation

    func report(target: ReportTarget, reason: String, details: String?) async throws {
        let type: String
        let targetID: String
        switch target {
        case .post(let id):
            type = "post"
            targetID = id
        case .comment(let id, _):
            type = "comment"
            targetID = id
        case .maker(let id):
            type = "user"
            targetID = apiID(for: id)
        }

        let response = try await APIClient.shared.report(
            targetType: type,
            targetId: targetID,
            reason: reason,
            details: details
        )

        await MainActor.run {
            switch target {
            case .post(let postID):
                if response.hidden {
                    removePostAndComments(id: postID)
                }
            case .comment(let commentID, _):
                if response.hidden {
                    state.comments.removeAll { $0.id == commentID }
                    persist()
                    notify()
                }
            case .maker(let makerID):
                if response.blocked {
                    removeMakerAndContent(id: makerID, remoteID: targetID)
                }
            }
        }
    }

    // MARK: - Account

    func deleteAccount() async throws {
        try await AuthService.shared.deleteAccount()
        await MainActor.run {
            erasePersonalDataForCurrentAccount()
        }
    }

    // MARK: - Local removals (report / account actions)

    func removePostAndComments(id: String) {
        let removed = state.posts.filter { $0.id == id }
        state.posts.removeAll { $0.id == id }
        state.comments.removeAll { $0.postID == id }
        state.likedPostIDs.remove(id)
        removed.flatMap(\.media).forEach {
            MediaLibrary.removeMedia(named: $0.fileName)
            MediaLibrary.removeMedia(named: $0.videoFileName)
        }
        persist()
        notify()
    }

    /// Removes a maker, everything they posted, and their comments from this view.
    func removeMakerAndContent(id: String, remoteID: String? = nil) {
        guard id != StudioNamespace.currentUserID else { return }
        let removedPostIDs = Set(state.posts.filter { $0.authorID == id }.map(\.id))

        state.posts
            .filter { $0.authorID == id }
            .flatMap(\.media)
            .forEach {
                MediaLibrary.removeMedia(named: $0.fileName)
                MediaLibrary.removeMedia(named: $0.videoFileName)
            }

        state.posts.removeAll { $0.authorID == id }
        state.comments.removeAll { $0.authorID == id || removedPostIDs.contains($0.postID) }
        state.likedPostIDs.subtract(removedPostIDs)
        state.makers.removeAll { $0.id == id || ($0.apiID != nil && $0.apiID == remoteID) }
        state.followedMakerIDs.remove(id)
        state.friendStates[id] = nil
        persist()
        notify()
    }

    func erasePersonalDataForCurrentAccount() {
        state.posts
            .filter { $0.authorID == StudioNamespace.currentUserID }
            .flatMap(\.media)
            .forEach {
                MediaLibrary.removeMedia(named: $0.fileName)
                MediaLibrary.removeMedia(named: $0.videoFileName)
            }
        state.posts.removeAll { $0.authorID == StudioNamespace.currentUserID }
        state.comments.removeAll { $0.authorID == StudioNamespace.currentUserID }
        state.events.removeAll { $0.hostID == StudioNamespace.currentUserID }
        clearPrivateState()
        persist()
        notify()
    }

    // MARK: - Merging server objects

    private func applyFeed(_ items: [APIPost]) {
        let mapped = items.map(map)
        let feedIDs = Set(mapped.map(\.id))

        for post in mapped where state.posts.contains(where: { $0.id == post.id }) {
            if let index = state.posts.firstIndex(where: { $0.id == post.id }) {
                state.posts[index] = post
            }
        }
        for post in mapped where !state.posts.contains(where: { $0.id == post.id }) {
            state.posts.append(post)
        }

        // Drop cached feed posts that vanished from the server, but keep the
        // viewer's own and liked pieces until those lists refresh.
        let likedBefore = state.likedPostIDs
        state.posts.removeAll {
            !feedIDs.contains($0.id)
                && $0.authorID != StudioNamespace.currentUserID
                && !likedBefore.contains($0.id)
        }

        state.likedPostIDs.subtract(feedIDs)
        for item in items where item.liked {
            state.likedPostIDs.insert(item.id)
        }
    }

    private func applyLikes(_ items: [APIPost]) {
        let mapped = items.map(map)
        for post in mapped {
            if let index = state.posts.firstIndex(where: { $0.id == post.id }) {
                state.posts[index] = post
            } else {
                state.posts.append(post)
            }
            state.likedPostIDs.insert(post.id)
        }
    }

    private func applyMyPosts(_ items: [APIPost]) {
        for post in items.map(map) {
            if let index = state.posts.firstIndex(where: { $0.id == post.id }) {
                state.posts[index] = post
            } else {
                state.posts.append(post)
            }
        }
    }

    private func applyEvents(_ items: [APIEvent], replacingUpcoming: Bool = false) {
        let mapped = items.map(map)
        for event in mapped {
            upsertEvent(event)
        }
        // Only the "upcoming" page may drop events; hosted/mine pages are a
        // partial view and must never wipe the calendar.
        if replacingUpcoming {
            let remoteIDs = Set(mapped.map(\.id))
            state.events.removeAll {
                $0.date >= Date().addingTimeInterval(-1800)
                    && !remoteIDs.contains($0.id)
                    && $0.hostID != StudioNamespace.currentUserID
            }
        }
        let pageIDs = Set(items.map(\.id))
        state.reservedEventIDs.subtract(pageIDs)
        items.filter { $0.isReserved }.forEach { state.reservedEventIDs.insert($0.id) }
    }

    private func applyUsers(_ users: [APIUser]) {
        for user in users {
            let mapped = map(user)
            guard mapped.id != StudioNamespace.currentUserID else { continue }
            upsertMaker(mapped)
        }
    }

    private func upsertMaker(_ maker: Maker) {
        if let index = state.makers.firstIndex(where: { $0.id == maker.id }) {
            state.makers[index] = maker
        } else {
            state.makers.append(maker)
        }
    }

    private func upsertPost(_ post: Post) {
        if let index = state.posts.firstIndex(where: { $0.id == post.id }) {
            state.posts[index] = post
        } else {
            state.posts.append(post)
        }
    }

    private func upsertEvent(_ event: StudioEvent) {
        if let index = state.events.firstIndex(where: { $0.id == event.id }) {
            state.events[index] = event
        } else {
            state.events.append(event)
        }
    }

    private func applyFriendState(_ raw: String, for makerID: String) {
        switch raw {
        case "friends": state.friendStates[makerID] = .friends
        case "requested", "incoming_request": state.friendStates[makerID] = .requested
        default: state.friendStates[makerID] = .none
        }
    }

    private func adjustFollowerCount(_ makerID: String, by delta: Int) {
        guard let index = state.makers.firstIndex(where: { $0.id == makerID }) else { return }
        state.makers[index].followers = max(0, state.makers[index].followers + delta)
    }

    private func adjustReservedCount(_ eventID: String, by delta: Int) {
        guard let index = state.events.firstIndex(where: { $0.id == eventID }) else { return }
        state.events[index].reservedCount = max(0, state.events[index].reservedCount + delta)
    }

    private func clearPrivateState() {
        state.likedPostIDs = []
        state.followedMakerIDs = []
        state.friendStates = [:]
        state.reservedEventIDs = []
        state.profiles = [:]
    }

    private func apiID(for localID: String) -> String {
        if localID == StudioNamespace.currentUserID {
            return myRemoteID ?? localID
        }
        return maker(id: localID)?.resolvedApiID ?? localID
    }

    // MARK: - DTO mapping

    private func map(_ user: APIUser) -> Maker {
        let isMe = user.id == myRemoteID || user.isMe
        let localID = isMe ? StudioNamespace.currentUserID : user.id
        return Maker(
            id: localID,
            name: user.displayName,
            handle: user.handle,
            bio: user.bio,
            craft: user.craft,
            location: user.location,
            avatarAsset: isMe ? "avatar_me" : (user.isSeed ? "maker_\(user.id)_avatar" : "avatar_guest"),
            avatarFile: nil,
            coverAsset: isMe ? "cover_me" : (user.isSeed ? "maker_\(user.id)_cover" : "event_user_poster"),
            followers: user.followerCount,
            following: user.followingCount,
            isCurrentUser: isMe,
            apiID: user.id,
            avatarRemoteURL: user.avatarUrl,
            coverRemoteURL: user.coverUrl
        )
    }

    private func map(_ media: APIMedia) -> MediaItem {
        MediaItem(
            assetName: "user_media",
            kind: media.kind == "video" ? .video : .image,
            aspect: media.aspect,
            remoteURL: media.url,
            remotePosterURL: media.posterUrl
        )
    }

    private func map(_ post: APIPost) -> Post {
        Post(
            id: post.id,
            authorID: post.author.id == myRemoteID ? StudioNamespace.currentUserID : post.author.id,
            title: post.title,
            body: post.body,
            media: post.media.map(map),
            tags: post.tags,
            likeCount: post.likeCount,
            createdAt: post.createdAt,
            commentCount: post.commentCount
        )
    }

    private func map(_ comment: APIComment) -> Comment {
        Comment(
            id: comment.id,
            postID: comment.postId,
            authorID: comment.author.id == myRemoteID ? StudioNamespace.currentUserID : comment.author.id,
            text: comment.text,
            createdAt: comment.createdAt
        )
    }

    private func map(_ event: APIEvent) -> StudioEvent {
        StudioEvent(
            id: event.id,
            hostID: event.host.id == myRemoteID ? StudioNamespace.currentUserID : event.host.id,
            title: event.title,
            summary: event.summary,
            details: event.details,
            location: event.location,
            date: event.startAt,
            capacity: event.capacity,
            reservedCount: event.reservedCount,
            posterAsset: "event_user_poster",
            posterFile: nil,
            tags: event.tags,
            posterRemoteURL: event.posterUrl
        )
    }

    // MARK: - Uploads

    private func uploadMedia(_ item: MediaItem) async throws -> APIMediaUpload {
        switch item.kind {
        case .image:
            guard let file = item.fileName else {
                throw APIError(statusCode: -1, code: "file_missing", message: "That image is no longer available.")
            }
            let url = MediaLibrary.url(for: file)
            let image = UIImage(contentsOfFile: url.path)
            return try await APIClient.shared.uploadMedia(
                fileURL: url,
                mimeType: "image/jpeg",
                kind: .image,
                width: image.map { Int($0.size.width * $0.scale) },
                height: image.map { Int($0.size.height * $0.scale) },
                aspect: image.map { Double($0.size.width / max(1, $0.size.height)) } ?? item.aspect,
                posterURL: nil
            )

        case .video:
            guard let videoFile = item.videoFileName else {
                throw APIError(statusCode: -1, code: "file_missing", message: "That film is no longer available.")
            }
            let videoURL = MediaLibrary.url(for: videoFile)
            let posterURL = item.fileName.map { MediaLibrary.url(for: $0) }
            let posterImage = posterURL.flatMap { UIImage(contentsOfFile: $0.path) }
            let videoMime: String
            switch videoURL.pathExtension.lowercased() {
            case "mov": videoMime = "video/quicktime"
            case "m4v": videoMime = "video/x-m4v"
            default: videoMime = "video/mp4"
            }
            return try await APIClient.shared.uploadMedia(
                fileURL: videoURL,
                mimeType: videoMime,
                kind: .video,
                width: posterImage.map { Int($0.size.width * $0.scale) },
                height: posterImage.map { Int($0.size.height * $0.scale) },
                aspect: item.aspect,
                posterURL: posterURL
            )
        }
    }

    // MARK: - Auth changes

    @objc private func authChanged() {
        if AuthService.shared.isSignedIn {
            refreshAll(force: true)
        } else {
            clearPrivateState()
            persist()
            notify()
        }
    }

    // MARK: - Persistence

    private func notify() {
        NotificationCenter.default.post(name: .studioDidChange, object: nil)
    }

    private func fail(_ error: Error) {
        let message: String
        if let apiError = error as? APIError {
            message = apiError.message
        } else {
            message = error.localizedDescription
        }
        NotificationCenter.default.post(
            name: .studioRequestFailed,
            object: nil,
            userInfo: ["message": message]
        )
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: stateURL, options: .atomic)
    }
}

extension StudioState {
    static let empty = StudioState(
        makers: [],
        posts: [],
        comments: [],
        events: [],
        likedPostIDs: [],
        followedMakerIDs: [],
        friendStates: [:],
        reservedEventIDs: [],
        profiles: [:]
    )
}
