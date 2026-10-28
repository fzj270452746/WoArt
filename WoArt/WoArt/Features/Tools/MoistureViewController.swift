import UIKit

final class MoistureViewController: ToolPageViewController {
    private var species: WoodSpecies = ToolData.species[0]
    private let speciesDot = UIView()
    private let speciesName = UILabel()
    private let speciesDetail = UILabel()
    private let width = NumberFieldRow(title: "Board width", unit: "mm")
    private let currentMC = NumberFieldRow(title: "Current moisture", unit: "%")
    private let targetMC = NumberFieldRow(title: "Target moisture", unit: "%")
    private let orientation = ChoicePillRow(options: ["Flat-sawn", "Quarter-sawn"], selected: 0)
    private let unitControl = UISegmentedControl(items: ["mm", "in"])
    private let result = ToolResultCard()
    private var usesInches = false

    init() {
        super.init(
            eyebrow: "Workshop tool 03",
            title: "Wood moves.\nPlan for it.",
            intro: "A wide board can change size more than you expect between the yard and the living room. Work out how much before the glue-up.",
            formula: "Δ width = width × (shrink % ÷ 28) × Δ MC"
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        width.setValue("300")
        currentMC.setValue("20")
        targetMC.setValue("8")

        addSection(makeSpeciesCard())

        let inputs = ToolSectionCard(
            title: "The board",
            subtitle: "Use the moisture reading from your meter, not the sticker on the pile."
        )
        let unitRow = UIStackView(axis: .horizontal, spacing: 12, alignment: .center, views: [])
        unitControl.selectedSegmentIndex = 0
        unitControl.selectedSegmentTintColor = Palette.ink
        unitControl.backgroundColor = Palette.cream
        unitControl.setTitleTextAttributes(
            [.font: Typeface.chip(11, weight: .semibold), .foregroundColor: Palette.inkSoft],
            for: .normal
        )
        unitControl.setTitleTextAttributes(
            [.font: Typeface.chip(11, weight: .semibold), .foregroundColor: Palette.paper],
            for: .selected
        )
        unitControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)
        unitControl.translatesAutoresizingMaskIntoConstraints = false
        unitControl.heightAnchor.constraint(equalToConstant: 32).isActive = true
        unitControl.widthAnchor.constraint(equalToConstant: 108).isActive = true
        unitRow.addArrangedSubview(width)
        unitRow.addArrangedSubview(unitControl)
        unitRow.alignment = .bottom

        let mcRow = UIStackView(axis: .horizontal, spacing: 18, distribution: .fillEqually, views: [currentMC, targetMC])
        inputs.add(unitRow)
        inputs.add(mcRow, spacing: 18)
        inputs.add(orientation, spacing: 18)
        addSection(inputs)

        result.valueLabel.text = "0"
        result.unitLabel.text = "mm"
        addSection(result)

        let emcCard = ToolSectionCard(
            title: "In the room",
            subtitle: "Approximate equilibrium moisture content at 20°C, for a board left to settle."
        )
        for humidity in [30, 50, 70] {
            emcCard.add(makeEMCRow(humidity: humidity))
        }
        addSection(emcCard)

        addSection(
            ToolNoteView(
                text: "Let stock acclimatise in the room where the piece will live for at least a week. A 12% board brought into a dry winter room will keep shrinking after you cut it."
            )
        )

        [width, currentMC, targetMC].forEach {
            $0.onChange = { [weak self] in self?.recompute() }
        }
        orientation.onChange = { [weak self] _ in self?.recompute() }

        recompute()
    }

    private func makeSpeciesCard() -> UIView {
        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 22
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.ink.withAlphaComponent(0.06).cgColor

        speciesDot.layer.cornerRadius = 19
        speciesDot.backgroundColor = UIColor(hex: species.swatch)
        speciesDot.translatesAutoresizingMaskIntoConstraints = false
        speciesDot.widthAnchor.constraint(equalToConstant: 38).isActive = true
        speciesDot.heightAnchor.constraint(equalToConstant: 38).isActive = true

        speciesName.font = Typeface.display(17, weight: .semibold)
        speciesName.textColor = Palette.ink
        speciesDetail.font = Typeface.body(10)
        speciesDetail.textColor = Palette.inkFaint
        let identity = UIStackView(axis: .vertical, spacing: 1, views: [speciesName, speciesDetail])

        let change = UILabel()
        change.text = "CHANGE"
        change.font = Typeface.eyebrow(8.5)
        change.textColor = Palette.terracotta

        card.addSubviews(speciesDot, identity, change)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 68),
            speciesDot.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            speciesDot.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            identity.leadingAnchor.constraint(equalTo: speciesDot.trailingAnchor, constant: 12),
            identity.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            identity.trailingAnchor.constraint(lessThanOrEqualTo: change.leadingAnchor, constant: -10),
            change.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            change.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(speciesTapped)))
        card.isUserInteractionEnabled = true
        updateSpeciesLabels()
        return card
    }

    private func updateSpeciesLabels() {
        speciesName.text = species.name
        speciesDetail.text = "T \(String(format: "%.1f", species.tangential))% · R \(String(format: "%.1f", species.radial))% total"
        speciesDot.backgroundColor = UIColor(hex: species.swatch)
    }

    private func makeEMCRow(humidity: Int) -> UIView {
        let mc = BenchMath.equilibriumMC(relativeHumidity: Double(humidity), temperatureC: 20)
        let title = UILabel()
        title.text = "\(humidity)% relative humidity"
        title.font = Typeface.body(12.5, weight: .medium)
        title.textColor = Palette.inkSoft

        let value = UILabel()
        value.text = String(format: "%.1f%% MC", mc)
        value.font = Typeface.chip(12, weight: .semibold)
        value.textColor = Palette.ink
        value.textAlignment = .right

        return UIStackView(axis: .horizontal, spacing: 12, views: [title, value])
    }

    @objc private func speciesTapped() {
        let items = ToolData.species.map { SelectionSheetViewController.Item(title: $0.name, subtitle: $0.botanical) }
        let list = ToolData.species
        SelectionSheetViewController.present(from: self, title: "Species", items: items) { [weak self] index in
            guard let self, index < list.count else { return }
            self.species = list[index]
            self.updateSpeciesLabels()
            self.recompute()
            Haptics.tap()
        }
    }

    @objc private func unitChanged() {
        let useInches = unitControl.selectedSegmentIndex == 1
        guard useInches != usesInches else { return }
        usesInches = useInches
        width.setValue(String(format: "%.2f", (width.value ?? 0) / 25.4))
        width.setUnit(usesInches ? "in" : "mm")
        recompute()
    }

    private func recompute() {
        let widthValue = width.value ?? 0
        let current = currentMC.value ?? 0
        let target = targetMC.value ?? 0
        let quarterSawn = orientation.control.selectedSegmentIndex == 1
        let physicalWidth = usesInches ? widthValue * 25.4 : widthValue
        let changeMM = BenchMath.movement(
            width: physicalWidth,
            currentMC: current,
            targetMC: target,
            species: species,
            quarterSawn: quarterSawn
        )
        let change = usesInches ? changeMM / 25.4 : changeMM
        let percent = physicalWidth > 0 ? abs(changeMM) / physicalWidth * 100 : 0
        let newWidth = physicalWidth - changeMM
        let newWidthDisplay = usesInches ? newWidth / 25.4 : newWidth

        result.valueLabel.text = String(format: "%.1f", abs(change))
        result.unitLabel.text = usesInches ? "inches" : "mm"
        let direction = abs(changeMM) < 0.05
            ? "No meaningful change"
            : (changeMM > 0 ? "The board shrinks" : "The board grows")
        result.setDetail(rows: [
            ("Direction", direction),
            ("Movement", String(format: "%.2f%%", percent)),
            ("Finished width", String(format: "%.1f %@", newWidthDisplay, usesInches ? "in" : "mm")),
            ("Grain", quarterSawn ? "Quarter-sawn" : "Flat-sawn")
        ])
    }
}
