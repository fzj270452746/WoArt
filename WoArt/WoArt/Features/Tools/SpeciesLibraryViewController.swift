import UIKit

final class SpeciesLibraryViewController: ToolPageViewController {
    private let searchField = UITextField()
    private let listStack = UIStackView()
    private let countLabel = UILabel()
    private let emptyLabel = UILabel()

    init() {
        super.init(
            eyebrow: "Workshop tool 02",
            title: "Fourteen woods,\nread honestly.",
            intro: "Hardness, density, movement and workability side by side. Choose a wood for how it behaves, not just how it looks."
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        let searchCard = UIView()
        searchCard.backgroundColor = Palette.card
        searchCard.layer.cornerRadius = 22
        searchCard.layer.cornerCurve = .continuous
        searchCard.layer.borderWidth = 1
        searchCard.layer.borderColor = Palette.ink.withAlphaComponent(0.06).cgColor

        let magnifier = UIImageView(
            image: UIImage(
                systemName: "magnifyingglass",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            )
        )
        magnifier.tintColor = Palette.inkFaint

        searchField.font = Typeface.body(14)
        searchField.textColor = Palette.ink
        searchField.tintColor = Palette.terracotta
        searchField.placeholder = "Search by name or use…"
        searchField.autocorrectionType = .no
        searchField.clearButtonMode = .whileEditing
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        searchField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        searchCard.heightAnchor.constraint(equalToConstant: 52).isActive = true
        searchCard.addSubviews(magnifier, searchField)
        NSLayoutConstraint.activate([
            magnifier.leadingAnchor.constraint(equalTo: searchCard.leadingAnchor, constant: 16),
            magnifier.centerYAnchor.constraint(equalTo: searchCard.centerYAnchor),
            magnifier.widthAnchor.constraint(equalToConstant: 20),
            searchField.leadingAnchor.constraint(equalTo: magnifier.trailingAnchor, constant: 9),
            searchField.trailingAnchor.constraint(equalTo: searchCard.trailingAnchor, constant: -12),
            searchField.centerYAnchor.constraint(equalTo: searchCard.centerYAnchor)
        ])
        addSection(searchCard, spacing: 14)

        countLabel.font = Typeface.eyebrow(9)
        countLabel.textColor = Palette.inkFaint
        addSection(countLabel, spacing: 4)

        listStack.axis = .vertical
        listStack.spacing = 10
        addSection(listStack, spacing: 12)

        emptyLabel.text = "No wood matches that name. Try “oak”, “turning” or “outdoor”."
        emptyLabel.font = Typeface.body(13)
        emptyLabel.textColor = Palette.inkFaint
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        addSection(emptyLabel)

        addSection(
            ToolNoteView(
                text: "Janka values measure the force needed to embed a steel ball halfway into the wood. Movement figures are total shrinkage from green to oven-dry; your shop will see less than that."
            )
        )

        rebuild()
    }

    @objc private func searchChanged() {
        rebuild()
    }

    private func rebuild() {
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let query = searchField.text?.trimmed.lowercased() ?? ""
        let filtered = ToolData.species.filter { species in
            if query.isEmpty { return true }
            return species.name.lowercased().contains(query)
                || species.botanical.lowercased().contains(query)
                || species.uses.contains { $0.lowercased().contains(query) }
        }
        countLabel.text = "\(filtered.count) SPECIES"
        emptyLabel.isHidden = !filtered.isEmpty

        for species in filtered {
            let card = SpeciesListCard(species: species)
            card.onOpen = { [weak self] in
                let detail = SpeciesDetailViewController(species: species)
                self?.navigationController?.pushViewController(detail, animated: true)
            }
            listStack.addArrangedSubview(card)
        }
    }
}

final class SpeciesListCard: UIControl {
    var onOpen: (() -> Void)?

    init(species: WoodSpecies) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 104).isActive = true

        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 24
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.ink.withAlphaComponent(0.06).cgColor
        card.isUserInteractionEnabled = false
        addSubview(card)
        card.pinEdges(to: self)

        let swatch = SpeciesSwatchView(color: UIColor(hex: species.swatch), seed: species.id)
        swatch.layer.cornerRadius = 17
        swatch.layer.cornerCurve = .continuous
        swatch.clipsToBounds = true
        swatch.translatesAutoresizingMaskIntoConstraints = false

        let name = UILabel()
        name.text = species.name
        name.font = Typeface.display(20, weight: .semibold)
        name.textColor = Palette.ink

        let botanical = UILabel()
        botanical.text = species.botanical
        botanical.font = Typeface.body(10.5)
        botanical.textColor = Palette.inkFaint

        let bottom = UILabel()
        bottom.font = Typeface.chip(10, weight: .medium)
        bottom.textColor = Palette.inkSoft
        bottom.text = "Janka \(formatted(species.janka))  ·  \(species.uses.first ?? "")"

        let textStack = UIStackView(axis: .vertical, spacing: 2, views: [name, botanical, bottom])
        textStack.setCustomSpacing(6, after: botanical)

        let chevron = UIImageView(
            image: UIImage(
                systemName: "arrow.up.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
            )
        )
        chevron.tintColor = Palette.inkFaint

        card.addSubviews(swatch, textStack, chevron)
        NSLayoutConstraint.activate([
            swatch.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            swatch.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            swatch.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            swatch.widthAnchor.constraint(equalToConstant: 66),
            textStack.leadingAnchor.constraint(equalTo: swatch.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        addTarget(self, action: #selector(pressed), for: .touchDown)
        addTarget(self, action: #selector(released), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func formatted(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    @objc private func tapped() { onOpen?() }

    @objc private func pressed() {
        UIView.animate(withDuration: 0.12) {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }
    }

    @objc private func released() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.3) {
            self.transform = .identity
        }
    }
}

final class SpeciesSwatchView: UIView {
    private let color: UIColor
    private let seed: UInt64

    init(color: UIColor, seed: String) {
        self.color = color
        self.seed = seed.stableSeed
        super.init(frame: .zero)
        backgroundColor = color
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let light = color.mixed(with: .white, amount: 0.34)
        let dark = color.mixed(with: .black, amount: 0.18)
        let colors = [light.cgColor, color.cgColor, dark.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1]) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: rect.width, y: rect.height),
                options: []
            )
        }

        var rng = SeededGenerator(seed: seed)
        for index in 0..<14 {
            let y = CGFloat(index) / 14 * rect.height + CGFloat.random(in: -3...3, using: &rng)
            let bend = CGFloat.random(in: -8...8, using: &rng)
            context.setStrokeColor(dark.withAlphaComponent(0.16).cgColor)
            context.setLineWidth(0.7)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -6, y: y))
            path.addCurve(
                to: CGPoint(x: rect.width + 6, y: y + bend),
                controlPoint1: CGPoint(x: rect.width * 0.3, y: y - 10),
                controlPoint2: CGPoint(x: rect.width * 0.7, y: y + 12)
            )
            path.stroke()
        }

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
        context.setLineWidth(1.2)
        for index in 0..<4 {
            let radius = rect.width * (0.12 + CGFloat(index) * 0.16)
            context.strokeEllipse(
                in: CGRect(
                    x: rect.midX - radius,
                    y: rect.midY - radius * 0.68,
                    width: radius * 2,
                    height: radius * 1.36
                )
            )
        }
    }
}

extension UIColor {
    func mixed(with other: UIColor, amount: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = max(0, min(1, amount))
        return UIColor(
            red: r1 + (r2 - r1) * t,
            green: g1 + (g2 - g1) * t,
            blue: b1 + (b2 - b1) * t,
            alpha: a1 + (a2 - a1) * t
        )
    }
}
