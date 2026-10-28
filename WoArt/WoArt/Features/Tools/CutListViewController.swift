import UIKit

/// A standalone cut planner for one-off jobs. It runs the same stock-aware
/// engine as a project's Cuts tab, and can turn the draft into a real project.
final class CutListViewController: ToolPageViewController {
    private let store = BenchStore.shared
    private var draft: BenchProject
    private let dynamicStack = UIStackView()
    private let unitControl: UISegmentedControl
    private var outputsStack: UIStackView?

    init() {
        let species = BenchStore.shared.activeProject?.speciesID ?? "white_oak"
        let unit = BenchStore.shared.defaultUnit
        draft = BenchProject(
            title: "Quick cut",
            speciesID: species,
            unit: unit,
            parts: [
                ProjectPart(
                    name: "Rails",
                    lengthMM: 600,
                    widthMM: 90,
                    thicknessMM: 25,
                    quantity: 4,
                    material: .solid,
                    grain: .alongLength
                ),
                ProjectPart(
                    name: "Cross rails",
                    lengthMM: 450,
                    widthMM: 90,
                    thicknessMM: 25,
                    quantity: 2,
                    material: .solid,
                    grain: .alongLength
                ),
                ProjectPart(
                    name: "Cleats",
                    lengthMM: 300,
                    widthMM: 60,
                    thicknessMM: 25,
                    quantity: 3,
                    material: .solid,
                    grain: .alongLength
                )
            ],
            stock: [
                StockBoard(
                    label: "Board stock",
                    material: .solid,
                    thicknessMM: 25,
                    widthMM: 200,
                    lengthMM: 2400,
                    quantity: 1,
                    pricePerBoardFoot: 0
                )
            ],
            kerfMM: 3,
            trimMM: 10
        )
        unitControl = BenchUI.segmented(
            items: ["mm", "in"],
            selected: unit == .metric ? 0 : 1
        )
        super.init(
            eyebrow: "Workshop tool 06",
            title: "Plan a cut.\nSave it later.",
            intro: "A handful of parts and a board from the rack. The planner handles the kerf, the end trim and the yield; save it as a project when the cut becomes a build.",
            formula: "usable = stock − (2 × trim) · every cut costs one kerf"
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        unitControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)
        unitControl.widthAnchor.constraint(equalToConstant: 112).isActive = true

        dynamicStack.axis = .vertical
        dynamicStack.spacing = 14
        addSection(dynamicStack)
        rebuild()
    }

    // MARK: - Rebuild

    private func rebuild() {
        dynamicStack.arrangedSubviews.forEach { view in
            dynamicStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        outputsStack = nil

        let unitRow = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, views: [])
        let unitLabel = EyebrowLabel("Units", color: Palette.inkFaint, size: 8.5)
        unitRow.addArrangedSubview(unitLabel)
        unitRow.addArrangedSubview(UIView())
        unitRow.addArrangedSubview(unitControl)
        dynamicStack.addArrangedSubview(unitRow)
        dynamicStack.setCustomSpacing(2, after: unitRow)

        let parts = DetailPanel(
            title: "Parts",
            info: BenchFormat.count(draft.partCount, "piece"),
            subtitle: "Finished sizes. Tap a part to change its dimensions, quantity or grain."
        )
        let partRows = UIStackView(axis: .vertical, spacing: 0)
        if draft.parts.isEmpty {
            partRows.addArrangedSubview(emptyLabel("No parts yet. Add the first length to cut."))
        } else {
            for (index, part) in draft.parts.enumerated() {
                let row = PartRow(part: part, project: draft, colorIndex: index)
                row.onOpen = { [weak self] in self?.editPart(id: part.id) }
                partRows.addArrangedSubview(row)
                if index < draft.parts.count - 1 {
                    partRows.addArrangedSubview(DividerLine())
                }
            }
        }
        parts.add(partRows)
        parts.add(DetailAddRow(title: "Add a part") { [weak self] in self?.addPart() }, spacing: 6)
        dynamicStack.addArrangedSubview(parts)

        let stock = DetailPanel(
            title: "Stock",
            info: BenchFormat.count(draft.stock.count, "type"),
            subtitle: "The board you have, or the board you are about to buy."
        )
        let stockRows = UIStackView(axis: .vertical, spacing: 0)
        if draft.stock.isEmpty {
            stockRows.addArrangedSubview(emptyLabel("No stock yet. Add the board you plan to cut."))
        } else {
            for (index, board) in draft.stock.enumerated() {
                let row = StockRow(stock: board, project: draft)
                row.onOpen = { [weak self] in self?.editStock(id: board.id) }
                stockRows.addArrangedSubview(row)
                if index < draft.stock.count - 1 {
                    stockRows.addArrangedSubview(DividerLine())
                }
            }
        }
        stock.add(stockRows)
        stock.add(DetailAddRow(title: "Add stock") { [weak self] in self?.addStock() }, spacing: 6)
        dynamicStack.addArrangedSubview(stock)

        let settings = DetailPanel(
            title: "Cut settings",
            subtitle: "Match the kerf to the blade and the trim to how much you square off each end."
        )
        let kerf = BenchStepperRow(
            title: "Blade kerf",
            subtitle: "The width of the saw cut.",
            value: draft.kerfMM,
            minimum: 1,
            maximum: 8,
            step: 0.5
        )
        kerf.onChange = { [weak self] value in self?.updateSettings(kerf: value, trim: nil) }
        settings.add(kerf, spacing: 8)
        settings.add(DividerLine(), spacing: 10)
        let trim = BenchStepperRow(
            title: "End trim",
            subtitle: "Removed from both ends of every board.",
            value: draft.trimMM,
            minimum: 0,
            maximum: 40,
            step: 2
        )
        trim.onChange = { [weak self] value in self?.updateSettings(kerf: nil, trim: value) }
        settings.add(trim, spacing: 10)
        dynamicStack.addArrangedSubview(settings)

        let outputs = UIStackView(axis: .vertical, spacing: 14)
        outputsStack = outputs
        dynamicStack.addArrangedSubview(outputs)

        let save = PillButton(title: "Save as a project", style: .dark, icon: "square.and.arrow.down", height: 52)
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        dynamicStack.addArrangedSubview(save)
        dynamicStack.setCustomSpacing(6, after: save)

        let saveNote = UILabel()
        saveNote.text = "Saves these parts and boards to The Bench, where you can add a species, movement allowances and build steps."
        saveNote.font = Typeface.body(10.5)
        saveNote.textColor = Palette.inkFaint
        saveNote.numberOfLines = 0
        saveNote.setLineHeight(3)
        dynamicStack.addArrangedSubview(saveNote)

        refreshOutputs()
    }

    private func emptyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = Typeface.body(12)
        label.textColor = Palette.inkFaint
        label.numberOfLines = 0
        label.setLineHeight(3)
        return label
    }

    private func refreshOutputs() {
        guard let outputs = outputsStack else { return }
        outputs.arrangedSubviews.forEach { view in
            outputs.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let plan = BenchEngine.plan(project: draft)
        let placedCount = plan.boards.flatMap { $0.strips }.flatMap { $0.parts }.count

        let result = ToolResultCard()
        result.valueLabel.text = "\(plan.boardCount)"
        result.unitLabel.text = plan.boardCount == 1 ? "board" : "boards"
        var rows: [(String, String)] = [
            ("Yield", plan.plannedBoardFeet > 0 ? BenchFormat.percent(plan.yield) : "—"),
            ("Parts placed", "\(placedCount)"),
            ("Stock needed", BenchFormat.boardFeetText(plan.plannedBoardFeet)),
            ("Net parts", BenchFormat.boardFeetText(plan.placedBoardFeet))
        ]
        if let cost = plan.costToBuy, cost > 0 {
            rows.append(("Lumber to buy", BenchFormat.money(cost)))
        }
        if let value = plan.stockValue, value > 0 {
            rows.append(("Stock value", BenchFormat.money(value)))
        }
        if plan.boardCount == 0 {
            rows.append(("Next", "Add parts and stock"))
        }
        result.setDetail(rows: rows)
        outputs.addArrangedSubview(result)

        if !plan.unplaced.isEmpty {
            outputs.addArrangedSubview(BenchUnplacedCard(plan: plan))
        }

        if draft.parts.contains(where: { $0.grain == .acrossWidth && $0.material == .solid }) {
            outputs.addArrangedSubview(
                ToolNoteView(
                    text: "Parts set across the grain are turned 90° on the board in the cut diagram. Check the grain direction before the first rip."
                )
            )
        }

        if !plan.summaries.isEmpty {
            let shopping = DetailPanel(
                title: "Shopping list",
                subtitle: "What the plan needs against the boards on hand."
            )
            let shoppingRows = UIStackView(axis: .vertical, spacing: 0)
            for (index, summary) in plan.summaries.enumerated() {
                shoppingRows.addArrangedSubview(ShoppingRow(summary: summary, project: draft))
                if index < plan.summaries.count - 1 {
                    shoppingRows.addArrangedSubview(DividerLine())
                }
            }
            shopping.add(shoppingRows)
            outputs.addArrangedSubview(shopping)
        }

        let sequence = DetailPanel(
            title: "Cut sequence",
            subtitle: plan.boards.isEmpty
                ? "Add parts and stock and the boards will be laid out here."
                : "Each board is ripped into strips, then cross-cut. Kerf and end trim are included."
        )
        if plan.boards.isEmpty {
            sequence.add(emptyLabel("No boards in the plan yet."))
        } else {
            let boardsStack = UIStackView(axis: .vertical, spacing: 12)
            for (index, board) in plan.boards.enumerated() {
                if index > 0 { boardsStack.addArrangedSubview(DividerLine()) }
                boardsStack.addArrangedSubview(BenchBoardView(board: board, index: index, project: draft))
            }
            sequence.add(boardsStack)
        }
        outputs.addArrangedSubview(sequence)

        outputs.addArrangedSubview(
            ToolNoteView(
                text: "The plan is a starting point, not a promise. Check every board for knots and checks before committing a cut, and always cut the longest part first."
            )
        )

        if draft.parts.isEmpty || draft.stock.isEmpty {
            let hint = ToolNoteView(
                text: "Add at least one part and one board to see a cut sequence. This quick plan is not saved until you press Save as a project."
            )
            outputs.addArrangedSubview(hint)
        }
    }

    // MARK: - Edits

    private func updateSettings(kerf: Double?, trim: Double?) {
        if let kerf { draft.kerfMM = kerf }
        if let trim { draft.trimMM = trim }
        refreshOutputs()
    }

    @objc private func unitChanged() {
        let newUnit: BenchUnit = unitControl.selectedSegmentIndex == 0 ? .metric : .imperial
        guard newUnit != draft.unit else { return }
        draft.unit = newUnit
        rebuild()
    }

    private func addPart() {
        let part = ProjectPart(
            name: "New part",
            lengthMM: 300,
            widthMM: 100,
            thicknessMM: 25,
            quantity: 1,
            material: .solid,
            grain: .alongLength
        )
        let form = PartFormViewController(project: draft, part: part, isNew: true)
        form.onSaved = { [weak self] saved in
            self?.draft.parts.append(saved)
            self?.rebuild()
            self?.showToast("Part added", icon: "checkmark")
        }
        presentForm(form)
    }

    private func editPart(id: String) {
        guard let index = draft.parts.firstIndex(where: { $0.id == id }) else { return }
        let form = PartFormViewController(project: draft, part: draft.parts[index], isNew: false)
        form.onSaved = { [weak self] saved in
            guard let self, let index = self.draft.parts.firstIndex(where: { $0.id == saved.id }) else { return }
            self.draft.parts[index] = saved
            self.rebuild()
            self.showToast("Part updated", icon: "checkmark")
        }
        form.onDeleted = { [weak self] in
            self?.draft.parts.removeAll { $0.id == id }
            self?.rebuild()
            self?.showToast("Part removed", icon: "trash")
        }
        presentForm(form)
    }

    private func addStock() {
        let stock = StockBoard(
            label: "Board stock",
            material: .solid,
            thicknessMM: 25,
            widthMM: 200,
            lengthMM: 2400,
            quantity: 1,
            pricePerBoardFoot: 0
        )
        let form = StockFormViewController(project: draft, stock: stock, isNew: true)
        form.onSaved = { [weak self] saved in
            self?.draft.stock.append(saved)
            self?.rebuild()
            self?.showToast("Stock added", icon: "checkmark")
        }
        presentForm(form)
    }

    private func editStock(id: String) {
        guard let index = draft.stock.firstIndex(where: { $0.id == id }) else { return }
        let form = StockFormViewController(project: draft, stock: draft.stock[index], isNew: false)
        form.onSaved = { [weak self] saved in
            guard let self, let index = self.draft.stock.firstIndex(where: { $0.id == saved.id }) else { return }
            self.draft.stock[index] = saved
            self.rebuild()
            self.showToast("Stock updated", icon: "checkmark")
        }
        form.onDeleted = { [weak self] in
            self?.draft.stock.removeAll { $0.id == id }
            self?.rebuild()
            self?.showToast("Stock removed", icon: "trash")
        }
        presentForm(form)
    }

    private func presentForm(_ form: UIViewController) {
        view.endEditing(true)
        form.modalPresentationStyle = .pageSheet
        if let sheet = form.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 34
        }
        present(form, animated: true)
    }

    // MARK: - Save

    @objc private func saveTapped() {
        guard !draft.parts.isEmpty, !draft.stock.isEmpty else {
            Haptics.warn()
            showToast("Add a part and a board first.", icon: "exclamationmark")
            return
        }
        Haptics.tap()
        TextPromptSheetViewController.present(
            from: self,
            title: "Save this cut",
            message: "The quick plan becomes a project with the same parts, boards, kerf and trim.",
            fieldTitle: "Project name",
            placeholder: "e.g. Garden bench rails",
            initialText: "Quick cut",
            confirmTitle: "Save project"
        ) { [weak self] title in
            self?.saveProject(named: title)
        }
    }

    private func saveProject(named title: String) {
        let created = store.createProject(
            title: title,
            speciesID: draft.speciesID,
            template: nil,
            unit: draft.unit
        )
        var project = created
        project.parts = draft.parts
        project.stock = draft.stock
        project.kerfMM = draft.kerfMM
        project.trimMM = draft.trimMM
        project.steps = [
            ProjectStep(
                title: "Cut the parts",
                detail: "Work from the longest part to the shortest. Check each board for defects before committing the cut."
            )
        ]
        store.update(project)

        guard let saved = store.project(id: created.id) else { return }
        let detail = ProjectDetailViewController(projectID: saved.id, initialSection: .cuts)
        if let navigation = navigationController, navigation.viewControllers.last === self {
            var stack = navigation.viewControllers
            stack[stack.count - 1] = detail
            navigation.setViewControllers(stack, animated: true)
        } else {
            navigationController?.pushViewController(detail, animated: true)
        }
        ToastCenter.shared.show("Saved to the bench", icon: "checkmark")
    }
}
