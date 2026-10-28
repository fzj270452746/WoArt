import UIKit

final class SpeciesDetailViewController: BaseViewController {
    private let species: WoodSpecies
    private let topBar = DetailTopBar()
    private let contentStack = UIStackView()
    private let compareCard = CardView(radius: 26)
    private let compareStack = UIStackView()
    private let compareButton = PillButton(title: "Choose a wood to compare", style: .light, height: 46)
    private var compared: WoodSpecies?

    override var hidesDock: Bool { true }

    init(species: WoodSpecies) {
        self.species = species
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackBar(topBar)

        let hero = SpeciesSwatchView(color: UIColor(hex: species.swatch), seed: species.id)
        hero.layer.cornerRadius = 32
        hero.layer.cornerCurve = .continuous
        hero.clipsToBounds = true
        hero.translatesAutoresizingMaskIntoConstraints = false
        hero.heightAnchor.constraint(equalToConstant: 190).isActive = true

        let eyebrow = EyebrowLabel("Species file", color: Palette.terracotta)
        let name = UILabel()
        name.text = species.name
        name.font = Typeface.display(37, weight: .bold)
        name.textColor = Palette.ink
        name.numberOfLines = 0

        let botanical = UILabel()
        botanical.text = species.botanical
        botanical.font = Typeface.body(12, weight: .medium)
        botanical.textColor = Palette.inkFaint

        let character = UILabel()
        character.text = species.character
        character.font = Typeface.body(15)
        character.textColor = Palette.inkSoft
        character.numberOfLines = 0
        character.setLineHeight(5)

        let metricsCard = ToolSectionCard(title: "How it behaves")

        let jankaBar = MetricBarView(
            title: "Janka hardness",
            value: "\(formatted(species.janka)) N",
            fraction: Double(species.janka) / 3500,
            tint: Palette.brass
        )
        let densityBar = MetricBarView(
            title: "Density",
            value: "\(species.density) kg/m³",
            fraction: Double(species.density) / 1300,
            tint: Palette.teal
        )
        let movementBar = MetricBarView(
            title: "Tangential movement",
            value: String(format: "%.1f%%", species.tangential),
            fraction: species.tangential / 12,
            tint: Palette.terracotta
        )
        let radialBar = MetricBarView(
            title: "Radial movement",
            value: String(format: "%.1f%%", species.radial),
            fraction: species.radial / 8,
            tint: Palette.clay
        )
        let workBar = MetricBarView(
            title: "Workability",
            value: "\(species.workability) / 5",
            fraction: Double(species.workability) / 5,
            tint: Palette.moss
        )
        let stableBar = MetricBarView(
            title: "Stability in service",
            value: "\(species.stability) / 5",
            fraction: Double(species.stability) / 5,
            tint: Palette.inkSoft
        )
        metricsCard.add(jankaBar)
        metricsCard.add(densityBar)
        metricsCard.add(movementBar)
        metricsCard.add(radialBar)
        metricsCard.add(workBar)
        metricsCard.add(stableBar)

        let tagRow = UIStackView()
        tagRow.axis = .horizontal
        tagRow.spacing = 7
        for (index, use) in species.uses.enumerated() {
            tagRow.addArrangedSubview(TagChip(text: use, index: index))
        }
        tagRow.addArrangedSubview(UIView())

        let usesCard = ToolSectionCard(title: "Where it belongs", subtitle: "Typical uses for this species.")
        usesCard.add(tagRow)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.addArrangedSubview(hero)
        contentStack.addArrangedSubview(eyebrow)
        contentStack.addArrangedSubview(name)
        contentStack.addArrangedSubview(botanical)
        contentStack.addArrangedSubview(character)
        contentStack.addArrangedSubview(metricsCard)
        contentStack.addArrangedSubview(usesCard)
        contentStack.addArrangedSubview(compareCard)
        contentStack.setCustomSpacing(7, after: hero)
        contentStack.setCustomSpacing(8, after: eyebrow)
        contentStack.setCustomSpacing(2, after: name)
        contentStack.setCustomSpacing(16, after: botanical)
        contentStack.setCustomSpacing(22, after: character)
        contentStack.setCustomSpacing(26, after: usesCard)

        buildCompareCard()

        addSection(
            ToolNoteView(
                text: "Figures are typical values for seasoned wood. Real boards vary; treat these as a starting point and test your own stock."
            )
        )

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.addSubview(contentStack)
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
    }

    private func addSection(_ view: UIView) {
        contentStack.addArrangedSubview(view)
    }

    private func buildCompareCard() {
        compareStack.axis = .vertical
        compareStack.spacing = 14
        compareStack.translatesAutoresizingMaskIntoConstraints = false
        compareCard.addSubview(compareStack)
        compareStack.pinEdges(to: compareCard, insets: UIEdgeInsets(top: 20, left: 18, bottom: 20, right: 18))

        let title = UILabel()
        title.text = "Compare two woods"
        title.font = Typeface.display(20, weight: .semibold)
        title.textColor = Palette.ink
        compareStack.addArrangedSubview(title)

        let subtitle = UILabel()
        subtitle.text = "Put hardness, movement and workability side by side before you commit."
        subtitle.font = Typeface.body(12.5)
        subtitle.textColor = Palette.inkSoft
        subtitle.numberOfLines = 0
        compareStack.addArrangedSubview(subtitle)
        compareStack.setCustomSpacing(6, after: title)

        compareButton.addTarget(self, action: #selector(compareTapped), for: .touchUpInside)
        compareStack.addArrangedSubview(compareButton)
    }

    private func rebuildComparison() {
        // Keep the title, subtitle and button; remove anything below.
        while compareStack.arrangedSubviews.count > 3 {
            let view = compareStack.arrangedSubviews.last!
            compareStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        guard let other = compared else { return }

        compareButton.setTitle("Change comparison", for: .normal)

        let columns = UIStackView(axis: .horizontal, spacing: 8, distribution: .fillEqually)
        columns.addArrangedSubview(SpeciesCompareColumn(species: species, tint: Palette.terracotta))
        columns.addArrangedSubview(SpeciesCompareColumn(species: other, tint: Palette.moss))
        compareStack.addArrangedSubview(columns)
        compareStack.setCustomSpacing(16, after: compareButton)

        let clear = UIButton(type: .system)
        clear.setTitle("Clear comparison", for: .normal)
        clear.setTitleColor(Palette.inkFaint, for: .normal)
        clear.titleLabel?.font = Typeface.chip(12, weight: .semibold)
        clear.addAction(UIAction { [weak self] _ in
            self?.compared = nil
            self?.rebuildComparison()
        }, for: .touchUpInside)
        compareStack.addArrangedSubview(clear)
    }

    @objc private func compareTapped() {
        let items = ToolData.species
            .filter { $0.id != species.id }
            .map { SelectionSheetViewController.Item(title: $0.name, subtitle: $0.botanical) }
        let candidates = ToolData.species.filter { $0.id != species.id }
        SelectionSheetViewController.present(from: self, title: "Compare with", items: items) { [weak self] index in
            guard let self, index < candidates.count else { return }
            self.compared = candidates[index]
            self.rebuildComparison()
            Haptics.tap()
        }
    }

    private func formatted(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

private final class SpeciesCompareColumn: UIView {
    init(species: WoodSpecies, tint: UIColor) {
        super.init(frame: .zero)

        let name = UILabel()
        name.text = species.name
        name.font = Typeface.display(15, weight: .semibold)
        name.textColor = Palette.ink
        name.numberOfLines = 2

        let botanical = UILabel()
        botanical.text = species.botanical
        botanical.font = Typeface.body(9.5)
        botanical.textColor = Palette.inkFaint
        botanical.numberOfLines = 1

        let stack = UIStackView(axis: .vertical, spacing: 8, views: [name, botanical])
        stack.setCustomSpacing(3, after: name)

        let metrics: [(String, String, Double)] = [
            ("Janka", "\(species.janka) N", Double(species.janka) / 3500),
            ("Density", "\(species.density)", Double(species.density) / 1300),
            ("Move T", String(format: "%.1f%%", species.tangential), species.tangential / 12),
            ("Move R", String(format: "%.1f%%", species.radial), species.radial / 8),
            ("Work", "\(species.workability) / 5", Double(species.workability) / 5),
            ("Stable", "\(species.stability) / 5", Double(species.stability) / 5)
        ]

        for metric in metrics {
            let label = UILabel()
            label.text = metric.0.uppercased()
            label.font = Typeface.eyebrow(8)
            label.textColor = Palette.inkFaint

            let value = UILabel()
            value.text = metric.1
            value.font = Typeface.chip(11, weight: .semibold)
            value.textColor = Palette.ink
            value.textAlignment = .right

            let row = UIStackView(axis: .horizontal, spacing: 6, views: [label, value])
            stack.addArrangedSubview(row)
            stack.setCustomSpacing(4, after: row)

            let bar = MetricBarView(
                title: "",
                value: "",
                fraction: metric.2,
                tint: tint
            )
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.heightAnchor.constraint(equalToConstant: 14).isActive = true
            stack.addArrangedSubview(bar)
            stack.setCustomSpacing(9, after: bar)
        }

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
