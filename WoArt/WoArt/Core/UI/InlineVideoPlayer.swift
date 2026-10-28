import UIKit
import AVFoundation

/// A muted, looping film surface that a card can show in place of its poster.
/// The owner decides when it plays, so the feed and the detail screen can drive
/// playback from their own scroll position.
final class InlineVideoPlayer: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private(set) var url: URL?

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        playerLayer.videoGravity = .resizeAspectFill
        isHidden = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Swaps in a new clip. Passing the same URL again keeps the current player.
    func prepare(url: URL?) {
        guard url != self.url else { return }
        teardown()
        self.url = url
        guard let url else { return }

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none
        playerLayer.player = player
        self.player = player

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.player?.seek(to: .zero)
            self.player?.play()
        }
    }

    func play() {
        guard let player else { return }
        isHidden = false
        if player.timeControlStatus != .playing {
            player.play()
        }
    }

    func pause() {
        player?.pause()
    }

    func teardown() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerLayer.player = nil
        isHidden = true
        url = nil
    }
}
