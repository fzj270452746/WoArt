import UIKit

class ProfileListViewController: BaseViewController {
    let store = StudioStore.shared
    let listStack = UIStackView()
    private let topBar = DetailTopBar()
    private let scrollView = UIScrollView()
    private let countLabel = UILabel()
    private let pageTitle: String
    private let pageSubtitle: String

    override var hidesDock: Bool { true }

    init(title: String, subtitle: String) {
        pageTitle = title
        pageSubtitle = subtitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        topBar.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        configureBackBar(topBar)

        let title = UILabel()
        title.text = pageTitle
        title.font = Typeface.display(31, weight: .bold)
        title.textColor = Palette.ink
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = pageSubtitle
        subtitle.font = Typeface.body(12.5)
        subtitle.textColor = Palette.inkSoft
        subtitle.numberOfLines = 0

        countLabel.font = Typeface.eyebrow(9)
        countLabel.textColor = Palette.terracotta

        listStack.axis = .vertical
        listStack.spacing = 10

        let stack = UIStackView(axis: .vertical, spacing: 12, views: [countLabel, title, subtitle, listStack])
        stack.setCustomSpacing(6, after: title)
        stack.setCustomSpacing(22, after: subtitle)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        scrollView.addSubview(stack)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadFromNotification),
            name: .studioDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(authChanged),
            name: .authDidChange,
            object: nil
        )
        reloadContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadContent()
        store.refreshAll()
    }

    func reloadContent() {}

    func setCount(_ text: String) {
        countLabel.text = text.uppercased()
    }

    func setRows(_ views: [UIView]) {
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        views.forEach { listStack.addArrangedSubview($0) }
    }

    func showEmpty(title: String, message: String) {
        let wrapper = UIView()
        let empty = EmptyStateView(title: title, message: message)
        wrapper.addSubview(empty)
        empty.pinEdges(to: wrapper)
        wrapper.heightAnchor.constraint(equalToConstant: 330).isActive = true
        setRows([wrapper])
    }

    @objc private func reloadFromNotification() {
        reloadContent()
    }

    @objc private func authChanged() {
        if !AuthService.shared.isSignedIn {
            navigationController?.popToRootViewController(animated: true)
        }
    }

    func openPost(_ post: Post) {
        navigationController?.pushViewController(PostDetailViewController(postID: post.id), animated: true)
    }
}

// MARK: - Liked pieces

final class MyLikesViewController: ProfileListViewController {
    init() {
        super.init(title: "Liked pieces", subtitle: "Pieces you want to find again, kept in one place.")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func reloadContent() {
        let posts = store.likedPosts
        setCount("\(posts.count) liked")
        guard !posts.isEmpty else {
            showEmpty(
                title: "Nothing liked yet",
                message: "Tap the heart on a piece you want to come back to."
            )
            return
        }
        let rows: [UIView] = posts.map { post in
            let row = PostListRow(
                post: post,
                detail: "\(post.createdAt.feedTimestamp) · \(store.likeCount(for: post)) likes",
                trailingSymbol: "heart.fill"
            )
            row.trailingButton.tintColor = Palette.terracotta
            row.onOpen = { [weak self] in self?.openPost(post) }
            row.onTrailing = { [weak self] in
                self?.store.toggleLike(postID: post.id)
                self?.showToast("Removed from liked pieces", icon: "heart.slash")
            }
            return row
        }
        setRows(rows)
    }
}

// MARK: - My pieces

final class MyWorksViewController: ProfileListViewController {
    init() {
        super.init(title: "My pieces", subtitle: "Everything you have shared from the bench.")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func reloadContent() {
        let posts = store.posts(by: StudioNamespace.currentUserID)
        setCount(posts.count == 1 ? "1 piece" : "\(posts.count) pieces")
        guard !posts.isEmpty else {
            showEmpty(
                title: "No pieces yet",
                message: "Share a photo, a film or a note from your workshop."
            )
            return
        }
        let rows: [UIView] = posts.map { post in
            let row = PostListRow(
                post: post,
                detail: "\(post.createdAt.shortDay) · \(store.commentCount(for: post.id)) comments",
                trailingSymbol: "trash"
            )
            row.trailingButton.tintColor = Palette.terracotta
            row.onOpen = { [weak self] in self?.openPost(post) }
            row.onTrailing = { [weak self] in
                self?.confirmDelete(post)
            }
            return row
        }
        setRows(rows)
    }

    private func confirmDelete(_ post: Post) {
        ConfirmSheetViewController.present(
            from: self,
            title: "Delete this piece?",
            message: "“\(post.title)” and its comments will be removed. This cannot be undone.",
            confirmTitle: "Delete piece",
            destructive: true
        ) { [weak self] in
            self?.store.deletePost(id: post.id)
            self?.showToast("Piece deleted", icon: "trash")
        }
    }
}

// MARK: - Following

final class MyFollowingViewController: ProfileListViewController {
    init() {
        super.init(title: "Following", subtitle: "Makers whose work you want to keep an eye on.")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func reloadContent() {
        let makers = store.followingMakers
        setCount(makers.count == 1 ? "1 maker" : "\(makers.count) makers")
        guard !makers.isEmpty else {
            showEmpty(
                title: "Not following yet",
                message: "Follow a maker from any piece or profile to see them here."
            )
            return
        }
        let rows: [UIView] = makers.map { maker in
            let row = FollowingRow(maker: maker, followerCount: store.followerCount(for: maker))
            row.onOpen = { [weak self] in
                self?.navigationController?.pushViewController(
                    MakerProfileViewController(makerID: maker.id),
                    animated: true
                )
            }
            row.onUnfollow = { [weak self] in
                self?.store.toggleFollow(makerID: maker.id)
                self?.showToast("No longer following \(maker.name)", icon: "person.badge.minus")
            }
            return row
        }
        setRows(rows)
    }
}

private final class FollowingRow: UIControl, UIGestureRecognizerDelegate {
    var onOpen: (() -> Void)?
    var onUnfollow: (() -> Void)?

    init(maker: Maker, followerCount: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let card = CardView(radius: 22)
        addSubview(card)
        card.pinEdges(to: self)
        card.heightAnchor.constraint(equalToConstant: 82).isActive = true

        let avatar = ArtworkView()
        avatar.layer.cornerRadius = 24
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.configure(
            assetName: maker.avatarAsset,
            fileName: maker.avatarFile,
            remoteURL: maker.avatarRemoteURL,
            avatar: true,
            monogram: maker.name
        )

        let name = UILabel()
        name.text = maker.name
        name.font = Typeface.display(17, weight: .semibold)
        name.textColor = Palette.ink

        let meta = UILabel()
        meta.text = "\(maker.craft) · \(followerCount) followers"
        meta.font = Typeface.body(10.5)
        meta.textColor = Palette.inkFaint

        let text = UIStackView(axis: .vertical, spacing: 2, views: [name, meta])

        let unfollow = UIButton(type: .system)
        unfollow.setTitle("Unfollow", for: .normal)
        unfollow.setTitleColor(Palette.inkSoft, for: .normal)
        unfollow.titleLabel?.font = Typeface.chip(10.5, weight: .semibold)
        unfollow.backgroundColor = Palette.cream
        unfollow.layer.cornerRadius = 14
        unfollow.translatesAutoresizingMaskIntoConstraints = false
        unfollow.heightAnchor.constraint(equalToConstant: 28).isActive = true
        unfollow.widthAnchor.constraint(equalToConstant: 72).isActive = true
        unfollow.addTarget(self, action: #selector(unfollowTapped), for: .touchUpInside)

        card.addSubviews(avatar, text, unfollow)
        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            avatar.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 48),
            avatar.heightAnchor.constraint(equalToConstant: 48),
            text.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            text.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            text.trailingAnchor.constraint(lessThanOrEqualTo: unfollow.leadingAnchor, constant: -8),
            unfollow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            unfollow.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.delegate = self
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UIControl { return false }
            view = current.superview
        }
        return true
    }

    @objc private func tapped() { onOpen?() }
    @objc private func unfollowTapped() { onUnfollow?() }
}

// MARK: - Hosted gatherings

final class MyEventsViewController: ProfileListViewController {
    init() {
        super.init(title: "Hosted gatherings", subtitle: "The rooms you have opened to other makers.")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func reloadContent() {
        let events = store.events(hostedBy: StudioNamespace.currentUserID)
        setCount(events.count == 1 ? "1 gathering" : "\(events.count) gatherings")
        guard !events.isEmpty else {
            showEmpty(
                title: "No gatherings yet",
                message: "Host a workshop, an open studio or a build weekend."
            )
            return
        }
        let rows: [UIView] = events.map { event in
            let row = MyEventRow(event: event, reserved: store.reservedCount(for: event))
            row.onOpen = { [weak self] in
                self?.navigationController?.pushViewController(
                    EventDetailViewController(eventID: event.id),
                    animated: true
                )
            }
            row.onDelete = { [weak self] in
                self?.confirmDelete(event)
            }
            return row
        }
        setRows(rows)
    }

    private func confirmDelete(_ event: StudioEvent) {
        ConfirmSheetViewController.present(
            from: self,
            title: "Delete this gathering?",
            message: "“\(event.title)” and any reserved places will be removed. This cannot be undone.",
            confirmTitle: "Delete gathering",
            destructive: true
        ) { [weak self] in
            self?.store.deleteEvent(id: event.id)
            self?.showToast("Gathering removed", icon: "trash")
        }
    }
}

private final class MyEventRow: UIControl, UIGestureRecognizerDelegate {
    var onOpen: (() -> Void)?
    var onDelete: (() -> Void)?

    init(event: StudioEvent, reserved: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let card = CardView(radius: 22)
        addSubview(card)
        card.pinEdges(to: self)
        card.heightAnchor.constraint(equalToConstant: 96).isActive = true

        let poster = ArtworkView()
        poster.layer.cornerRadius = 15
        poster.clipsToBounds = true
        poster.translatesAutoresizingMaskIntoConstraints = false
        poster.configure(assetName: event.posterAsset, fileName: event.posterFile, remoteURL: event.posterRemoteURL)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d · h:mm a"

        let title = UILabel()
        title.text = event.title
        title.font = Typeface.display(17, weight: .semibold)
        title.textColor = Palette.ink
        title.numberOfLines = 1

        let meta = UILabel()
        meta.text = "\(formatter.string(from: event.date).uppercased()) · \(reserved) places"
        meta.font = Typeface.body(10)
        meta.textColor = Palette.inkFaint
        meta.numberOfLines = 1

        let text = UIStackView(axis: .vertical, spacing: 3, views: [title, meta])

        let delete = UIButton(type: .system)
        delete.setImage(
            UIImage(
                systemName: "trash",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            ),
            for: .normal
        )
        delete.tintColor = Palette.terracotta
        delete.translatesAutoresizingMaskIntoConstraints = false
        delete.widthAnchor.constraint(equalToConstant: 32).isActive = true
        delete.heightAnchor.constraint(equalToConstant: 32).isActive = true
        delete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        card.addSubviews(poster, text, delete)
        NSLayoutConstraint.activate([
            poster.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            poster.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            poster.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            poster.widthAnchor.constraint(equalToConstant: 72),
            text.leadingAnchor.constraint(equalTo: poster.trailingAnchor, constant: 12),
            text.trailingAnchor.constraint(lessThanOrEqualTo: delete.leadingAnchor, constant: -8),
            text.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            delete.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            delete.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.delegate = self
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UIControl { return false }
            view = current.superview
        }
        return true
    }

    @objc private func tapped() { onOpen?() }
    @objc private func deleteTapped() { onDelete?() }
}
