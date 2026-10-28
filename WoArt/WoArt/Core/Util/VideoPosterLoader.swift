import UIKit
import AVFoundation

/// Grabs the opening frame of a film so cards can show the clip itself instead
/// of a separate still. Frames are kept in memory for the session.
final class VideoPosterLoader {
    static let shared = VideoPosterLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let queue = DispatchQueue(label: "woart.video-poster", qos: .userInitiated)

    private init() {
        cache.countLimit = 120
        cache.totalCostLimit = 60 * 1024 * 1024
    }

    func cachedPoster(for url: URL?) -> UIImage? {
        guard let url else { return nil }
        return cache.object(forKey: url as NSURL)
    }

    /// Completion always runs on the main queue.
    func loadPoster(for url: URL, completion: @escaping (UIImage?) -> Void) {
        if let cached = cache.object(forKey: url as NSURL) {
            DispatchQueue.main.async { completion(cached) }
            return
        }
        queue.async { [weak self] in
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 1600, height: 1600)
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            // A hair after zero avoids the black frame some encoders start on.
            let time = CMTime(seconds: 0.05, preferredTimescale: 600)
            let image: UIImage?
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                image = UIImage(cgImage: cgImage)
            } else {
                image = nil
            }
            if let image {
                self?.cache.setObject(image, forKey: url as NSURL)
            }
            DispatchQueue.main.async { completion(image) }
        }
    }
}
