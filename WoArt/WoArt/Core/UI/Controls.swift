import UIKit

final class EyebrowLabel: UILabel {
    init(_ text: String, color: UIColor = Palette.inkSoft, size: CGFloat = 11) {
        super.init(frame: .zero)
        let font = Typeface.eyebrow(size)
        attributedText = NSAttributedString(
            string: text.uppercased(),
            attributes: [.font: font, .kern: 2.0, .foregroundColor: color]
        )
        numberOfLines = 0
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class PillButton: UIButton {
    enum Style {
        case primary
        case dark
        case light
        case outline
        case destructive
    }

    private let style: Style

    init(title: String, style: Style = .primary, icon: String? = nil, height: CGFloat = 54) {
        self.style = style
        super.init(frame: .zero)

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)

        var container = AttributeContainer()
        container.font = Typeface.chip(16, weight: .bold)
        config.attributedTitle = AttributedString(title, attributes: container)

        if let icon {
            let imageConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
            config.image = UIImage(systemName: icon, withConfiguration: imageConfig)
            config.imagePadding = 9
            config.imagePlacement = .leading
        }

        switch style {
        case .primary:
            config.baseBackgroundColor = Palette.terracotta
            config.baseForegroundColor = .white
        case .dark:
            config.baseBackgroundColor = Palette.walnut
            config.baseForegroundColor = Palette.paper
        case .light:
            config.baseBackgroundColor = Palette.card
            config.baseForegroundColor = Palette.ink
        case .outline:
            config.baseBackgroundColor = .clear
            config.baseForegroundColor = Palette.ink
        case .destructive:
            config.baseBackgroundColor = Palette.terracotta.withAlphaComponent(0.12)
            config.baseForegroundColor = Palette.terracottaDeep
        }

        configuration = config
        titleLabel?.adjustsFontSizeToFitWidth = true
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true

        if style == .outline {
            layer.borderWidth = 1.2
            layer.borderColor = Palette.ink.withAlphaComponent(0.22).cgColor
        }
        if style == .primary || style == .dark {
            layer.shadowColor = (style == .primary ? Palette.terracottaDeep : Palette.walnut).cgColor
            layer.shadowOpacity = 0.26
            layer.shadowRadius = 16
            layer.shadowOffset = CGSize(width: 0, height: 9)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.13, delay: 0, options: [.beginFromCurrentState]) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.975, y: 0.975)
                    : .identity
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

final class CircleIconButton: UIButton {
    private let diameter: CGFloat

    init(
        symbol: String,
        diameter: CGFloat = 42,
        background: UIColor = Palette.card,
        tint: UIColor = Palette.ink,
        pointSize: CGFloat = 16,
        weight: UIImage.SymbolWeight = .semibold
    ) {
        self.diameter = diameter
        super.init(frame: .zero)

        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = tint
        config.contentInsets = .zero
        let imageConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        config.image = UIImage(systemName: symbol, withConfiguration: imageConfig)
        configuration = config

        backgroundColor = background
        layer.cornerRadius = diameter / 2
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.ink.withAlphaComponent(0.08).cgColor
        layer.shadowColor = UIColor(hex: 0x4A2E1C).cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 6)

        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: diameter).isActive = true
        heightAnchor.constraint(equalToConstant: diameter).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.93, y: 0.93) : .identity
            }
        }
    }
}

final class CardView: UIView {
    init(radius: CGFloat = Metrics.cardRadius, fill: UIColor = Palette.card) {
        super.init(frame: .zero)
        backgroundColor = fill
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.ink.withAlphaComponent(0.055).cgColor
        applySoftShadow(opacity: 0.1, radius: 22, y: 12)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class TagChip: UILabel {
    private var insets = UIEdgeInsets(top: 5, left: 11, bottom: 5, right: 11)

    init(text: String, index: Int = 0) {
        super.init(frame: .zero)
        let pair = Palette.tagPalettes[index % Palette.tagPalettes.count]
        backgroundColor = pair.0
        textColor = pair.1
        font = Typeface.chip(12, weight: .semibold)
        self.text = text
        layer.cornerRadius = 11
        layer.cornerCurve = .continuous
        clipsToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}

final class SectionHeadingView: UIView {
    let actionButton = UIButton(type: .system)

    init(eyebrow: String, title: String, actionTitle: String? = nil) {
        super.init(frame: .zero)

        let eyebrowLabel = EyebrowLabel(eyebrow, color: Palette.terracotta)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typeface.display(27, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0

        let textStack = UIStackView(axis: .vertical, spacing: 5, views: [eyebrowLabel, titleLabel])

        addSubview(textStack)
        textStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            textStack.topAnchor.constraint(equalTo: topAnchor),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        if let actionTitle {
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.setTitleColor(Palette.inkSoft, for: .normal)
            actionButton.titleLabel?.font = Typeface.chip(13, weight: .semibold)
            addSubview(actionButton)
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                actionButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                actionButton.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
                actionButton.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 12)
            ])
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class StatColumnView: UIView {
    init(value: String, label: String) {
        super.init(frame: .zero)
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = Typeface.display(23, weight: .bold)
        valueLabel.textColor = Palette.ink
        valueLabel.textAlignment = .center

        let caption = UILabel()
        caption.text = label.uppercased()
        caption.font = Typeface.eyebrow(9)
        caption.textColor = Palette.inkFaint
        caption.textAlignment = .center

        let stack = UIStackView(axis: .vertical, spacing: 2, alignment: .center, views: [valueLabel, caption])
        addSubview(stack)
        stack.pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class EmptyStateView: UIView {
    init(title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        super.init(frame: .zero)

        let ring = RingGlyphView()
        ring.color = Palette.terracotta.withAlphaComponent(0.4)
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.widthAnchor.constraint(equalToConstant: 58).isActive = true
        ring.heightAnchor.constraint(equalToConstant: 58).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typeface.display(25, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = Typeface.body(14.5)
        messageLabel.textColor = Palette.inkSoft
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var views: [UIView] = [ring, titleLabel, messageLabel]
        if let actionTitle, let action {
            let button = PillButton(title: actionTitle, style: .light, height: 44)
            button.addAction(UIAction { _ in action() }, for: .touchUpInside)
            views.append(button)
        }

        let stack = UIStackView(axis: .vertical, spacing: 12, alignment: .center, views: views)
        stack.setCustomSpacing(20, after: ring)
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 20)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class DetailTopBar: UIView {
    let backButton = CircleIconButton(symbol: "chevron.left", diameter: 40, pointSize: 15)
    let trailingButton: CircleIconButton?
    var onBack: (() -> Void)?
    var onTrailing: (() -> Void)?

    init(trailingSymbol: String? = nil) {
        trailingButton = trailingSymbol.map {
            CircleIconButton(symbol: $0, diameter: 40, pointSize: 15)
        }
        super.init(frame: .zero)

        addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 42)
        ])

        if let trailingButton {
            addSubview(trailingButton)
            trailingButton.translatesAutoresizingMaskIntoConstraints = false
            trailingButton.addTarget(self, action: #selector(trailingTapped), for: .touchUpInside)
            NSLayoutConstraint.activate([
                trailingButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                trailingButton.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func backTapped() {
        Haptics.tap()
        if let onBack {
            onBack()
        } else {
            (superview?.next as? UIViewController)?.navigationController?.popViewController(animated: true)
        }
    }

    @objc private func trailingTapped() {
        Haptics.tap()
        onTrailing?()
    }
}

final class DividerLine: UIView {
    init(color: UIColor = Palette.hairline) {
        super.init(frame: .zero)
        backgroundColor = color
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// A view whose gradient follows its bounds.
final class GradientView: UIView {
    private let gradient = CAGradientLayer()

    init(
        colors: [UIColor],
        locations: [NSNumber]? = nil,
        startPoint: CGPoint = CGPoint(x: 0.5, y: 0),
        endPoint: CGPoint = CGPoint(x: 0.5, y: 1)
    ) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        gradient.colors = colors.map(\.cgColor)
        gradient.locations = locations
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        layer.addSublayer(gradient)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = bounds
        CATransaction.commit()
    }
}
