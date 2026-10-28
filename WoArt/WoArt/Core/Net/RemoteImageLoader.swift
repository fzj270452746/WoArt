import UIKit

/// Small memory/disk-cached image loader for media served from api.woart.app.
final class RemoteImageLoader {
    static let shared = RemoteImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession
    private var inFlight: [String: [(UIImage?) -> Void]] = [:]

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024,
            diskPath: "woart-media-cache"
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.timeoutIntervalForRequest = 25
        session = URLSession(configuration: configuration)
        cache.countLimit = 300
        cache.totalCostLimit = 80 * 1024 * 1024
    }

    func cachedImage(for urlString: String?) -> UIImage? {
        guard let key = normalized(urlString) else { return nil }
        return cache.object(forKey: key as NSString)
    }

    /// Completion always runs on the main queue. Uses the in-memory cache first,
    /// then URLSession's disk cache, so scrolling back through the feed is quiet.
    func load(_ urlString: String?, completion: @escaping (UIImage?) -> Void) {
        guard let key = normalized(urlString) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        if let cached = cache.object(forKey: key as NSString) {
            DispatchQueue.main.async { completion(cached) }
            return
        }
        if inFlight[key] != nil {
            inFlight[key]?.append(completion)
            return
        }
        inFlight[key] = [completion]

        guard let url = APIConfig.resolveMediaURL(key) else {
            finish(key: key, image: nil)
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        session.dataTask(with: request) { [weak self] data, response, _ in
            var image: UIImage?
            if let data,
               let http = response as? HTTPURLResponse,
               (200..<300).contains(http.statusCode) {
                image = UIImage(data: data)
            }
            if let image {
                self?.cache.setObject(image, forKey: key as NSString, cost: data?.count ?? 0)
            } else {
                self?.session.configuration.urlCache?.removeCachedResponse(for: request)
            }
            DispatchQueue.main.async {
                self?.finish(key: key, image: image)
            }
        }.resume()
    }

    private func finish(key: String, image: UIImage?) {
        let callbacks = inFlight.removeValue(forKey: key) ?? []
        callbacks.forEach { $0(image) }
    }

    private func normalized(_ urlString: String?) -> String? {
        guard let urlString else { return nil }
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, URL(string: trimmed) != nil else { return nil }
        return trimmed
    }
}
