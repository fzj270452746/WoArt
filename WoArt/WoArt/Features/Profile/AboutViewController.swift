import UIKit

final class AboutViewController: BaseViewController {
    private let topBar = DetailTopBar()

    override var hidesDock: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        topBar.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        configureBackBar(topBar)

        let wordmark = WordmarkView(size: 26)
        let eyebrow = EyebrowLabel("About WoArt", color: Palette.terracotta)
        let title = UILabel()
        title.text = "A workshop\nin your pocket."
        title.font = Typeface.display(36, weight: .bold)
        title.textColor = Palette.ink
        title.numberOfLines = 0

        let intro = UILabel()
        intro.text = "WoArt is a place to keep the work of your hands, the numbers behind it, and the people you meet at the bench."
        intro.font = Typeface.body(14.5)
        intro.textColor = Palette.inkSoft
        intro.numberOfLines = 0
        intro.setLineHeight(5)

        let ring = RingGlyphView()
        ring.color = Palette.terracotta.withAlphaComponent(0.45)
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.widthAnchor.constraint(equalToConstant: 68).isActive = true
        ring.heightAnchor.constraint(equalToConstant: 68).isActive = true
        let ringWrapper = UIView()
        ringWrapper.translatesAutoresizingMaskIntoConstraints = false
        ringWrapper.heightAnchor.constraint(equalToConstant: 80).isActive = true
        ringWrapper.addSubview(ring)
        NSLayoutConstraint.activate([
            ring.centerXAnchor.constraint(equalTo: ringWrapper.centerXAnchor),
            ring.centerYAnchor.constraint(equalTo: ringWrapper.centerYAnchor)
        ])

        let toolsTitle = EyebrowLabel("Five bench tools", color: Palette.inkFaint)
        let tools = UIStackView(axis: .vertical, spacing: 8, views: [
            aboutRow("ruler", "Board feet, waste and cost"),
            aboutRow("leaf", "Species hardness, movement and workability"),
            aboutRow("drop", "Moisture movement for a real board"),
            aboutRow("scissors", "Cut sequences that respect the kerf"),
            aboutRow("square.split.2x2", "Joinery advice tied to the piece")
        ])

        let sharedCard = CardView(radius: 26)
        let sharedTitle = UILabel()
        sharedTitle.text = "A shared bench"
        sharedTitle.font = Typeface.display(22, weight: .bold)
        sharedTitle.textColor = Palette.ink
        let sharedBody = UILabel()
        sharedBody.text = "Share a finished piece, a film from the workshop, or a gathering you are opening to other makers. Follow the people whose work you admire."
        sharedBody.font = Typeface.body(13.5)
        sharedBody.textColor = Palette.inkSoft
        sharedBody.numberOfLines = 0
        sharedBody.setLineHeight(4)
        let sharedStack = UIStackView(axis: .vertical, spacing: 8, views: [sharedTitle, sharedBody])
        sharedCard.addSubview(sharedStack)
        sharedStack.translatesAutoresizingMaskIntoConstraints = false
        sharedStack.pinEdges(to: sharedCard, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))

        let localCard = CardView(radius: 26)
        let localTitle = UILabel()
        localTitle.text = "Local by design"
        localTitle.font = Typeface.display(22, weight: .bold)
        localTitle.textColor = Palette.ink
        let localBody = UILabel()
        localBody.text = "Your projects, parts and cut plans stay on this device. Pieces, gatherings and comments you choose to share are stored with the WoArt community so other makers can see them. You can remove your account, and its content, from Settings at any time."
        localBody.font = Typeface.body(13.5)
        localBody.textColor = Palette.inkSoft
        localBody.numberOfLines = 0
        localBody.setLineHeight(4)
        let localStack = UIStackView(axis: .vertical, spacing: 8, views: [localTitle, localBody])
        localCard.addSubview(localStack)
        localStack.translatesAutoresizingMaskIntoConstraints = false
        localStack.pinEdges(to: localCard, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))

        let legalTitle = EyebrowLabel("The fine print", color: Palette.inkFaint)
        let legalCard = CardView(radius: 22)
        let legalStack = UIStackView(axis: .vertical, spacing: 0)
        let legalRows: [(String, String)] = [
            ("Terms of Service", "terms"),
            ("Privacy Policy", "privacy"),
            ("End User License Agreement", "eula"),
            ("Support", "support")
        ]
        for (index, item) in legalRows.enumerated() {
            if index > 0 { legalStack.addArrangedSubview(DividerLine()) }
            let button = UIButton(type: .system)
            button.setTitle(item.0, for: .normal)
            button.setTitleColor(Palette.inkSoft, for: .normal)
            button.titleLabel?.font = Typeface.chip(13.5, weight: .semibold)
            button.contentHorizontalAlignment = .left
            button.heightAnchor.constraint(equalToConstant: 48).isActive = true
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                AppLinks.openLegal(item.1, from: self)
            }, for: .touchUpInside)
            legalStack.addArrangedSubview(button)
        }
        legalCard.addSubview(legalStack)
        legalStack.translatesAutoresizingMaskIntoConstraints = false
        legalStack.pinEdges(to: legalCard, insets: UIEdgeInsets(top: 2, left: 18, bottom: 2, right: 18))

        let version = UILabel()
        version.text = "WoArt · version 1.0\nCrafted for makers."
        version.font = Typeface.body(11)
        version.textColor = Palette.inkFaint
        version.textAlignment = .center
        version.numberOfLines = 0

        let stack = UIStackView(
            axis: .vertical,
            spacing: 16,
            views: [wordmark, eyebrow, title, intro, ringWrapper, toolsTitle, tools, sharedCard, localCard, legalTitle, legalCard, version]
        )
        stack.alignment = .fill
        stack.setCustomSpacing(22, after: wordmark)
        stack.setCustomSpacing(8, after: eyebrow)
        stack.setCustomSpacing(12, after: title)
        stack.setCustomSpacing(22, after: intro)
        stack.setCustomSpacing(26, after: ringWrapper)
        stack.setCustomSpacing(10, after: toolsTitle)
        stack.setCustomSpacing(26, after: tools)
        stack.setCustomSpacing(26, after: sharedCard)
        stack.setCustomSpacing(26, after: localCard)
        stack.setCustomSpacing(10, after: legalTitle)
        stack.setCustomSpacing(20, after: legalCard)

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.addSubview(stack)
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
    }

    private func aboutRow(_ symbol: String, _ text: String) -> UIView {
        let icon = UIImageView(
            image: UIImage(
                systemName: symbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
            )
        )
        icon.tintColor = Palette.brass
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 20).isActive = true

        let label = UILabel()
        label.text = text
        label.font = Typeface.body(12.5)
        label.textColor = Palette.inkSoft
        label.numberOfLines = 0

        return UIStackView(axis: .horizontal, spacing: 10, alignment: .center, views: [icon, label])
    }
}
