import UIKit

final class ProfileMenuRow: UIControl {
    private let action: () -> Void

    init(
        symbol: String,
        title: String,
        detail: String? = nil,
        tint: UIColor = Palette.inkSoft,
        action: @escaping () -> Void
    ) {
        self.action = action
        super.init(frame: .zero)
        heightAnchor.constraint(equalToConstant: 58).isActive = true

        let iconCircle = UIView()
        iconCircle.backgroundColor = tint.withAlphaComponent(0.12)
        iconCircle.layer.cornerRadius = 16
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconCircle.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let icon = UIImageView(
            image: UIImage(
                systemName: symbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            )
        )
        icon.tintColor = tint
        iconCircle.isUserInteractionEnabled = false
        iconCircle.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor).isActive = true
        icon.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typeface.chip(14.5, weight: .semibold)
        titleLabel.textColor = Palette.ink

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = Typeface.chip(11.5, weight: .medium)
        detailLabel.textColor = Palette.inkFaint
        detailLabel.textAlignment = .right
        detailLabel.isHidden = detail == nil

        let chevron = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 10.5, weight: .semibold)
            )
        )
        chevron.tintColor = Palette.inkFaint

        addSubviews(iconCircle, titleLabel, detailLabel, chevron)
        NSLayoutConstraint.activate([
            iconCircle.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconCircle.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            detailLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() {
        Haptics.tap()
        action()
    }
}

final class PostListRow: UIControl, UIGestureRecognizerDelegate {
    var onOpen: (() -> Void)?
    var onTrailing: (() -> Void)?
    let trailingButton = UIButton(type: .system)

    init(post: Post, detail: String, trailingSymbol: String? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let card = CardView(radius: 22)
        addSubview(card)
        card.pinEdges(to: self)
        card.heightAnchor.constraint(greaterThanOrEqualToConstant: 94).isActive = true

        let thumb = ArtworkView()
        thumb.layer.cornerRadius = 16
        thumb.layer.cornerCurve = .continuous
        thumb.clipsToBounds = true
        thumb.translatesAutoresizingMaskIntoConstraints = false
        if let media = post.media.first {
            thumb.configure(assetName: media.assetName, fileName: media.fileName, remoteURL: media.thumbnailRemoteURL)
        } else {
            thumb.isHidden = true
        }

        let title = UILabel()
        title.text = post.title
        title.font = Typeface.display(17, weight: .semibold)
        title.textColor = Palette.ink
        title.numberOfLines = 2

        let meta = UILabel()
        meta.text = detail
        meta.font = Typeface.body(10.5)
        meta.textColor = Palette.inkFaint

        let text = UIStackView(axis: .vertical, spacing: 4, views: [title, meta])

        trailingButton.setImage(
            trailingSymbol.flatMap {
                UIImage(
                    systemName: $0,
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                )
            },
            for: .normal
        )
        trailingButton.tintColor = Palette.inkFaint
        trailingButton.translatesAutoresizingMaskIntoConstraints = false
        trailingButton.widthAnchor.constraint(equalToConstant: 36).isActive = true
        trailingButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        trailingButton.isHidden = trailingSymbol == nil
        trailingButton.addTarget(self, action: #selector(trailingTapped), for: .touchUpInside)

        card.addSubviews(thumb, text, trailingButton)
        var constraints: [NSLayoutConstraint] = [
            thumb.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            thumb.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            thumb.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            thumb.widthAnchor.constraint(equalToConstant: 76),
            text.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            text.trailingAnchor.constraint(equalTo: trailingButton.leadingAnchor, constant: -8),
            text.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            trailingButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            trailingButton.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ]
        if post.media.isEmpty {
            thumb.widthAnchor.constraint(equalToConstant: 0).isActive = true
            constraints.append(text.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 18))
        } else {
            thumb.heightAnchor.constraint(equalToConstant: 78).isActive = true
        }
        NSLayoutConstraint.activate(constraints)

        let tap = UITapGestureRecognizer(target: self, action: #selector(openTapped))
        tap.delegate = self
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UIControl { return false }
            view = current.superview
        }
        return true
    }

    @objc private func openTapped() { onOpen?() }

    @objc private func trailingTapped() { onTrailing?() }
}

final class SimpleDetailHeader: UIView {
    let backButton = CircleIconButton(symbol: "chevron.left", diameter: 40, pointSize: 15)
    var onBack: (() -> Void)?
    private let titleLabel: UILabel

    init(title: String, subtitle: String? = nil) {
        titleLabel = UILabel()
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = Typeface.display(26, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0

        var views: [UIView] = [titleLabel]
        if let subtitle {
            let sub = UILabel()
            sub.text = subtitle
            sub.font = Typeface.body(12)
            sub.textColor = Palette.inkFaint
            views.append(sub)
        }
        let stack = UIStackView(axis: .vertical, spacing: 3, views: views)

        addSubviews(backButton, stack)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: topAnchor),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            stack.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func backTapped() { onBack?() }
}
