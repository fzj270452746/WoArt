import UIKit
import AVKit

final class MediaViewerViewController: UIViewController {
    private let media: [MediaItem]
    private let startIndex: Int
    private let collectionView: UICollectionView
    private let counter = UILabel()
    private let closeButton = UIButton(type: .system)
    private let layout = UICollectionViewFlowLayout()

    init(media: [MediaItem], startIndex: Int) {
        self.media = media
        self.startIndex = max(0, min(startIndex, max(0, media.count - 1)))
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: 0x120D09)

        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ViewerPageCell.self, forCellWithReuseIdentifier: ViewerPageCell.reuseID)
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.pinEdges(to: view)

        counter.font = Typeface.eyebrow(10)
        counter.textColor = UIColor.white.withAlphaComponent(0.8)
        counter.text = "\(startIndex + 1) / \(media.count)"

        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        closeButton.tintColor = .white
        closeButton.layer.cornerRadius = 21
        closeButton.setImage(
            UIImage(
                systemName: "xmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            ),
            for: .normal
        )
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let hint = UILabel()
        hint.text = "Tap a film to play"
        hint.font = Typeface.body(11, weight: .medium)
        hint.textColor = UIColor.white.withAlphaComponent(0.55)
        hint.isHidden = !media.contains(where: { $0.kind == .video })

        let topScrim = GradientView(
            colors: [UIColor.black.withAlphaComponent(0.55), UIColor.clear]
        )
        let bottomScrim = GradientView(
            colors: [UIColor.clear, UIColor.black.withAlphaComponent(0.45)]
        )
        view.addSubview(topScrim)
        view.addSubview(bottomScrim)
        topScrim.translatesAutoresizingMaskIntoConstraints = false
        bottomScrim.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topScrim.topAnchor.constraint(equalTo: view.topAnchor),
            topScrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topScrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topScrim.heightAnchor.constraint(equalToConstant: 160),
            bottomScrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomScrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomScrim.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomScrim.heightAnchor.constraint(equalToConstant: 150)
        ])

        view.addSubview(counter)
        view.addSubview(closeButton)
        view.addSubview(hint)
        counter.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        hint.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 42),
            closeButton.heightAnchor.constraint(equalToConstant: 42),
            counter.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            counter.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = view.bounds.size
        if layout.itemSize != size {
            layout.itemSize = size
            layout.invalidateLayout()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if startIndex > 0 {
            collectionView.scrollToItem(
                at: IndexPath(item: startIndex, section: 0),
                at: .centeredHorizontally,
                animated: false
            )
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

extension MediaViewerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        media.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ViewerPageCell.reuseID,
            for: indexPath
        ) as! ViewerPageCell
        cell.configure(media: media[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = media[indexPath.item]
        guard item.kind == .video, let url = item.playbackURL else { return }
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        present(controller, animated: true) {
            player.play()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        counter.text = "\(index + 1) / \(media.count)"
    }
}

final class ViewerPageCell: UICollectionViewCell {
    static let reuseID = "ViewerPageCell"

    private let artwork = ArtworkView()
    private let imageView = UIImageView()
    private let videoPoster = UIImageView()
    private let playBadge = UIView()
    private var posterURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        artwork.layer.cornerRadius = 0
        contentView.addSubview(artwork)
        artwork.translatesAutoresizingMaskIntoConstraints = false
        artwork.pinEdges(to: contentView)

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.pinEdges(to: contentView)

        videoPoster.contentMode = .scaleAspectFit
        videoPoster.clipsToBounds = true
        videoPoster.isHidden = true
        contentView.addSubview(videoPoster)
        videoPoster.translatesAutoresizingMaskIntoConstraints = false
        videoPoster.pinEdges(to: contentView)

        playBadge.backgroundColor = UIColor(hex: 0xFFFDF7, alpha: 0.94)
        playBadge.layer.cornerRadius = 32
        contentView.addSubview(playBadge)
        playBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playBadge.widthAnchor.constraint(equalToConstant: 64),
            playBadge.heightAnchor.constraint(equalToConstant: 64)
        ])
        let icon = UIImageView(
            image: UIImage(
                systemName: "play.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
            )
        )
        icon.tintColor = Palette.terracotta
        playBadge.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: playBadge.centerXAnchor, constant: 2),
            icon.centerYAnchor.constraint(equalTo: playBadge.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(media: MediaItem) {
        artwork.configure(
            assetName: media.assetName,
            fileName: media.fileName,
            remoteURL: media.thumbnailRemoteURL,
            contentMode: .scaleAspectFit
        )
        imageView.isHidden = true
        artwork.isHidden = false
        playBadge.isHidden = media.kind != .video
        loadVideoPoster(url: media.kind == .video ? media.playbackURL : nil)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadVideoPoster(url: nil)
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
}
