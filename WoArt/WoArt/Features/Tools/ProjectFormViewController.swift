import UIKit

final class ProjectFormViewController: BenchFormViewController {
    var onCreated: ((BenchProject) -> Void)?

    private let nameField = InputFieldView(
        title: "Project name",
        placeholder: "e.g. Walnut side table"
    )
    private let speciesRow: BenchSpeciesRow
    private let unitControl: UISegmentedControl
    private let templateScroller = UIScrollView()
    private let templateStack = UIStackView()
    private let selectionNote = UILabel()
    private var templateCards: [ProjectTemplateCard] = []
    private var selectedTemplate: BenchTemplate
    private var selectedSpecies: WoodSpecies

    init(templateID: String? = nil) {
        let template: BenchTemplate
        if let templateID, let found = BenchTemplates.template(id: templateID) {
            template = found
        } else {
            // Start with a real piece on the bench; everything is editable.
            template = BenchTemplates.sideTable
        }
        let species = ToolData.species(withID: template.speciesID) ?? ToolData.species[0]
        selectedTemplate = template
        selectedSpecies = species
        speciesRow = BenchSpeciesRow(species: species)
        unitControl = BenchUI.segmented(
            items: ["Millimetres", "Inches"],
            selected: BenchStore.shared.defaultUnit == .metric ? 0 : 1
        )
        super.init(
            eyebrow: "New project",
            title: "Set up the work.",
            subtitle: "Pick a starting point, name the piece and choose the wood. Every part, board and step can be changed later.",
            saveTitle: "Start project"
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildFields() {
        let templateLabel = EyebrowLabel("Start from", color: Palette.inkFaint, size: 8.5)
        contentStack.addArrangedSubview(templateLabel)
        contentStack.setCustomSpacing(8, after: templateLabel)

        templateScroller.showsHorizontalScrollIndicator = false
        templateScroller.clipsToBounds = true
        templateStack.axis = .horizontal
        templateStack.alignment = .top
        templateStack.spacing = 10
        templateScroller.addSubview(templateStack)
        templateScroller.translatesAutoresizingMaskIntoConstraints = false
        templateStack.translatesAutoresizingMaskIntoConstraints = false

        for template in BenchTemplates.all {
            let card = ProjectTemplateCard(template: template)
            card.onSelect = { [weak self] in
                self?.select(template: template)
            }
            templateCards.append(card)
            templateStack.addArrangedSubview(card)
        }

        templateScroller.heightAnchor.constraint(equalToConstant: 120).isActive = true
        NSLayoutConstraint.activate([
            templateStack.topAnchor.constraint(equalTo: templateScroller.contentLayoutGuide.topAnchor),
            templateStack.bottomAnchor.constraint(equalTo: templateScroller.contentLayoutGuide.bottomAnchor),
            templateStack.leadingAnchor.constraint(equalTo: templateScroller.contentLayoutGuide.leadingAnchor),
            templateStack.trailingAnchor.constraint(equalTo: templateScroller.contentLayoutGuide.trailingAnchor),
            templateStack.heightAnchor.constraint(equalTo: templateScroller.frameLayoutGuide.heightAnchor)
        ])
        contentStack.addArrangedSubview(templateScroller)
        contentStack.setCustomSpacing(3, after: templateScroller)

        selectionNote.font = Typeface.body(10.5)
        selectionNote.textColor = Palette.inkFaint
        selectionNote.numberOfLines = 0
        contentStack.addArrangedSubview(selectionNote)
        contentStack.setCustomSpacing(20, after: selectionNote)

        contentStack.addArrangedSubview(nameField)

        let speciesLabel = EyebrowLabel("Species", color: Palette.inkFaint, size: 8.5)
        contentStack.addArrangedSubview(speciesLabel)
        contentStack.setCustomSpacing(8, after: speciesLabel)

        speciesRow.onTap = { [weak self] in self?.chooseSpecies() }
        contentStack.addArrangedSubview(speciesRow)

        contentStack.addArrangedSubview(BenchUI.labeled("Units", unitControl))

        contentStack.addArrangedSubview(
            ToolNoteView(
                text: "The template fills in a starter parts list, a matching stock board and a build order. Nothing is locked — every part, board and step is yours to change."
            )
        )

        updateSelectionUI()
        if selectedTemplate.id != BenchTemplates.blank.id {
            nameField.textField.text = selectedTemplate.defaultTitle
        }
    }

    private func select(template: BenchTemplate) {
        Haptics.tap()
        let previousTitle = selectedTemplate.defaultTitle
        let current = nameField.text.trimmed
        let shouldReplaceTitle = current.isEmpty
            || current == previousTitle
            || current == "Untitled project"

        selectedTemplate = template
        if shouldReplaceTitle {
            nameField.textField.text = template.id == BenchTemplates.blank.id ? "" : template.defaultTitle
        }

        if let species = ToolData.species(withID: template.speciesID) {
            selectedSpecies = species
            speciesRow.update(species: species)
        }

        updateSelectionUI()
    }

    private func updateSelectionUI() {
        for card in templateCards {
            card.setChosen(card.template.id == selectedTemplate.id)
        }
        if selectedTemplate.parts.isEmpty {
            selectionNote.text = "A blank bench: add your own parts, stock and steps."
        } else {
            let pieces = selectedTemplate.parts.reduce(0) { $0 + $1.quantity }
            selectionNote.text = "\(selectedTemplate.name): \(pieces) pieces, \(selectedTemplate.steps.count) build steps, \(selectedTemplate.stock.count) stock types."
        }
    }

    private func chooseSpecies() {
        let list = ToolData.species
        let items = list.map {
            SelectionSheetViewController.Item(title: $0.name, subtitle: $0.botanical)
        }
        SelectionSheetViewController.present(from: self, title: "Species", items: items) { [weak self] index in
            guard let self, index < list.count else { return }
            self.selectedSpecies = list[index]
            self.speciesRow.update(species: list[index])
            Haptics.tap()
        }
    }

    override func saveTapped() {
        let unit: BenchUnit = unitControl.selectedSegmentIndex == 1 ? .imperial : .metric
        let project = BenchStore.shared.createProject(
            title: nameField.text,
            speciesID: selectedSpecies.id,
            template: selectedTemplate,
            unit: unit
        )
        Haptics.success()
        dismiss(animated: true) { [weak self] in
            self?.onCreated?(project)
        }
    }
}

private final class ProjectTemplateCard: UIControl {
    let template: BenchTemplate
    var onSelect: (() -> Void)?

    private let check = UIView()
    private let checkIcon = UIImageView()

    init(template: BenchTemplate) {
        self.template = template
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 138).isActive = true
        heightAnchor.constraint(equalToConstant: 116).isActive = true

        backgroundColor = Palette.card
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.ink.withAlphaComponent(0.07).cgColor

        let iconCircle = UIView()
        iconCircle.backgroundColor = Palette.cream
        iconCircle.layer.cornerRadius = 15
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.widthAnchor.constraint(equalToConstant: 30).isActive = true
        iconCircle.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let icon = UIImageView(
            image: UIImage(
                systemName: template.symbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            )
        )
        icon.tintColor = Palette.inkSoft
        iconCircle.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor)
        ])

        let name = UILabel()
        name.text = template.name
        name.font = Typeface.display(15.5, weight: .semibold)
        name.textColor = Palette.ink
        name.numberOfLines = 1
        name.adjustsFontSizeToFitWidth = true
        name.minimumScaleFactor = 0.8

        let blurb = UILabel()
        blurb.text = template.blurb
        blurb.font = Typeface.body(9.5)
        blurb.textColor = Palette.inkFaint
        blurb.numberOfLines = 3

        check.backgroundColor = Palette.terracotta
        check.layer.cornerRadius = 8
        check.translatesAutoresizingMaskIntoConstraints = false
        check.isHidden = true
        checkIcon.image = UIImage(
            systemName: "checkmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
        )
        checkIcon.tintColor = .white
        check.addSubview(checkIcon)
        checkIcon.translatesAutoresizingMaskIntoConstraints = false

        iconCircle.isUserInteractionEnabled = false
        addSubviews(iconCircle, name, blurb, check)
        NSLayoutConstraint.activate([
            iconCircle.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            iconCircle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),

            check.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            check.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            check.widthAnchor.constraint(equalToConstant: 16),
            check.heightAnchor.constraint(equalToConstant: 16),
            checkIcon.centerXAnchor.constraint(equalTo: check.centerXAnchor),
            checkIcon.centerYAnchor.constraint(equalTo: check.centerYAnchor),

            name.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            name.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            name.topAnchor.constraint(equalTo: iconCircle.bottomAnchor, constant: 9),

            blurb.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            blurb.trailingAnchor.constraint(equalTo: name.trailingAnchor),
            blurb.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 2),
            blurb.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setChosen(_ chosen: Bool) {
        check.isHidden = !chosen
        layer.borderWidth = chosen ? 1.6 : 1
        layer.borderColor = (chosen
            ? Palette.terracotta.withAlphaComponent(0.7)
            : Palette.ink.withAlphaComponent(0.07)).cgColor
        backgroundColor = chosen ? Palette.card : Palette.card.withAlphaComponent(0.7)
    }

    @objc private func tapped() {
        onSelect?()
    }
}
