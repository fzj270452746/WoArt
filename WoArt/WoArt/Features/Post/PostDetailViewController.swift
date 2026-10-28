import UIKit
import AVKit

final class PostDetailViewController: BaseViewController {
    private let postID: String
    private let store = StudioStore.shared
    private let scrollView = UIScrollView()
    private let carousel: UICollectionView
    private let sheet = UIView()
    private let contentStack = UIStackView()
    private let tagRow = UIStackView()
    private let titleLabel = UILabel()
    private let authorAvatar = ArtworkView()
    private let authorName = UILabel()
    private let authorTime = UILabel()
    private let followButton = UIButton(type: .custom)
    private let bodyLabel = UILabel()
    private let actionRow = UIStackView()
    private let likeButton = UIButton(type: .custom)
    private let commentCountLabel = UILabel()
    private let divider = DividerLine()
    private let commentsTitle = UILabel()
    private let commentsCount = TagChip(text: "0", index: 0)
    private let commentsStack = UIStackView()
    private let noCommentsLabel = UILabel()
    private let composerBar = UIView()
    private let composerField = UITextField()
    private let sendButton = UIButton(type: .custom)
    private let backButton = CircleIconButton(symbol: "chevron.left", diameter: 40, pointSize: 15)
    private let moreButton = CircleIconButton(symbol: "ellipsis", diameter: 40, pointSize: 15)

    private var carouselHeight: NSLayoutConstraint!
    private var sheetTop: NSLayoutConstraint!
    private var composerBottom: NSLayoutConstraint!
    private var currentPost: Post?
    private var currentMediaIndex = 0
    private var comments: [Comment] = []

    override var hidesDock: Bool { true }

    init(postID: String) {
        self.postID = postID
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        carousel = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        build()
        if store.post(id: postID) != nil {
            render()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataChanged),
            name: .studioDidChange,
            object: nil
        )
        observeKeyboard()

        Task { @MainActor in
            do {
                try await store.loadPost(id: postID)
                if store.post(id: postID) != nil {
                    render()
                } else {
                    navigationController?.popViewController(animated: true)
                }
            } catch {
                if store.post(id: postID) == nil {
                    showToast(error.localizedDescription, icon: "exclamationmark")
                    navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCarouselMetrics()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateMediaPlayback()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseMediaPlayback()
    }

    // MARK: - Build

    private func build() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        carousel.backgroundColor = .clear
        carousel.isPagingEnabled = true
        carousel.showsHorizontalScrollIndicator = false
        carousel.dataSource = self
        carousel.delegate = self
        carousel.layer.cornerRadius = 32
        carousel.layer.cornerCurve = .continuous
        carousel.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        carousel.clipsToBounds = true
        carousel.register(MediaPageCell.self, forCellWithReuseIdentifier: MediaPageCell.reuseID)
        scrollView.addSubview(carousel)
        carousel.translatesAutoresizingMaskIntoConstraints = false
        carouselHeight = carousel.heightAnchor.constraint(equalToConstant: 320)
        NSLayoutConstraint.activate([
            carousel.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            carousel.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            carousel.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            carousel.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            carouselHeight
        ])

        sheet.backgroundColor = Palette.card
        sheet.layer.cornerRadius = 32
        sheet.layer.cornerCurve = .continuous
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.applySoftShadow(opacity: 0.08, radius: 24, y: -6)
        scrollView.addSubview(sheet)
        sheet.translatesAutoresizingMaskIntoConstraints = false
        sheetTop = sheet.topAnchor.constraint(equalTo: carousel.bottomAnchor, constant: -24)
        NSLayoutConstraint.activate([
            sheetTop,
            sheet.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            sheet.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            sheet.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])

        tagRow.axis = .horizontal
        tagRow.spacing = 7

        titleLabel.font = Typeface.display(28, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8

        authorAvatar.layer.cornerRadius = 20
        authorAvatar.clipsToBounds = true
        authorAvatar.translatesAutoresizingMaskIntoConstraints = false
        authorAvatar.widthAnchor.constraint(equalToConstant: 40).isActive = true
        authorAvatar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        authorAvatar.isUserInteractionEnabled = true
        authorAvatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(authorTapped)))

        authorName.font = Typeface.chip(14, weight: .bold)
        authorName.textColor = Palette.ink
        authorTime.font = Typeface.body(11)
        authorTime.textColor = Palette.inkFaint
        let authorText = UIStackView(axis: .vertical, spacing: 2, views: [authorName, authorTime])
        authorText.isUserInteractionEnabled = true
        authorText.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(authorTapped)))

        followButton.translatesAutoresizingMaskIntoConstraints = false
        followButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        followButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 82).isActive = true
        followButton.layer.cornerRadius = 15
        followButton.layer.cornerCurve = .continuous
        followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
        followButton.titleLabel?.font = Typeface.chip(11.5, weight: .bold)

        let authorRow = UIStackView(
            axis: .horizontal,
            spacing: 10,
            alignment: .center,
            views: [authorAvatar, authorText]
        )
        authorRow.addArrangedSubview(UIView())
        authorRow.addArrangedSubview(followButton)

        bodyLabel.font = Typeface.body(15.5)
        bodyLabel.textColor = Palette.inkSoft
        bodyLabel.numberOfLines = 0
        bodyLabel.setLineHeight(6)

        configureActionButtons()
        createCommentsBlock()

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.addArrangedSubview(tagRow)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(authorRow)
        contentStack.addArrangedSubview(bodyLabel)
        contentStack.addArrangedSubview(actionRow)
        contentStack.addArrangedSubview(divider)
        contentStack.addArrangedSubview(commentsHeader())
        contentStack.addArrangedSubview(commentsStack)
        contentStack.addArrangedSubview(noCommentsLabel)
        contentStack.setCustomSpacing(7, after: tagRow)
        contentStack.setCustomSpacing(18, after: titleLabel)
        contentStack.setCustomSpacing(18, after: authorRow)
        contentStack.setCustomSpacing(20, after: bodyLabel)
        contentStack.setCustomSpacing(18, after: actionRow)
        contentStack.setCustomSpacing(18, after: divider)
        contentStack.setCustomSpacing(12, after: contentStack.arrangedSubviews[7])

        sheet.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 22),
            contentStack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: sheet.bottomAnchor, constant: -24)
        ])

        buildComposer()

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        view.addSubview(backButton)
        view.addSubview(moreButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            moreButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            moreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)
        ])
    }

    private func configureActionButtons() {
        var likeConfig = UIButton.Configuration.plain()
        likeConfig.contentInsets = .zero
        likeConfig.imagePadding = 6
        likeConfig.image = UIImage(
            systemName: "heart",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        )
        var likeTitle = AttributedString("0")
        likeTitle.font = Typeface.chip(13, weight: .semibold)
        likeConfig.attributedTitle = likeTitle
        likeConfig.baseForegroundColor = Palette.inkSoft
        likeButton.configuration = likeConfig
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

        let commentIcon = UIImageView(
            image: UIImage(
                systemName: "bubble.left",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            )
        )
        commentIcon.tintColor = Palette.inkSoft
        commentCountLabel.font = Typeface.chip(13, weight: .semibold)
        commentCountLabel.textColor = Palette.inkSoft
        let commentStat = UIStackView(axis: .horizontal, spacing: 6, alignment: .center, views: [commentIcon, commentCountLabel])

        actionRow.axis = .horizontal
        actionRow.spacing = 18
        actionRow.alignment = .center
        actionRow.addArrangedSubview(likeButton)
        actionRow.addArrangedSubview(commentStat)
        actionRow.addArrangedSubview(UIView())
        let rule = UIView()
        rule.backgroundColor = Palette.brass.withAlphaComponent(0.5)
        rule.translatesAutoresizingMaskIntoConstraints = false
        rule.widthAnchor.constraint(equalToConstant: 22).isActive = true
        rule.heightAnchor.constraint(equalToConstant: 2).isActive = true
        actionRow.addArrangedSubview(rule)
    }

    private func commentsHeader() -> UIView {
        commentsTitle.text = "Comments"
        commentsTitle.font = Typeface.display(24, weight: .bold)
        commentsTitle.textColor = Palette.ink

        let titleRow = UIStackView(axis: .horizontal, spacing: 9, alignment: .center, views: [commentsTitle, commentsCount])
        titleRow.addArrangedSubview(UIView())
        return titleRow
    }

    private func createCommentsBlock() {
        commentsStack.axis = .vertical
        commentsStack.spacing = 0

        noCommentsLabel.text = "No notes yet. Add the first thought."
        noCommentsLabel.font = Typeface.body(13, weight: .medium)
        noCommentsLabel.textColor = Palette.inkFaint
        noCommentsLabel.numberOfLines = 0
    }

    private func buildComposer() {
        composerBar.backgroundColor = Palette.paper
        view.addSubview(composerBar)
        composerBar.translatesAutoresizingMaskIntoConstraints = false

        let topLine = DividerLine()
        composerBar.addSubview(topLine)
        topLine.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topLine.topAnchor.constraint(equalTo: composerBar.topAnchor),
            topLine.leadingAnchor.constraint(equalTo: composerBar.leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: composerBar.trailingAnchor)
        ])

        let fieldContainer = UIView()
        fieldContainer.backgroundColor = Palette.cream
        fieldContainer.layer.cornerRadius = 25
        fieldContainer.layer.cornerCurve = .continuous
        composerBar.addSubview(fieldContainer)
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false

        composerField.font = Typeface.body(14.5)
        composerField.textColor = Palette.ink
        composerField.tintColor = Palette.terracotta
        composerField.placeholder = "Add a note…"
        composerField.delegate = self
        composerField.returnKeyType = .send
        composerField.autocorrectionType = .yes
        fieldContainer.addSubview(composerField)
        composerField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.backgroundColor = Palette.terracotta
        sendButton.layer.cornerRadius = 18
        sendButton.tintColor = .white
        sendButton.setImage(
            UIImage(
                systemName: "arrow.up",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
            ),
            for: .normal
        )
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        fieldContainer.addSubview(sendButton)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            composerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composerBar.heightAnchor.constraint(equalToConstant: 64),
            fieldContainer.leadingAnchor.constraint(equalTo: composerBar.leadingAnchor, constant: 18),
            fieldContainer.trailingAnchor.constraint(equalTo: composerBar.trailingAnchor, constant: -18),
            fieldContainer.topAnchor.constraint(equalTo: composerBar.topAnchor, constant: 8),
            fieldContainer.bottomAnchor.constraint(equalTo: composerBar.bottomAnchor, constant: -8),
            composerField.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 16),
            composerField.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            composerField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            sendButton.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -7),
            sendButton.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        composerBottom = composerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        composerBottom.isActive = true

        let safeFill = UIView()
        safeFill.backgroundColor = Palette.paper
        view.addSubview(safeFill)
        safeFill.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            safeFill.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            safeFill.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            safeFill.topAnchor.constraint(equalTo: composerBar.bottomAnchor),
            safeFill.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Render

    private func render() {
        guard let post = store.post(id: postID) else {
            navigationController?.popViewController(animated: true)
            return
        }
        currentPost = post
        let author = store.maker(id: post.authorID)
        let authorIsMe = post.authorID == StudioNamespace.currentUserID

        titleLabel.text = post.title
        bodyLabel.text = post.body
        bodyLabel.isHidden = post.body.isEmpty
        authorName.text = author?.name ?? "Maker"
        authorTime.text = post.createdAt.feedTimestamp
        if let author {
            authorAvatar.configure(
                assetName: author.avatarAsset,
                fileName: author.avatarFile,
                remoteURL: author.avatarRemoteURL,
                avatar: true,
                monogram: author.name
            )
        }
        followButton.isHidden = authorIsMe
        updateFollowButton()

        tagRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, tag) in post.tags.enumerated() {
            tagRow.addArrangedSubview(TagChip(text: tag, index: index))
        }
        tagRow.addArrangedSubview(UIView())
        tagRow.isHidden = post.tags.isEmpty

        updateLikeState()
        commentCountLabel.text = "\(store.commentCount(for: post.id))"
        commentsCount.text = "\(store.commentCount(for: post.id))"

        let hasMedia = !post.media.isEmpty
        carouselHeight.constant = hasMedia ? carouselHeight(for: post.media[0].aspect) : 0
        sheetTop.constant = hasMedia ? -32 : 84
        carousel.reloadData()
        updateCarouselMetrics()
        DispatchQueue.main.async { [weak self] in
            self?.updateMediaPlayback()
        }

        rebuildComments()
    }

    // MARK: - Inline playback

    /// The film in front plays on its own; the rest of the carousel stays still.
    private func updateMediaPlayback() {
        guard let post = currentPost, !post.media.isEmpty else { return }
        for indexPath in carousel.indexPathsForVisibleItems {
            guard let cell = carousel.cellForItem(at: indexPath) as? MediaPageCell else { continue }
            if indexPath.item == currentMediaIndex {
                cell.playVideoIfNeeded()
            } else {
                cell.pauseVideo()
            }
        }
    }

    private func pauseMediaPlayback() {
        for indexPath in carousel.indexPathsForVisibleItems {
            (carousel.cellForItem(at: indexPath) as? MediaPageCell)?.pauseVideo()
        }
    }

    private func carouselHeight(for aspect: Double) -> CGFloat {
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        // A detail hero should sit in the upper third of the screen, not fill it.
        let raw = width * 0.78
        return min(max(raw, 260), 360)
    }

    private func updateCarouselMetrics() {
        guard let post = currentPost, !post.media.isEmpty else { return }
        let width = scrollView.frameLayoutGuide.layoutFrame.width
        guard width > 0 else { return }
        let height = carouselHeight.constant
        if let layout = carousel.collectionViewLayout as? UICollectionViewFlowLayout,
           layout.itemSize.width != width || layout.itemSize.height != height {
            layout.itemSize = CGSize(width: width, height: height)
            layout.invalidateLayout()
        }
    }

    private func updateLikeState() {
        guard let post = currentPost else { return }
        let liked = store.isLiked(post.id)
        if var config = likeButton.configuration {
            config.image = UIImage(
                systemName: liked ? "heart.fill" : "heart",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            )
            var title = AttributedString("\(store.likeCount(for: post))")
            title.font = Typeface.chip(13, weight: .semibold)
            config.attributedTitle = title
            config.baseForegroundColor = liked ? Palette.terracotta : Palette.inkSoft
            likeButton.configuration = config
        }
    }

    private func updateFollowButton() {
        guard let post = currentPost else { return }
        let makerID = post.authorID
        let isFollowing = store.isFollowing(makerID)
        followButton.backgroundColor = isFollowing ? Palette.cream : Palette.terracotta
        followButton.setTitle(isFollowing ? "Following" : "Follow", for: .normal)
        followButton.setTitleColor(isFollowing ? Palette.inkSoft : .white, for: .normal)
    }

    private func rebuildComments() {
        comments = store.comments(for: postID)
        commentsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        commentsCount.text = "\(comments.count)"
        commentCountLabel.text = "\(comments.count)"
        noCommentsLabel.isHidden = !comments.isEmpty

        for comment in comments {
            let row = CommentRowView(
                comment: comment,
                author: store.maker(id: comment.authorID)
            )
            row.onMore = { [weak self, weak row] in
                guard let self else { return }
                self.commentActions(for: comment, anchorRow: row)
            }
            row.onAuthor = { [weak self] in
                self?.openMaker(comment.authorID)
            }
            commentsStack.addArrangedSubview(row)
            let line = DividerLine()
            commentsStack.addArrangedSubview(line)
        }
    }

    @objc private func dataChanged() {
        guard store.post(id: postID) != nil else {
            navigationController?.popViewController(animated: true)
            return
        }
        render()
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func authorTapped() {
        guard let post = currentPost else { return }
        openMaker(post.authorID)
    }

    private func openMaker(_ makerID: String) {
        let profile = MakerProfileViewController(makerID: makerID)
        navigationController?.pushViewController(profile, animated: true)
    }

    @objc private func followTapped() {
        guard currentPost != nil else { return }
        guard AuthGate.requireLogin(from: self, then: { [weak self] in
            self?.toggleFollow()
        }) else { return }
        toggleFollow()
    }

    private func toggleFollow() {
        guard let post = currentPost else { return }
        let isFollowing = store.toggleFollow(makerID: post.authorID)
        updateFollowButton()
        if isFollowing {
            Haptics.success()
            showToast("Following \(store.maker(id: post.authorID)?.name ?? "maker")", icon: "checkmark")
        }
    }

    @objc private func likeTapped() {
        guard currentPost != nil else { return }
        guard AuthGate.requireLogin(from: self, then: { [weak self] in
            self?.applyLike()
        }) else { return }
        applyLike()
    }

    private func applyLike() {
        guard let post = currentPost else { return }
        Haptics.tap()
        store.toggleLike(postID: post.id)
        updateLikeState()
    }

    @objc private func moreTapped() {
        guard let post = currentPost else { return }
        let isMine = post.authorID == StudioNamespace.currentUserID
        var options: [ActionSheetViewController.Option] = []
        if isMine {
            options.append(
                .init(title: "Delete post", symbol: "trash", destructive: true) { [weak self] in
                    self?.confirmDeletePost()
                }
            )
        } else {
            options.append(
                .init(title: "Report post", symbol: "flag", destructive: true) { [weak self] in
                    let report = ReportViewController(target: .post(post.id))
                    self?.navigationController?.pushViewController(report, animated: true)
                }
            )
        }
        options.append(
            .init(title: "Cancel", symbol: "xmark", destructive: false) {}
        )
        ActionSheetViewController.present(from: self, title: "This piece", options: options)
    }

    private func confirmDeletePost() {
        ConfirmSheetViewController.present(
            from: self,
            title: "Delete this piece?",
            message: "The post and its comments will be removed. This cannot be undone.",
            confirmTitle: "Delete post",
            destructive: true
        ) { [weak self] in
            guard let self else { return }
            self.store.deletePost(id: self.postID)
            self.navigationController?.popViewController(animated: true)
            self.showToast("Post deleted", icon: "trash")
        }
    }

    private func commentActions(for comment: Comment, anchorRow: CommentRowView?) {
        let isMine = comment.authorID == StudioNamespace.currentUserID
        var options: [ActionSheetViewController.Option] = []
        if isMine {
            options.append(
                .init(title: "Delete comment", symbol: "trash", destructive: true) { [weak self] in
                    self?.confirmDeleteComment(comment)
                }
            )
        } else {
            options.append(
                .init(title: "Report comment", symbol: "flag", destructive: true) { [weak self] in
                    let report = ReportViewController(target: .comment(id: comment.id, postID: comment.postID))
                    self?.navigationController?.pushViewController(report, animated: true)
                }
            )
        }
        options.append(.init(title: "Cancel", symbol: "xmark", destructive: false) {})
        ActionSheetViewController.present(from: self, title: "This comment", options: options)
    }

    private func confirmDeleteComment(_ comment: Comment) {
        ConfirmSheetViewController.present(
            from: self,
            title: "Delete this comment?",
            message: "It will be removed for everyone viewing this piece.",
            confirmTitle: "Delete comment",
            destructive: true
        ) { [weak self] in
            self?.store.deleteComment(id: comment.id)
            self?.showToast("Comment removed", icon: "trash")
        }
    }

    @objc private func sendTapped() {
        submitComment()
    }

    private func submitComment() {
        let text = composerField.text?.trimmed ?? ""
        guard !text.isEmpty else {
            showToast("Write a note first.", icon: "exclamationmark")
            return
        }
        guard AuthGate.requireLogin(from: self, then: { [weak self] in
            self?.submitComment()
        }) else { return }
        guard let post = currentPost else { return }
        store.addComment(postID: post.id, text: text)
        composerField.text = nil
        composerField.resignFirstResponder()
        Haptics.success()
        rebuildComments()
        updateLikeState()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.scrollView.layoutIfNeeded()
            let bottom = CGPoint(
                x: 0,
                y: max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height + 96)
            )
            self.scrollView.setContentOffset(bottom, animated: true)
        }
    }

    // MARK: - Keyboard

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY)
        let lift = max(0, overlap - view.safeAreaInsets.bottom)
        UIView.animate(withDuration: duration) {
            self.composerBottom.constant = -lift
            self.scrollView.contentInset.bottom = 96 + lift
            self.scrollView.verticalScrollIndicatorInsets.bottom = 96 + lift
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide() {
        UIView.animate(withDuration: 0.25) {
            self.composerBottom.constant = 0
            self.scrollView.contentInset.bottom = 96
            self.scrollView.verticalScrollIndicatorInsets.bottom = 96
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UICollectionView

extension PostDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        currentPost?.media.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MediaPageCell.reuseID,
            for: indexPath
        ) as! MediaPageCell
        if let media = currentPost?.media[indexPath.item] {
            cell.configure(media: media, index: indexPath.item, total: currentPost?.media.count ?? 1)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let post = currentPost, indexPath.item < post.media.count else { return }
        presentMedia(post.media, index: indexPath.item)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === carousel {
            pauseMediaPlayback()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === carousel, scrollView.bounds.width > 0 else { return }
        currentMediaIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        updateMediaPlayback()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === carousel, scrollView.bounds.width > 0 else { return }
        currentMediaIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        updateMediaPlayback()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        (cell as? MediaPageCell)?.pauseVideo()
    }

    private func presentMedia(_ media: [MediaItem], index: Int) {
        pauseMediaPlayback()
        let item = media[index]
        if item.kind == .video, let url = item.playbackURL {
            let player = AVPlayer(url: url)
            let controller = AVPlayerViewController()
            controller.player = player
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true) {
                player.play()
            }
        } else {
            let viewer = MediaViewerViewController(media: media, startIndex: index)
            viewer.modalPresentationStyle = .fullScreen
            present(viewer, animated: true)
        }
    }
}

// MARK: - Text field

extension PostDetailViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if AuthService.shared.isSignedIn { return true }
        AuthGate.requireLogin(from: self) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.composerField.becomeFirstResponder()
            }
        }
        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitComment()
        return false
    }
}

// MARK: - Comment row

final class CommentRowView: UIView {
    var onMore: (() -> Void)?
    var onAuthor: (() -> Void)?

    init(comment: Comment, author: Maker?) {
        super.init(frame: .zero)

        let avatar = ArtworkView()
        avatar.layer.cornerRadius = 15
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 30).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 30).isActive = true
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(authorTapped)))
        if let author {
            avatar.configure(
                assetName: author.avatarAsset,
                fileName: author.avatarFile,
                remoteURL: author.avatarRemoteURL,
                avatar: true,
                monogram: author.name
            )
        }

        let name = UILabel()
        name.text = author?.name ?? "Maker"
        name.font = Typeface.chip(12.5, weight: .semibold)
        name.textColor = Palette.ink

        let time = UILabel()
        time.text = comment.createdAt.feedTimestamp
        time.font = Typeface.body(10)
        time.textColor = Palette.inkFaint

        let meta = UIStackView(axis: .vertical, spacing: 1, views: [name, time])

        let more = UIButton(type: .system)
        more.setImage(
            UIImage(
                systemName: "ellipsis",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            ),
            for: .normal
        )
        more.tintColor = Palette.inkFaint
        more.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        more.translatesAutoresizingMaskIntoConstraints = false
        more.widthAnchor.constraint(equalToConstant: 30).isActive = true
        more.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let header = UIStackView(axis: .horizontal, spacing: 9, alignment: .center, views: [avatar, meta])
        header.addArrangedSubview(UIView())
        header.addArrangedSubview(more)

        let text = UILabel()
        text.text = comment.text
        text.font = Typeface.body(13.5)
        text.textColor = Palette.inkSoft
        text.numberOfLines = 0
        text.setLineHeight(4)

        let stack = UIStackView(axis: .vertical, spacing: 8, views: [header, text])
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func moreTapped() { onMore?() }
    @objc private func authorTapped() { onAuthor?() }
}
