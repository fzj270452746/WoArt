import UIKit
import SafariServices

enum AppLinks {
    static let site = URL(string: "https://woart.app")!
    static let terms = URL(string: "https://woart.app/terms")!
    static let privacy = URL(string: "https://woart.app/privacy")!
    static let eula = URL(string: "https://woart.app/eula")!
    static let support = URL(string: "https://woart.app/support")!
    static let supportEmail = "support@woart.app"

    static func legalURL(for slug: String) -> URL {
        switch slug {
        case "terms": return terms
        case "privacy": return privacy
        case "eula": return eula
        case "support": return support
        default: return site
        }
    }

    @MainActor
    static func openLegal(_ slug: String, from controller: UIViewController) {
        present(url: legalURL(for: slug), from: controller)
    }

    @MainActor
    static func openSupport(from controller: UIViewController) {
        present(url: support, from: controller)
    }

    @MainActor
    private static func present(url: URL, from controller: UIViewController) {
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = Palette.terracotta
        safari.dismissButtonStyle = .close
        controller.present(safari, animated: true)
    }
}
