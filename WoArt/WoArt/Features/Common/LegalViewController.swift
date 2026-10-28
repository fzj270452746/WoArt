import UIKit

struct LegalDocument {
    let title: String
    let intro: String
    let sections: [(heading: String, body: String)]

    static func from(slug: String) -> LegalDocument {
        switch slug {
        case "privacy":
            return .privacy
        case "eula":
            return .eula
        default:
            return .terms
        }
    }

    static let terms = LegalDocument(
        title: "Terms of Service",
        intro: "These terms describe how WoArt works and what we expect from each other while you are here. By creating an account or using the app, you agree to them.",
        sections: [
            (
                "Your account",
                "You are responsible for the name and password you choose and for activity that happens under your account. Keep your password private. If you believe someone else has access to your account, sign out and remove the account from this device."
            ),
            (
                "What belongs to you",
                "Photographs, video and text you create remain yours. By sharing a piece in WoArt you allow the app to display that content to you and to other makers in the app. You confirm that you have the right to share what you post, including any work made with other people."
            ),
            (
                "A useful atelier",
                "Share work you made or have permission to share. Do not post illegal material, harassment, private information about other people, or content that encourages harm. Do not use the app to sell unsafe goods or misrepresent who you are."
            ),
            (
                "Reports and removals",
                "Every post, comment and profile can be reported from the screen where it appears. Reporting content or a maker removes that content from your view immediately. Accounts that repeatedly break these terms may lose access."
            ),
            (
                "Changes",
                "WoArt grows with the people using it. Features and these terms may change over time. When a change materially affects your rights, the app will make that clear before the change takes effect."
            ),
            (
                "Contact",
                "Questions about the service can be sent through the support address listed on the App Store product page."
            )
        ]
    )

    static let privacy = LegalDocument(
        title: "Privacy Policy",
        intro: "WoArt keeps your workshop private. This policy explains what the app stores and where it lives.",
        sections: [
            (
                "What we store",
                "Your maker name, password hash, profile details, posts, comments, gatherings and the pieces you have liked or saved are stored on WoArt's servers. Your password is kept as a salted hash, never as plain text. The Bench — projects, parts, stock and cut plans — stays on this device."
            ),
            (
                "Where it lives",
                "Account, community and media data are stored in a Cloudflare D1 database and R2 object storage and delivered through Cloudflare's network. Session tokens are kept in the device keychain. Removing your account removes your profile, content and media from the live service."
            ),
            (
                "Photos and videos",
                "When you choose a photo or a video for a post, profile or gathering, the app uploads only the file you selected. It does not browse your library. Removing a post, gathering or account deletes the associated files from live storage."
            ),
            (
                "Sign in with Apple",
                "If you use Sign in with Apple, Apple provides a stable identifier so WoArt can recognize your account. WoArt stores that identifier with your account. Apple's own privacy policy applies to the sign in step."
            ),
            (
                "Your choices",
                "You can edit your profile at any time, remove your pieces, and delete your account from Settings. Deleting the account removes your profile, content, media and reservations from WoArt's live systems."
            ),
            (
                "Children",
                "WoArt is not directed at children under 13. If you are below the age required in your region to agree to these terms, please use the app with a parent or guardian."
            )
        ]
    )

    static let eula = LegalDocument(
        title: "End User License Agreement",
        intro: "This agreement covers your use of the WoArt application. It is a licence, not a sale of the app itself.",
        sections: [
            (
                "Licence",
                "You receive a personal, non-transferable licence to use WoArt on Apple devices that you own or control, in accordance with the App Store terms. The app, its design and its written content may not be redistributed, resold or copied except as allowed by law."
            ),
            (
                "Your content",
                "You keep ownership of the photographs, films and words you create. You are responsible for making sure you have the rights to publish them. Do not upload someone else's work as your own."
            ),
            (
                "Acceptable use",
                "Do not reverse engineer the app, interfere with its operation, or use it to harass, defraud or endanger another person. Tools and calculators in WoArt are aids, not professional advice; verify measurements before cutting material."
            ),
            (
                "Availability",
                "Features may be added, changed or removed as the app develops. Local content remains available without a network connection. The app is provided as is, without warranties beyond those required by law."
            ),
            (
                "Ending the licence",
                "You may stop using WoArt at any time and delete your account from Settings. The licence ends if you materially breach these terms or the App Store terms."
            )
        ]
    )
}

final class LegalViewController: BaseViewController {
    private let document: LegalDocument

    init(document: LegalDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        let eyebrow = EyebrowLabel("The fine print", color: Palette.terracotta)
        let title = UILabel()
        title.text = document.title
        title.font = Typeface.display(36, weight: .bold)
        title.textColor = Palette.ink
        title.numberOfLines = 0

        let intro = UILabel()
        intro.text = document.intro
        intro.font = Typeface.body(15)
        intro.textColor = Palette.inkSoft
        intro.numberOfLines = 0
        intro.setLineHeight(6)

        let stack = UIStackView(axis: .vertical, spacing: 22, views: [eyebrow, title, intro])
        stack.setCustomSpacing(8, after: eyebrow)
        stack.setCustomSpacing(14, after: title)

        for section in document.sections {
            let heading = UILabel()
            heading.text = section.heading
            heading.font = Typeface.display(18, weight: .semibold)
            heading.textColor = Palette.ink

            let body = UILabel()
            body.text = section.body
            body.font = Typeface.body(14.5)
            body.textColor = Palette.inkSoft
            body.numberOfLines = 0
            body.setLineHeight(5)

            let group = UIStackView(axis: .vertical, spacing: 7, views: [heading, body])
            stack.addArrangedSubview(group)
        }

        let updated = EyebrowLabel("Last updated · October 2026", color: Palette.inkFaint, size: 9)
        stack.addArrangedSubview(updated)
        stack.setCustomSpacing(30, after: updated)

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        scroll.addSubview(stack)
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        let close = CircleIconButton(symbol: "xmark", diameter: 40, pointSize: 14)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(close)
        close.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.gutter),

            scroll.topAnchor.constraint(equalTo: close.bottomAnchor, constant: 20),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.gutter + 2),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.gutter - 2),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
    }

    @objc private func closeTapped() {
        view.endEditing(true)
        dismiss(animated: true)
    }
}
