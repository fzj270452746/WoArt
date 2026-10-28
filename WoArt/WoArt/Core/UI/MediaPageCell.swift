import UIKit

final class MediaPageCell: UICollectionViewCell {
    static let reuseID = "MediaPageCell"

    private let artwork = ArtworkView()
    private let videoPoster = UIImageView()
    private let videoPlayer = InlineVideoPlayer()
    private let playBadge = UIView()
    private let playIcon = UIImageView()
    private let counter = MediaOverlayPill()
    private var posterURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = Palette.walnut

        artwork.clipsToBounds = true
        contentView.addSubview(artwork)
        artwork.translatesAutoresizingMaskIntoConstraints = false
        artwork.pinEdges(to: contentView)

        videoPoster.contentMode = .scaleAspectFill
        videoPoster.clipsToBounds = true
        videoPoster.isHidden = true
        contentView.addSubview(videoPoster)
        videoPoster.translatesAutoresizingMaskIntoConstraints = false
        videoPoster.pinEdges(to: contentView)

        contentView.addSubview(videoPlayer)
        videoPlayer.translatesAutoresizingMaskIntoConstraints = false
        videoPlayer.pinEdges(to: contentView)

        playBadge.backgroundColor = UIColor(hex: 0xFFFDF7, alpha: 0.92)
        playBadge.layer.cornerRadius = 29
        playBadge.layer.shadowColor = UIColor.black.cgColor
        playBadge.layer.shadowOpacity = 0.25
        playBadge.layer.shadowRadius = 14
        playBadge.layer.shadowOffset = CGSize(width: 0, height: 5)
        contentView.addSubview(playBadge)
        playBadge.translatesAutoresizingMaskIntoConstraints = false

        playIcon.image = UIImage(
            systemName: "play.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        )
        playIcon.tintColor = Palette.terracotta
        playBadge.addSubview(playIcon)
        playIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            playBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playBadge.widthAnchor.constraint(equalToConstant: 58),
            playBadge.heightAnchor.constraint(equalToConstant: 58),
            playIcon.centerXAnchor.constraint(equalTo: playBadge.centerXAnchor, constant: 2),
            playIcon.centerYAnchor.constraint(equalTo: playBadge.centerYAnchor)
        ])

        contentView.addSubview(counter)
        counter.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            counter.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            counter.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -44)
        ])
        counter.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(media: MediaItem, index: Int, total: Int) {
        artwork.configure(assetName: media.assetName, fileName: media.fileName, remoteURL: media.thumbnailRemoteURL)
        let playback = media.kind == .video ? media.playbackURL : nil
        videoPlayer.prepare(url: playback)
        loadVideoPoster(url: playback)
        // A film starts on its own once its page is in front. The badge only
        // remains for a clip that cannot be reached.
        playBadge.isHidden = media.kind != .video || playback != nil
        counter.text = "\(index + 1) / \(total)"
        counter.isHidden = total <= 1
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

    func playVideoIfNeeded() {
        videoPlayer.play()
    }

    func pauseVideo() {
        videoPlayer.pause()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        videoPlayer.teardown()
        loadVideoPoster(url: nil)
    }
}
