import UIKit

final class CreateChooserViewController: BaseViewController {
    var onChoosePost: (() -> Void)?
    var onChooseEvent: (() -> Void)?
    var onChooseProject: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.paper

        let eyebrow = EyebrowLabel("Make something", color: Palette.terracotta)
        let title = UILabel()
        title.text = "What's on the bench?"
        title.font = Typeface.display(31, weight: .bold)
        title.textColor = Palette.ink
        title.numberOfLines = 0

        let postCard = makeOption(
            symbol: "photo.on.rectangle.angled",
            title: "Share a piece",
            subtitle: "A photo, a film, a note from the workshop.",
            tint: Palette.terracotta
        )
        postCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(choosePost)))

        let eventCard = makeOption(
            symbol: "person.2.wave.2",
            title: "Host a gathering",
            subtitle: "Bring makers together around a bench.",
            tint: Palette.moss
        )
        eventCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(chooseEvent)))

        let projectCard = makeOption(
            symbol: "hammer",
            title: "Start a project",
            subtitle: "Parts, cut plan, movement and build steps.",
            tint: Palette.brass
        )
        projectCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(chooseProject)))

        let note = UILabel()
        note.text = "Nothing is shared until you press publish. Projects stay on this device."
        note.font = Typeface.body(12)
        note.textColor = Palette.inkFaint
        note.numberOfLines = 0

        let stack = UIStackView(
            axis: .vertical,
            spacing: 14,
            views: [eyebrow, title, postCard, eventCard, projectCard, note]
        )
        stack.setCustomSpacing(8, after: eyebrow)
        stack.setCustomSpacing(20, after: title)
        stack.setCustomSpacing(8, after: projectCard)
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.addSubview(stack)
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
    }

    private func makeOption(symbol: String, title: String, subtitle: String, tint: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = Palette.card
        container.layer.cornerRadius = 24
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = Palette.ink.withAlphaComponent(0.06).cgColor
        container.applySoftShadow(opacity: 0.08, radius: 16, y: 8)

        let iconCircle = UIView()
        iconCircle.backgroundColor = tint.withAlphaComponent(0.12)
        iconCircle.layer.cornerRadius = 25
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.widthAnchor.constraint(equalToConstant: 50).isActive = true
        iconCircle.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let icon = UIImageView()
        icon.image = UIImage(
            systemName: symbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        )
        icon.tintColor = tint
        iconCircle.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor).isActive = true
        icon.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typeface.display(20, weight: .semibold)
        titleLabel.textColor = Palette.ink

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = Typeface.body(12.5)
        subtitleLabel.textColor = Palette.inkSoft
        subtitleLabel.numberOfLines = 0

        let textStack = UIStackView(axis: .vertical, spacing: 3, views: [titleLabel, subtitleLabel])

        let chevron = UIImageView(
            image: UIImage(
                systemName: "arrow.up.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            )
        )
        chevron.tintColor = Palette.inkFaint

        container.addSubviews(iconCircle, textStack, chevron)
        NSLayoutConstraint.activate([
            iconCircle.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconCircle.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: iconCircle.trailingAnchor, constant: 14),
            textStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -10),

            chevron.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            chevron.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    @objc private func choosePost() {
        Haptics.tap()
        let action = onChoosePost
        dismiss(animated: true) { action?() }
    }

    @objc private func chooseEvent() {
        Haptics.tap()
        let action = onChooseEvent
        dismiss(animated: true) { action?() }
    }

    @objc private func chooseProject() {
        Haptics.tap()
        let action = onChooseProject
        dismiss(animated: true) { action?() }
    }
}
