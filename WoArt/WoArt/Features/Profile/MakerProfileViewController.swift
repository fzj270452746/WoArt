import UIKit

final class MakerProfileViewController: BaseViewController {
    private let makerID: String
    private let store = StudioStore.shared
    private let scrollView = UIScrollView()
    private let cover = ArtworkView()
    private let sheet = UIView()
    private let avatar = ArtworkView()
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let metaLabel = UILabel()
    private let bioLabel = UILabel()
    private let statsRow = UIStackView()
    private let actionsRow = UIStackView()
    private let actionButtons = UIStackView()
    private let followButton = PillButton(title: "Follow", style: .primary, height: 44)
    private let friendButton = PillButton(title: "Add friend", style: .outline, height: 44)
    private let editButton = PillButton(title: "Edit profile", style: .light, height: 44)
    private let postsStack = UIStackView()
    private let backButton = CircleIconButton(symbol: "chevron.left", diameter: 40, pointSize: 15)
    private let reportButton = CircleIconButton(symbol: "flag", diameter: 40, background: Palette.card, pointSize: 14)
    private let emptyPieces = UILabel()
    private var isMe = false

    override var hidesDock: Bool { true }

    init(makerID: String) {
        self.makerID = makerID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        build()
        if store.maker(id: makerID) != nil {
            render()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataChanged),
            name: .studioDidChange,
            object: nil
        )

        Task { @MainActor in
            do {
                try await store.loadMaker(id: makerID)
                if store.maker(id: makerID) != nil {
                    render()
                } else {
                    navigationController?.popViewController(animated: true)
                }
            } catch {
                if store.maker(id: makerID) == nil {
                    showToast(error.localizedDescription, icon: "exclamationmark")
                    navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func build() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        cover.layer.cornerRadius = 30
        cover.layer.cornerCurve = .continuous
        cover.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        cover.clipsToBounds = true
        scrollView.addSubview(cover)
        cover.translatesAutoresizingMaskIntoConstraints = false

        let coverShade = UIView()
        coverShade.isUserInteractionEnabled = false
        let coverGradient = GradientView(
            colors: [Palette.paper.withAlphaComponent(0.55), UIColor.clear, Palette.walnut.withAlphaComponent(0.25)],
            locations: [0, 0.35, 1]
        )
        coverShade.addSubview(coverGradient)
        coverGradient.translatesAutoresizingMaskIntoConstraints = false
        coverGradient.pinEdges(to: coverShade)
        cover.addSubview(coverShade)
        coverShade.pinEdges(to: cover)

        sheet.backgroundColor = Palette.card
        sheet.layer.cornerRadius = 36
        sheet.layer.cornerCurve = .continuous
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.applySoftShadow(opacity: 0.08, radius: 24, y: -4)
        scrollView.addSubview(sheet)
        sheet.translatesAutoresizingMaskIntoConstraints = false

        avatar.layer.cornerRadius = 39
        avatar.layer.borderWidth = 3
        avatar.layer.borderColor = Palette.card.cgColor
        avatar.clipsToBounds = true
        avatar.applySoftShadow(opacity: 0.14, radius: 18, y: 8)
        scrollView.addSubview(avatar)
        avatar.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = Typeface.display(28, weight: .bold)
        nameLabel.textColor = Palette.ink
        nameLabel.numberOfLines = 0

        handleLabel.font = Typeface.chip(12.5, weight: .medium)
        handleLabel.textColor = Palette.inkFaint

        metaLabel.font = Typeface.body(12.5, weight: .medium)
        metaLabel.textColor = Palette.inkSoft
        metaLabel.numberOfLines = 1

        bioLabel.font = Typeface.body(14.5)
        bioLabel.textColor = Palette.inkSoft
        bioLabel.numberOfLines = 0
        bioLabel.setLineHeight(5)

        statsRow.axis = .horizontal
        statsRow.distribution = .fillEqually
        statsRow.alignment = .center

        actionButtons.axis = .horizontal
        actionButtons.spacing = 8
        actionButtons.distribution = .fillEqually
        actionButtons.addArrangedSubview(followButton)
        actionButtons.addArrangedSubview(friendButton)
        actionButtons.addArrangedSubview(editButton)

        actionsRow.axis = .horizontal
        actionsRow.spacing = 8
        actionsRow.alignment = .center
        actionsRow.addArrangedSubview(actionButtons)

        followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
        friendButton.addTarget(self, action: #selector(friendTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

        postsStack.axis = .vertical
        postsStack.spacing = 10

        emptyPieces.text = "No pieces shared yet."
        emptyPieces.font = Typeface.body(13.5, weight: .medium)
        emptyPieces.textColor = Palette.inkFaint
        emptyPieces.numberOfLines = 0
        emptyPieces.isHidden = true

        let piecesHeading = UILabel()
        piecesHeading.text = "Pieces"
        piecesHeading.font = Typeface.display(21, weight: .bold)
        piecesHeading.textColor = Palette.ink

        let stack = UIStackView(
            axis: .vertical,
            spacing: 18,
            views: [nameLabel, handleLabel, metaLabel, bioLabel, statsRow, actionsRow, piecesHeading, postsStack, emptyPieces]
        )
        stack.setCustomSpacing(2, after: nameLabel)
        stack.setCustomSpacing(8, after: handleLabel)
        stack.setCustomSpacing(12, after: metaLabel)
        stack.setCustomSpacing(18, after: bioLabel)
        stack.setCustomSpacing(18, after: statsRow)
        stack.setCustomSpacing(26, after: actionsRow)
        stack.setCustomSpacing(12, after: piecesHeading)

        sheet.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cover.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            cover.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            cover.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            cover.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            cover.heightAnchor.constraint(equalToConstant: 176),

            sheet.topAnchor.constraint(equalTo: cover.bottomAnchor, constant: -30),
            sheet.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            sheet.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            sheet.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            avatar.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 22),
            avatar.topAnchor.constraint(equalTo: cover.bottomAnchor, constant: -34),
            avatar.widthAnchor.constraint(equalToConstant: 78),
            avatar.heightAnchor.constraint(equalToConstant: 78),

            stack.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 86),
            stack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: sheet.bottomAnchor, constant: -34)
        ])

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        view.addSubview(backButton)
        view.addSubview(reportButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        reportButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            reportButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            reportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)
        ])
    }

    private func render() {
        guard let maker = store.maker(id: makerID) else {
            navigationController?.popViewController(animated: true)
            return
        }
        isMe = maker.id == StudioNamespace.currentUserID || makerID == StudioNamespace.currentUserID

        cover.configure(assetName: maker.coverAsset, remoteURL: maker.coverRemoteURL)
        avatar.configure(
            assetName: maker.avatarAsset,
            fileName: maker.avatarFile,
            remoteURL: maker.avatarRemoteURL,
            avatar: true,
            monogram: maker.name
        )
        nameLabel.text = maker.name
        handleLabel.text = "@\(maker.handle)"
        metaLabel.text = [maker.craft, maker.location].filter { !$0.isEmpty }.joined(separator: "  ·  ")
        bioLabel.text = maker.bio
        bioLabel.isHidden = maker.bio.isEmpty

        let pieces = store.posts(by: maker.id)
        rebuildStats(piecesCount: pieces.count, followers: store.followerCount(for: maker), following: maker.following)

        followButton.isHidden = isMe
        friendButton.isHidden = isMe
        editButton.isHidden = !isMe
        reportButton.isHidden = isMe

        if !isMe {
            let following = store.isFollowing(maker.id)
            followButton.setTitle(following ? "Following" : "Follow", for: .normal)
            if var config = followButton.configuration {
                config.baseBackgroundColor = following ? Palette.cream : Palette.terracotta
                config.baseForegroundColor = following ? Palette.inkSoft : .white
                followButton.configuration = config
            }

            let friendState = store.friendState(for: maker.id)
            friendButton.isHidden = friendState == .friends
            friendButton.setTitle(friendState == .requested ? "Requested" : "Add friend", for: .normal)
            friendButton.isEnabled = friendState == .none
        }

        rebuildPieces(pieces)
    }

    private func rebuildStats(piecesCount: Int, followers: Int, following: Int) {
        statsRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let items: [(String, String)] = [
            ("\(piecesCount)", "Pieces"),
            ("\(followers)", "Followers"),
            ("\(following)", "Following")
        ]
        for item in items {
            let column = StatColumnView(value: item.0, label: item.1)
            statsRow.addArrangedSubview(column)
        }
    }

    private func rebuildPieces(_ pieces: [Post]) {
        postsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        emptyPieces.isHidden = !pieces.isEmpty
        for post in pieces {
            let row = MakerPostRow(post: post, likeCount: store.likeCount(for: post))
            row.onOpen = { [weak self] in
                let detail = PostDetailViewController(postID: post.id)
                self?.navigationController?.pushViewController(detail, animated: true)
            }
            postsStack.addArrangedSubview(row)
        }
    }

    @objc private func dataChanged() {
        guard store.maker(id: makerID) != nil else {
            navigationController?.popViewController(animated: true)
            return
        }
        render()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func reportTapped() {
        guard let maker = store.maker(id: makerID) else { return }
        ActionSheetViewController.present(
            from: self,
            title: maker.name,
            options: [
                .init(title: "Report or block this maker", symbol: "flag", destructive: true) { [weak self] in
                    let report = ReportViewController(target: .maker(maker.id))
                    self?.navigationController?.pushViewController(report, animated: true)
                },
                .init(title: "Cancel", symbol: "xmark", destructive: false) {}
            ]
        )
    }

    @objc private func followTapped() {
        guard AuthGate.requireLogin(from: self, then: { [weak self] in
            self?.toggleFollow()
        }) else { return }
        toggleFollow()
    }

    private func toggleFollow() {
        let following = store.toggleFollow(makerID: makerID)
        render()
        if following {
            Haptics.success()
            showToast("Following", icon: "checkmark")
        }
    }

    @objc private func friendTapped() {
        guard AuthGate.requireLogin(from: self, then: { [weak self] in
            self?.sendFriendRequest()
        }) else { return }
        sendFriendRequest()
    }

    private func sendFriendRequest() {
        store.requestFriend(makerID: makerID)
        render()
        Haptics.success()
        showToast("Friend request sent", icon: "paperplane")
    }

    @objc private func editTapped() {
        let edit = EditProfileViewController()
        navigationController?.pushViewController(edit, animated: true)
    }
}

private final class MakerPostRow: UIControl {
    var onOpen: (() -> Void)?
    private let row = CardView(radius: 18)
    private let thumb = ArtworkView()

    init(post: Post, likeCount: Int) {
        super.init(frame: .zero)
        heightAnchor.constraint(equalToConstant: 94).isActive = true

        row.isUserInteractionEnabled = false
        addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.pinEdges(to: self)

        thumb.layer.cornerRadius = 13
        thumb.layer.cornerCurve = .continuous
        thumb.clipsToBounds = true
        thumb.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(thumb)

        let title = UILabel()
        title.text = post.title
        title.font = Typeface.display(16, weight: .semibold)
        title.textColor = Palette.ink
        title.numberOfLines = 2

        let meta = UILabel()
        meta.text = "\(post.createdAt.shortDay) · \(likeCount) likes"
        meta.font = Typeface.body(10.5)
        meta.textColor = Palette.inkFaint

        let textStack = UIStackView(axis: .vertical, spacing: 4, views: [title, meta])
        row.addSubview(textStack)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
            )
        )
        chevron.tintColor = Palette.inkFaint
        chevron.contentMode = .scaleAspectFit
        row.addSubview(chevron)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 14).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 14).isActive = true

        let textLeading = textStack.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12)
        NSLayoutConstraint.activate([
            thumb.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 7),
            thumb.topAnchor.constraint(equalTo: row.topAnchor, constant: 7),
            thumb.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -7),
            thumb.widthAnchor.constraint(equalToConstant: 62),
            textLeading,
            textStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -10),
            textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        if let media = post.media.first {
            thumb.isHidden = false
            thumb.configure(assetName: media.assetName, fileName: media.fileName, remoteURL: media.thumbnailRemoteURL)
            thumb.heightAnchor.constraint(equalToConstant: 64).isActive = true
        } else {
            thumb.isHidden = true
            thumb.widthAnchor.constraint(equalToConstant: 0).isActive = true
            textLeading.isActive = false
            textStack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 18).isActive = true
        }

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() {
        Haptics.tap()
        onOpen?()
    }
}
