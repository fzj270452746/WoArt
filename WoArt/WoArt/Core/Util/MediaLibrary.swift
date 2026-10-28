import UIKit
import AVFoundation

enum MediaLibrary {
    private static let imageCache = NSCache<NSString, UIImage>()
    private static let folderName = "WoArtMedia"

    static var folderURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func url(for fileName: String) -> URL {
        folderURL.appendingPathComponent(fileName)
    }

    static func image(assetName: String, fileName: String?) -> UIImage? {
        if let fileName, let cached = imageCache.object(forKey: fileName as NSString) {
            return cached
        }
        if let fileName, let image = UIImage(contentsOfFile: url(for: fileName).path) {
            imageCache.setObject(image, forKey: fileName as NSString)
            return image
        }
        if let asset = UIImage(named: assetName) {
            return asset
        }
        return nil
    }

    @discardableResult
    static func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let name = "media_\(UUID().uuidString).jpg"
        do {
            try data.write(to: url(for: name), options: .atomic)
            imageCache.setObject(image, forKey: name as NSString)
            return name
        } catch {
            return nil
        }
    }

    static func copyVideo(from sourceURL: URL) -> String? {
        let sourceExtension = sourceURL.pathExtension.lowercased()
        let extensionName = ["mp4", "mov", "m4v"].contains(sourceExtension) ? sourceExtension : "mp4"
        let name = "film_\(UUID().uuidString).\(extensionName)"
        let destination = url(for: name)
        let needsScope = sourceURL.startAccessingSecurityScopedResource()
        defer { if needsScope { sourceURL.stopAccessingSecurityScopedResource() } }
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            return name
        } catch {
            return nil
        }
    }

    static func videoThumbnail(fileName: String) -> UIImage? {
        let asset = AVURLAsset(url: url(for: fileName))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 900, height: 1600)
        let time = CMTime(seconds: 0.4, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    static func videoURL(fileName: String?, bundledName: String?) -> URL? {
        if let fileName {
            let local = url(for: fileName)
            if FileManager.default.fileExists(atPath: local.path) { return local }
        }
        if let bundledName, let bundled = Bundle.main.url(forResource: bundledName, withExtension: nil) {
            return bundled
        }
        return nil
    }

    static func removeMedia(named fileName: String?) {
        guard let fileName else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
        imageCache.removeObject(forKey: fileName as NSString)
    }
}

/// Deterministic generator so generated artwork stays stable between launches.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

extension String {
    var stableSeed: UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }
}

extension MediaItem {
    /// Remote videos play straight from api.woart.app; local picks keep working.
    var playbackURL: URL? {
        if kind == .video, let remoteURL, let url = APIConfig.resolveMediaURL(remoteURL) {
            return url
        }
        return MediaLibrary.videoURL(
            fileName: videoFileName ?? fileName,
            bundledName: bundledVideoName
        )
    }
}
