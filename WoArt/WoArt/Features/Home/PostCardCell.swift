import UIKit

protocol PostCardCellDelegate: AnyObject {
    func postCard(_ cell: PostCardCell, didOpen post: Post)
    func postCard(_ cell: PostCardCell, didToggleLike post: Post)
}

final class PostCardCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    static let reuseID = "PostCardCell"

    weak var delegate: PostCardCellDelegate?

    private let card = UIView()
    private let media = ArtworkView()
    private let videoPoster = UIImageView()
    private let videoPlayer = InlineVideoPlayer()
    private let mediaShade = UIView()
    private let playBadge = UIView()
    private let mediaTag = MediaOverlayPill()
    private let mediaCount = MediaOverlayPill()
    private let textStack = UIStackView()
    private let tagRow = UIStackView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let quoteMark = UILabel()
    private let footRow = UIStackView()
    private let avatar = ArtworkView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let likeButton = UIButton(type: .custom)
    private let commentRow = UIStackView()
    private let commentCountLabel = UILabel()

    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var mediaHeight: NSLayoutConstraint?
    private var mediaCollapsed: NSLayoutConstraint?
    private var mediaTop: NSLayoutConstraint?
    private var textTopWithMedia: NSLayoutConstraint?
    private var textTopWithoutMedia: NSLayoutConstraint?
    private var currentPost: Post?
    private var isDarkCard = false
    private var posterURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        card.layer.cornerRadius = 26
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.ink.withAlphaComponent(0.05).cgColor
        card.applySoftShadow(opacity: 0.1, radius: 18, y: 10)
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        leadingConstraint = card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18)
        trailingConstraint = card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18)
        NSLayoutConstraint.activate([
            leadingConstraint!,
            trailingConstraint!,
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2)
        ])

        media.contentMode = .scaleAspectFill
        media.layer.cornerRadius = 20
        media.layer.cornerCurve = .continuous
        media.clipsToBounds = true
        card.addSubview(media)
        media.translatesAutoresizingMaskIntoConstraints = false

        // The opening frame stands in for the poster; the player sits above it
        // and under the shade, so the badge and gradient stay legible.
        videoPoster.contentMode = .scaleAspectFill
        videoPoster.clipsToBounds = true
        videoPoster.isHidden = true
        media.addSubview(videoPoster)
        videoPoster.translatesAutoresizingMaskIntoConstraints = false
        videoPoster.pinEdges(to: media)

        media.addSubview(videoPlayer)
        videoPlayer.translatesAutoresizingMaskIntoConstraints = false
        videoPlayer.pinEdges(to: media)

        mediaShade.backgroundColor = .clear
        mediaShade.isUserInteractionEnabled = false
        media.addSubviews(mediaShade)
        mediaShade.pinEdges(to: media)
        let shade = GradientView(
            colors: [UIColor.clear, Palette.walnut.withAlphaComponent(0.34)],
            locations: [0.45, 1]
        )
        mediaShade.addSubview(shade)
        shade.translatesAutoresizingMaskIntoConstraints = false
        shade.pinEdges(to: mediaShade)

        playBadge.backgroundColor = UIColor(hex: 0xFFFDF7, alpha: 0.92)
        playBadge.layer.cornerRadius = 22
        playBadge.isUserInteractionEnabled = false
        playBadge.layer.shadowColor = UIColor.black.cgColor
        playBadge.layer.shadowOpacity = 0.18
        playBadge.layer.shadowRadius = 10
        playBadge.layer.shadowOffset = CGSize(width: 0, height: 4)
        media.addSubview(playBadge)
        playBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playBadge.centerXAnchor.constraint(equalTo: media.centerXAnchor),
            playBadge.centerYAnchor.constraint(equalTo: media.centerYAnchor),
            playBadge.widthAnchor.constraint(equalToConstant: 44),
            playBadge.heightAnchor.constraint(equalToConstant: 44)
        ])
        let playIcon = UIImageView(
            image: UIImage(
                systemName: "play.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
            )
        )
        playIcon.tintColor = Palette.terracotta
        playBadge.addSubview(playIcon)
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playIcon.centerXAnchor.constraint(equalTo: playBadge.centerXAnchor, constant: 2),
            playIcon.centerYAnchor.constraint(equalTo: playBadge.centerYAnchor)
        ])

        media.addSubview(mediaTag)
        media.addSubview(mediaCount)
        mediaTag.translatesAutoresizingMaskIntoConstraints = false
        mediaCount.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mediaTag.leadingAnchor.constraint(equalTo: media.leadingAnchor, constant: 12),
            mediaTag.topAnchor.constraint(equalTo: media.topAnchor, constant: 12),
            mediaCount.trailingAnchor.constraint(equalTo: media.trailingAnchor, constant: -12),
            mediaCount.topAnchor.constraint(equalTo: media.topAnchor, constant: 12)
        ])

        tagRow.axis = .horizontal
        tagRow.spacing = 6
        tagRow.alignment = .center

        titleLabel.font = Typeface.display(21, weight: .bold)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = Palette.ink

        bodyLabel.font = Typeface.body(13.5)
        bodyLabel.numberOfLines = 2
        bodyLabel.textColor = Palette.inkSoft

        quoteMark.text = "“"
        quoteMark.font = Typeface.display(40, weight: .bold)
        quoteMark.textColor = Palette.brass.withAlphaComponent(0.6)
        quoteMark.isHidden = true

        let textViews = UIStackView(
            axis: .vertical,
            spacing: 7,
            views: [quoteMark, tagRow, titleLabel, bodyLabel]
        )
        textViews.setCustomSpacing(0, after: quoteMark)
        textViews.setCustomSpacing(9, after: tagRow)
        textViews.setCustomSpacing(5, after: titleLabel)
        textStack.axis = .vertical
        textStack.addArrangedSubview(textViews)
        card.addSubview(textStack)
        textStack.translatesAutoresizingMaskIntoConstraints = false

        avatar.layer.cornerRadius = 14
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 28).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 28).isActive = true

        nameLabel.font = Typeface.chip(12.5, weight: .semibold)
        nameLabel.textColor = Palette.ink

        timeLabel.font = Typeface.body(10.5, weight: .medium)
        timeLabel.textColor = Palette.inkFaint

        let identityStack = UIStackView(
            axis: .vertical,
            spacing: 1,
            views: [nameLabel, timeLabel]
        )

        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

        let commentIcon = UIImageView(
            image: UIImage(
                systemName: "bubble.left",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 12.5, weight: .regular)
            )
        )
        commentIcon.tintColor = Palette.inkFaint
        commentCountLabel.font = Typeface.body(11.5, weight: .medium)
        commentCountLabel.textColor = Palette.inkFaint
        commentRow.axis = .horizontal
        commentRow.spacing = 4
        commentRow.alignment = .center
        commentRow.addArrangedSubview(commentIcon)
        commentRow.addArrangedSubview(commentCountLabel)

        footRow.axis = .horizontal
        footRow.alignment = .center
        footRow.spacing = 8
        footRow.addArrangedSubview(avatar)
        footRow.addArrangedSubview(identityStack)
        let spacer = UIView()
        footRow.addArrangedSubview(spacer)
        footRow.addArrangedSubview(likeButton)
        footRow.addArrangedSubview(commentRow)
        textStack.addArrangedSubview(footRow)
        textStack.setCustomSpacing(12, after: textViews)

        NSLayoutConstraint.activate([
            media.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 7),
            media.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -7),
            textStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -15)
        ])
        mediaTop = media.topAnchor.constraint(equalTo: card.topAnchor, constant: 7)
        mediaTop?.isActive = true
        mediaCollapsed = media.heightAnchor.constraint(equalToConstant: 0)
        textTopWithMedia = textStack.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 12)
        textTopWithoutMedia = textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 17)

        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        tap.delegate = self
        card.addGestureRecognizer(tap)
    }

    func configure(post: Post, index: Int, store: StudioStore) {
        currentPost = post
        isDarkCard = post.media.isEmpty

        // One consistent measure keeps the feed calm and scannable.
        leadingConstraint?.constant = 20
        trailingConstraint?.constant = -20

        let background = isDarkCard ? Palette.walnut : Palette.card
        card.backgroundColor = background
        card.layer.borderColor = (isDarkCard ? UIColor.white.withAlphaComponent(0.06) : Palette.ink.withAlphaComponent(0.05)).cgColor

        titleLabel.text = post.title
        titleLabel.textColor = isDarkCard ? Palette.paper : Palette.ink
        titleLabel.font = Typeface.display(isDarkCard ? 23 : 21, weight: .bold)

        bodyLabel.text = post.body.replacingOccurrences(of: "\n", with: " ")
        bodyLabel.textColor = isDarkCard ? Palette.paper.withAlphaComponent(0.72) : Palette.inkSoft
        bodyLabel.numberOfLines = isDarkCard ? 3 : 2
        bodyLabel.font = Typeface.body(isDarkCard ? 14 : 13.5)
        quoteMark.isHidden = !isDarkCard

        nameLabel.text = store.maker(id: post.authorID)?.name ?? "Maker"
        nameLabel.textColor = isDarkCard ? Palette.paper : Palette.ink
        timeLabel.text = post.createdAt.feedTimestamp
        timeLabel.textColor = isDarkCard ? Palette.paper.withAlphaComponent(0.5) : Palette.inkFaint

        if let maker = store.maker(id: post.authorID) {
            avatar.configure(
                assetName: maker.avatarAsset,
                fileName: maker.avatarFile,
                remoteURL: maker.avatarRemoteURL,
                avatar: true,
                monogram: maker.name
            )
        }

        tagRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (tagIndex, tag) in post.tags.prefix(2).enumerated() {
            tagRow.addArrangedSubview(TagChip(text: tag, index: tagIndex))
        }
        tagRow.addArrangedSubview(UIView())
        tagRow.isHidden = post.tags.isEmpty

        let liked = store.isLiked(post.id)
        configureLikeButton(liked: liked, count: store.likeCount(for: post), dark: isDarkCard)
        commentCountLabel.text = "\(store.commentCount(for: post.id))"
        commentCountLabel.textColor = isDarkCard ? Palette.paper.withAlphaComponent(0.5) : Palette.inkFaint
        (commentRow.arrangedSubviews.first as? UIImageView)?.tintColor =
            isDarkCard ? Palette.paper.withAlphaComponent(0.5) : Palette.inkFaint

        mediaHeight?.isActive = false
        mediaCollapsed?.isActive = false
        textTopWithMedia?.isActive = false
        textTopWithoutMedia?.isActive = false

        if let first = post.media.first {
            media.isHidden = false
            textTopWithMedia?.isActive = true
            media.configure(assetName: first.assetName, fileName: first.fileName, remoteURL: first.thumbnailRemoteURL)
            // Keep the feed rhythm even: a wide editorial crop instead of
            // letting portrait media take over the screen.
            mediaHeight = media.heightAnchor.constraint(
                equalTo: media.widthAnchor,
                multiplier: 0.5
            )
            mediaHeight?.isActive = true

            mediaTag.text = post.tags.first?.uppercased() ?? "FROM THE BENCH"
            mediaCount.text = post.media.count > 1 ? "1 / \(post.media.count)" : nil
            mediaCount.isHidden = post.media.count <= 1

            // Films play in place as the feed scrolls; the badge is only a
            // fallback for a clip that cannot be reached. Stills never get one.
            let playback = first.kind == .video ? first.playbackURL : nil
            videoPlayer.prepare(url: playback)
            loadVideoPoster(url: playback)
            playBadge.isHidden = first.kind != .video || playback != nil
        } else {
            media.isHidden = true
            textTopWithoutMedia?.isActive = true
            mediaCollapsed?.isActive = true
            videoPlayer.prepare(url: nil)
            loadVideoPoster(url: nil)
            playBadge.isHidden = true
        }
    }

    // MARK: - Inline film

    override func prepareForReuse() {
        super.prepareForReuse()
        videoPlayer.teardown()
        loadVideoPoster(url: nil)
    }

    /// Called by the feed while the card is on screen.
    func playVideoIfNeeded() {
        videoPlayer.play()
    }

    func pauseVideo() {
        videoPlayer.pause()
    }

    private func loadVideoPoster(url: URL?) {
        posterURL = url
        guard let url else {
            videoPoster.image = nil
            videoPoster.isHidden = true
            return
        }
        if let cached = VideoPosterLoader.shared.cachedPoster(for: url) {
            videoPoster.image = cached
            videoPoster.isHidden = false
            return
        }
        videoPoster.image = nil
        videoPoster.isHidden = true
        VideoPosterLoader.shared.loadPoster(for: url) { [weak self] image in
            guard let self, self.posterURL == url, let image else { return }
            self.videoPoster.image = image
            self.videoPoster.isHidden = false
        }
    }

    private func configureLikeButton(liked: Bool, count: Int, dark: Bool) {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        config.imagePadding = 5
        let symbol = liked ? "heart.fill" : "heart"
        config.image = UIImage(
            systemName: symbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        )
        var title = AttributedString("\(count)")
        title.font = Typeface.body(11.5, weight: .medium)
        config.attributedTitle = title
        if liked {
            config.baseForegroundColor = Palette.terracotta
        } else {
            config.baseForegroundColor = dark ? Palette.paper.withAlphaComponent(0.62) : Palette.inkFaint
        }
        likeButton.configuration = config
    }

    @objc private func likeTapped() {
        guard let post = currentPost else { return }
        Haptics.tap()
        UIView.animate(
            withDuration: 0.18,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.8
        ) {
            self.likeButton.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
        } completion: { _ in
            UIView.animate(withDuration: 0.18) {
                self.likeButton.transform = .identity
            }
        }
        delegate?.postCard(self, didToggleLike: post)
    }

    @objc private func cardTapped() {
        guard let post = currentPost else { return }
        delegate?.postCard(self, didOpen: post)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UIControl { return false }
            view = current.superview
        }
        return true
    }
}

final class MediaOverlayPill: UILabel {
    private let insets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

    init() {
        super.init(frame: .zero)
        backgroundColor = Palette.walnut.withAlphaComponent(0.5)
        textColor = Palette.paper
        font = Typeface.eyebrow(9)
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous
        clipsToBounds = true
        isHidden = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}
