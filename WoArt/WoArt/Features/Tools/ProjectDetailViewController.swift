import UIKit

final class ProjectDetailViewController: BaseViewController {
    enum Section: Int, CaseIterable {
        case plan
        case cuts
        case movement
        case steps

        var title: String {
            switch self {
            case .plan: return "Plan"
            case .cuts: return "Cuts"
            case .movement: return "Movement"
            case .steps: return "Steps"
            }
        }
    }

    private let projectID: String
    private let store = BenchStore.shared
    private let topBar = DetailTopBar(trailingSymbol: "ellipsis")
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let speciesLabel = UILabel()
    private let warningLabel = UILabel()
    private let statsContainer = UIView()
    private let segmentBar = UIView()
    private let segmentStack = UIStackView()
    private var segmentButtons: [UIButton] = []
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var currentSection: Section
    private var isSuppressingRefresh = false

    private var notesView: UITextView?
    private var notesPlaceholder: UILabel?

    private var cutsOutputStack: UIStackView?
    private var movementOutputStack: UIStackView?
    private var movementMCSummary: UILabel?

    override var hidesDock: Bool { true }

    private var project: BenchProject? {
        store.project(id: projectID)
    }

    init(projectID: String, initialSection: Section = .plan) {
        self.projectID = projectID
        self.currentSection = initialSection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackBar(topBar)
        topBar.onTrailing = { [weak self] in self?.showProjectMenu() }
        buildHeader()
        buildScroll()
        refresh()
        observeChanges()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveNotes()
    }

    // MARK: - Scaffold

    private func buildHeader() {
        let eyebrow = EyebrowLabel("Project", color: Palette.terracotta, size: 9)

        titleLabel.font = Typeface.display(30, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 2

        speciesLabel.font = Typeface.body(11.5, weight: .medium)
        speciesLabel.textColor = Palette.inkSoft
        speciesLabel.numberOfLines = 1
        speciesLabel.adjustsFontSizeToFitWidth = true
        speciesLabel.minimumScaleFactor = 0.8

        warningLabel.font = Typeface.body(11, weight: .medium)
        warningLabel.textColor = Palette.terracotta
        warningLabel.numberOfLines = 0
        warningLabel.isHidden = true

        headerStack.axis = .vertical
        headerStack.spacing = 6
        headerStack.addArrangedSubview(eyebrow)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(speciesLabel)
        headerStack.addArrangedSubview(warningLabel)
        headerStack.addArrangedSubview(statsContainer)
        headerStack.setCustomSpacing(5, after: eyebrow)
        headerStack.setCustomSpacing(7, after: titleLabel)
        headerStack.setCustomSpacing(8, after: speciesLabel)
        headerStack.setCustomSpacing(10, after: warningLabel)

        view.addSubview(headerStack)
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        segmentBar.backgroundColor = Palette.cream.withAlphaComponent(0.7)
        segmentBar.layer.cornerRadius = 15
        segmentBar.layer.cornerCurve = .continuous
        segmentStack.axis = .horizontal
        segmentStack.spacing = 3
        segmentStack.distribution = .fillEqually
        segmentBar.addSubview(segmentStack)
        segmentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentStack.topAnchor.constraint(equalTo: segmentBar.topAnchor, constant: 3),
            segmentStack.leadingAnchor.constraint(equalTo: segmentBar.leadingAnchor, constant: 3),
            segmentStack.trailingAnchor.constraint(equalTo: segmentBar.trailingAnchor, constant: -3),
            segmentStack.bottomAnchor.constraint(equalTo: segmentBar.bottomAnchor, constant: -3)
        ])

        for section in Section.allCases {
            let button = UIButton(type: .custom)
            button.setTitle(section.title, for: .normal)
            button.titleLabel?.font = Typeface.chip(11.5, weight: .semibold)
            button.layer.cornerRadius = 12
            button.layer.cornerCurve = .continuous
            button.tag = section.rawValue
            button.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
            segmentButtons.append(button)
            segmentStack.addArrangedSubview(button)
        }

        view.addSubview(segmentBar)
        segmentBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentBar.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 14),
            segmentBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            segmentBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            segmentBar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func buildScroll() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 14

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: segmentBar.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 2),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Metrics.gutter),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Metrics.gutter),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Metrics.gutter * 2)
        ])
    }

    private func observeChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataChanged),
            name: .benchDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardChanged(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardHidden),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Refresh

    @objc private func dataChanged() {
        guard !isSuppressingRefresh else { return }
        refresh()
    }

    private func refresh() {
        guard let project else { return }
        refreshHeader(project: project, metrics: BenchEngine.metrics(project: project))
        updateSegments()
        renderCurrentSection()
    }

    private func refreshHeaderOnly() {
        guard let project else { return }
        refreshHeader(project: project, metrics: BenchEngine.metrics(project: project))
    }

    private func refreshHeader(project: BenchProject, metrics: BenchMetrics) {
        titleLabel.text = project.title
        let parts = [
            project.species.name,
            BenchFormat.count(project.partCount, "part"),
            BenchFormat.boardFeetText(metrics.netBoardFeet)
        ]
        speciesLabel.text = parts.joined(separator: "  ·  ")

        warningLabel.isHidden = metrics.unplacedCount == 0
        warningLabel.text = metrics.unplacedCount == 0
            ? nil
            : "\(BenchFormat.count(metrics.unplacedCount, "part")) "
                + (metrics.unplacedCount == 1 ? "has" : "have")
                + " no matching stock. Open Cuts to see why."

        statsContainer.subviews.forEach { $0.removeFromSuperview() }
        let stats = BenchStatStrip(stats: [
            ("\(metrics.partCount)", "Parts"),
            (String(format: "%.1f", metrics.netBoardFeet), "Board ft"),
            ("\(metrics.boardCount)", "Boards"),
            (metrics.stepCount > 0 ? "\(metrics.doneSteps)/\(metrics.stepCount)" : "—", "Steps")
        ])
        statsContainer.addSubview(stats)
        stats.pinEdges(to: statsContainer)
        stats.heightAnchor.constraint(equalToConstant: 58).isActive = true
    }

    private func updateSegments() {
        for (index, button) in segmentButtons.enumerated() {
            let chosen = index == currentSection.rawValue
            button.backgroundColor = chosen ? Palette.ink : .clear
            button.setTitleColor(chosen ? Palette.paper : Palette.inkSoft, for: .normal)
        }
    }

    private func renderCurrentSection() {
        contentStack.arrangedSubviews.forEach { view in
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        notesView = nil
        notesPlaceholder = nil
        cutsOutputStack = nil
        movementOutputStack = nil
        movementMCSummary = nil

        switch currentSection {
        case .plan: renderPlan()
        case .cuts: renderCuts()
        case .movement: renderMovement()
        case .steps: renderSteps()
        }
    }

    @objc private func segmentTapped(_ sender: UIButton) {
        guard
            let section = Section(rawValue: sender.tag),
            section != currentSection
        else { return }
        Haptics.tap()
        if currentSection == .plan { saveNotes() }
        currentSection = section
        updateSegments()
        renderCurrentSection()
        scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.contentInset.top), animated: false)
    }

    // MARK: - Project menu

    private func showProjectMenu() {
        guard let project else { return }
        let unitTitle = project.unit == .metric ? "Switch to inches" : "Switch to millimetres"
        ActionSheetViewController.present(
            from: self,
            title: project.title,
            options: [
                .init(title: "Rename project", symbol: "pencil", destructive: false) { [weak self] in
                    self?.renameProject()
                },
                .init(title: "Change species", symbol: "leaf", destructive: false) { [weak self] in
                    self?.chooseSpecies()
                },
                .init(title: unitTitle, symbol: "ruler", destructive: false) { [weak self] in
                    self?.toggleUnit()
                },
                .init(title: "Duplicate project", symbol: "plus.square.on.square", destructive: false) { [weak self] in
                    self?.duplicateProject()
                },
                .init(title: "Delete project", symbol: "trash", destructive: true) { [weak self] in
                    self?.deleteProject()
                }
            ]
        )
    }

    private func renameProject() {
        guard let project else { return }
        TextPromptSheetViewController.present(
            from: self,
            title: "Rename project",
            fieldTitle: "Project name",
            placeholder: "Project name",
            initialText: project.title,
            confirmTitle: "Rename"
        ) { [weak self] text in
            guard var project = self?.project else { return }
            project.title = text
            self?.store.update(project)
        }
    }

    private func chooseSpecies() {
        guard project != nil else { return }
        let list = ToolData.species
        let items = list.map {
            SelectionSheetViewController.Item(title: $0.name, subtitle: $0.botanical)
        }
        SelectionSheetViewController.present(from: self, title: "Species", items: items) { [weak self] index in
            guard let self, index < list.count, var project = self.project else { return }
            project.speciesID = list[index].id
            self.store.update(project)
            Haptics.tap()
        }
    }

    private func toggleUnit() {
        guard var project else { return }
        project.unit = project.unit == .metric ? .imperial : .metric
        store.update(project)
        showToast(
            project.unit == .metric ? "Showing millimetres" : "Showing inches",
            icon: "ruler"
        )
    }

    private func duplicateProject() {
        guard let copy = store.duplicateProject(id: projectID) else { return }
        Haptics.success()
        showToast("“\(copy.title)” added to the bench", icon: "plus.square.on.square")
    }

    private func deleteProject() {
        guard let project else { return }
        ConfirmSheetViewController.present(
            from: self,
            title: "Delete “\(project.title)”?",
            message: "The parts, cut plan and build steps for this project will be removed. This cannot be undone.",
            confirmTitle: "Delete project",
            destructive: true
        ) { [weak self] in
            Haptics.warn()
            self?.store.deleteProject(id: self?.projectID ?? "")
            self?.navigationController?.popViewController(animated: true)
            ToastCenter.shared.show("Project removed", icon: "trash")
        }
    }

    // MARK: - Plan

    private func renderPlan() {
        guard let project else { return }

        let panel = DetailPanel(
            title: "Parts",
            info: "\(BenchFormat.count(project.partCount, "piece")) · \(BenchFormat.boardFeetText(project.netBoardFeet))",
            subtitle: "Finished sizes. Kerf, end trim and stock selection are handled on the Cuts tab."
        )

        let rows = UIStackView(axis: .vertical, spacing: 0)
        if project.parts.isEmpty {
            let empty = UILabel()
            empty.text = "No parts yet. Add the first piece and the cut plan will start to take shape."
            empty.font = Typeface.body(12)
            empty.textColor = Palette.inkFaint
            empty.numberOfLines = 0
            empty.setLineHeight(3)
            rows.addArrangedSubview(empty)
        } else {
            for (index, part) in project.parts.enumerated() {
                let row = PartRow(part: part, project: project, colorIndex: index)
                row.onOpen = { [weak self] in self?.editPart(id: part.id) }
                rows.addArrangedSubview(row)
                if index < project.parts.count - 1 {
                    rows.addArrangedSubview(DividerLine())
                }
            }
        }
        panel.add(rows)
        let add = DetailAddRow(title: "Add a part") { [weak self] in self?.addPart() }
        panel.add(add, spacing: 6)
        contentStack.addArrangedSubview(panel)

        let notesPanel = DetailPanel(
            title: "Notes",
            subtitle: "Glue-ups, finish schedule, the things you will forget by the time the clamps come off."
        )
        notesPanel.add(makeNotesView(project: project))
        contentStack.addArrangedSubview(notesPanel)

        contentStack.addArrangedSubview(
            ToolNoteView(
                text: "Every solid part has a seasonal movement allowance. Open Movement to compare the shop with the room the piece will live in."
            )
        )
    }

    private func makeNotesView(project: BenchProject) -> UIView {
        let holder = UIView()
        holder.backgroundColor = Palette.cream.withAlphaComponent(0.4)
        holder.layer.cornerRadius = 15
        holder.layer.cornerCurve = .continuous
        holder.translatesAutoresizingMaskIntoConstraints = false
        holder.heightAnchor.constraint(equalToConstant: 112).isActive = true

        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.text = project.notes
        textView.font = Typeface.body(13)
        textView.textColor = Palette.ink
        textView.tintColor = Palette.terracotta
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 9, bottom: 8, right: 9)
        textView.delegate = self
        textView.keyboardDismissMode = .interactive
        textView.translatesAutoresizingMaskIntoConstraints = false

        let placeholder = UILabel()
        placeholder.text = "A finish schedule, a glue-up order, a reminder to check the grain…"
        placeholder.font = Typeface.body(13)
        placeholder.textColor = Palette.inkFaint.withAlphaComponent(0.75)
        placeholder.numberOfLines = 0
        placeholder.isHidden = !project.notes.trimmed.isEmpty
        placeholder.isUserInteractionEnabled = false
        placeholder.translatesAutoresizingMaskIntoConstraints = false

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(finishNotes))
        ]
        toolbar.tintColor = Palette.terracotta
        textView.inputAccessoryView = toolbar

        holder.addSubview(textView)
        holder.addSubview(placeholder)
        textView.pinEdges(to: holder)
        NSLayoutConstraint.activate([
            placeholder.topAnchor.constraint(equalTo: holder.topAnchor, constant: 13),
            placeholder.leadingAnchor.constraint(equalTo: holder.leadingAnchor, constant: 15),
            placeholder.trailingAnchor.constraint(equalTo: holder.trailingAnchor, constant: -15)
        ])

        notesView = textView
        notesPlaceholder = placeholder
        return holder
    }

    @objc private func finishNotes() {
        view.endEditing(true)
        saveNotes()
    }

    private func saveNotes() {
        guard let textView = notesView, var project else { return }
        let text = textView.text ?? ""
        guard text != project.notes else { return }
        project.notes = text
        isSuppressingRefresh = true
        store.update(project)
        isSuppressingRefresh = false
    }

    private func addPart() {
        guard let project else { return }
        let draft = ProjectPart(
            name: "New part",
            lengthMM: 300,
            widthMM: 100,
            thicknessMM: 25,
            quantity: 1,
            material: .solid,
            grain: .alongLength
        )
        let form = PartFormViewController(project: project, part: draft, isNew: true)
        form.onSaved = { [weak self] part in
            guard var project = self?.project else { return }
            project.parts.append(part)
            self?.store.update(project)
            self?.showToast("Part added", icon: "checkmark")
        }
        presentForm(form)
    }

    private func editPart(id: String) {
        guard
            let project,
            let index = project.parts.firstIndex(where: { $0.id == id })
        else { return }
        let form = PartFormViewController(project: project, part: project.parts[index], isNew: false)
        form.onSaved = { [weak self] part in
            guard var project = self?.project, let index = project.parts.firstIndex(where: { $0.id == part.id }) else { return }
            project.parts[index] = part
            self?.store.update(project)
            self?.showToast("Part updated", icon: "checkmark")
        }
        form.onDeleted = { [weak self] in
            guard var project = self?.project else { return }
            project.parts.removeAll { $0.id == id }
            self?.store.update(project)
            self?.showToast("Part removed", icon: "trash")
        }
        presentForm(form)
    }

    // MARK: - Cuts

    private func renderCuts() {
        guard let project else { return }

        let stockPanel = DetailPanel(
            title: "Stock",
            info: BenchFormat.count(project.stock.count, "type"),
            subtitle: "The boards you can actually buy or already have. The plan matches each part to the thinnest, narrowest board that can yield it."
        )
        let stockRows = UIStackView(axis: .vertical, spacing: 0)
        if project.stock.isEmpty {
            let empty = UILabel()
            empty.text = "No stock yet. Add a board and the plan can start placing parts."
            empty.font = Typeface.body(12)
            empty.textColor = Palette.inkFaint
            empty.numberOfLines = 0
            empty.setLineHeight(3)
            stockRows.addArrangedSubview(empty)
        } else {
            for (index, stock) in project.stock.enumerated() {
                let row = StockRow(stock: stock, project: project)
                row.onOpen = { [weak self] in self?.editStock(id: stock.id) }
                stockRows.addArrangedSubview(row)
                if index < project.stock.count - 1 {
                    stockRows.addArrangedSubview(DividerLine())
                }
            }
        }
        stockPanel.add(stockRows)
        stockPanel.add(DetailAddRow(title: "Add stock") { [weak self] in self?.addStock() }, spacing: 6)
        contentStack.addArrangedSubview(stockPanel)

        let settings = DetailPanel(
            title: "Cut settings",
            subtitle: "Match the kerf to the blade and the trim to how much you square off each end."
        )
        let kerf = BenchStepperRow(
            title: "Blade kerf",
            subtitle: "The width of the saw cut.",
            value: project.kerfMM,
            minimum: 1,
            maximum: 8,
            step: 0.5
        )
        kerf.onChange = { [weak self] value in self?.updateCutSettings(kerf: value, trim: nil) }
        settings.add(kerf, spacing: 8)
        settings.add(DividerLine(), spacing: 10)
        let trim = BenchStepperRow(
            title: "End trim",
            subtitle: "Removed from both ends of every board.",
            value: project.trimMM,
            minimum: 0,
            maximum: 40,
            step: 2
        )
        trim.onChange = { [weak self] value in self?.updateCutSettings(kerf: nil, trim: value) }
        settings.add(trim, spacing: 10)
        contentStack.addArrangedSubview(settings)

        let output = UIStackView(axis: .vertical, spacing: 14)
        cutsOutputStack = output
        contentStack.addArrangedSubview(output)
        refreshCutOutputs()
    }

    private func updateCutSettings(kerf: Double?, trim: Double?) {
        guard var project else { return }
        if let kerf { project.kerfMM = kerf }
        if let trim { project.trimMM = trim }
        isSuppressingRefresh = true
        store.update(project)
        isSuppressingRefresh = false
        refreshHeaderOnly()
        refreshCutOutputs()
    }

    private func refreshCutOutputs() {
        guard let project, let output = cutsOutputStack else { return }
        output.arrangedSubviews.forEach { view in
            output.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let plan = BenchEngine.plan(project: project)
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
        output.addArrangedSubview(result)

        if !plan.unplaced.isEmpty {
            output.addArrangedSubview(BenchUnplacedCard(plan: plan))
        }

        if project.parts.contains(where: { $0.grain == .acrossWidth && $0.material == .solid }) {
            output.addArrangedSubview(
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
                shoppingRows.addArrangedSubview(ShoppingRow(summary: summary, project: project))
                if index < plan.summaries.count - 1 {
                    shoppingRows.addArrangedSubview(DividerLine())
                }
            }
            shopping.add(shoppingRows)
            output.addArrangedSubview(shopping)
        }

        let sequence = DetailPanel(
            title: "Cut sequence",
            subtitle: plan.boards.isEmpty
                ? "Add parts and stock and the boards will be laid out here."
                : "Each board is ripped into strips, then cross-cut. Kerf and end trim are included."
        )
        if plan.boards.isEmpty {
            let empty = UILabel()
            empty.text = "No boards in the plan yet."
            empty.font = Typeface.body(12)
            empty.textColor = Palette.inkFaint
            sequence.add(empty)
        } else {
            let boardsStack = UIStackView(axis: .vertical, spacing: 12)
            for (index, board) in plan.boards.enumerated() {
                if index > 0 { boardsStack.addArrangedSubview(DividerLine()) }
                boardsStack.addArrangedSubview(BenchBoardView(board: board, index: index, project: project))
            }
            sequence.add(boardsStack)
        }
        output.addArrangedSubview(sequence)

        output.addArrangedSubview(
            ToolNoteView(
                text: "The plan is a starting point, not a promise. Check every board for knots and checks before committing a cut, and always cut the longest part first."
            )
        )
    }

    private func addStock() {
        guard let project else { return }
        let draft = StockBoard(
            label: "Board stock",
            material: .solid,
            thicknessMM: 25,
            widthMM: 200,
            lengthMM: 2400,
            quantity: 1,
            pricePerBoardFoot: 0
        )
        let form = StockFormViewController(project: project, stock: draft, isNew: true)
        form.onSaved = { [weak self] stock in
            guard var project = self?.project else { return }
            project.stock.append(stock)
            self?.store.update(project)
            self?.showToast("Stock added", icon: "checkmark")
        }
        presentForm(form)
    }

    private func editStock(id: String) {
        guard
            let project,
            let index = project.stock.firstIndex(where: { $0.id == id })
        else { return }
        let form = StockFormViewController(project: project, stock: project.stock[index], isNew: false)
        form.onSaved = { [weak self] stock in
            guard var project = self?.project, let index = project.stock.firstIndex(where: { $0.id == stock.id }) else { return }
            project.stock[index] = stock
            self?.store.update(project)
            self?.showToast("Stock updated", icon: "checkmark")
        }
        form.onDeleted = { [weak self] in
            guard var project = self?.project else { return }
            project.stock.removeAll { $0.id == id }
            self?.store.update(project)
            self?.showToast("Stock removed", icon: "trash")
        }
        presentForm(form)
    }

    // MARK: - Movement

    private func renderMovement() {
        guard let project else { return }

        let speciesPanel = DetailPanel(
            title: "Species",
            subtitle: "Movement figures use flat-sawn tangential shrinkage from green to oven-dry."
        )
        let speciesRow = BenchSpeciesRow(species: project.species)
        speciesRow.onTap = { [weak self] in self?.chooseSpecies() }
        speciesPanel.add(speciesRow, spacing: 0)
        contentStack.addArrangedSubview(speciesPanel)

        let roomPanel = DetailPanel(
            title: "The room",
            subtitle: "Compare the air where you build with the air where the piece will live."
        )
        let shop = RHSliderRow(title: "Shop air", value: project.shopRH)
        shop.onChange = { [weak self] value in self?.updateHumidity(shop: value, home: nil) }
        roomPanel.add(shop, spacing: 8)
        let home = RHSliderRow(title: "Home air", value: project.homeRH)
        home.onChange = { [weak self] value in self?.updateHumidity(shop: nil, home: value) }
        roomPanel.add(home, spacing: 10)

        let mcSummary = UILabel()
        mcSummary.font = Typeface.chip(10.5, weight: .medium)
        mcSummary.textColor = Palette.inkSoft
        mcSummary.numberOfLines = 0
        roomPanel.add(mcSummary, spacing: 10)
        movementMCSummary = mcSummary
        contentStack.addArrangedSubview(roomPanel)

        let output = UIStackView(axis: .vertical, spacing: 14)
        movementOutputStack = output
        contentStack.addArrangedSubview(output)
        refreshMovementOutputs()
    }

    private func updateHumidity(shop: Double?, home: Double?) {
        guard var project else { return }
        if let shop { project.shopRH = shop }
        if let home { project.homeRH = home }
        isSuppressingRefresh = true
        store.update(project)
        isSuppressingRefresh = false
        refreshMovementOutputs()
    }

    private func refreshMovementOutputs() {
        guard let project, let output = movementOutputStack else { return }
        output.arrangedSubviews.forEach { view in
            output.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let movement = BenchEngine.movement(project: project)
        movementMCSummary?.text = String(
            format: "Shop %.1f%% MC  →  home %.1f%% MC",
            movement.shopMC,
            movement.homeMC
        )

        let result = ToolResultCard()
        if project.unit == .metric {
            result.valueLabel.text = String(format: "%.1f", movement.maxMovementMM)
            result.unitLabel.text = "mm"
        } else {
            result.valueLabel.text = String(format: "%.3f", movement.maxMovementMM / BenchFormat.mmPerInch)
            result.unitLabel.text = "in"
        }
        let direction = movement.isShrinking ? "Dries and shrinks" : "Takes moisture and grows"
        result.setDetail(rows: [
            ("Shop air", String(format: "%.0f%% RH · %.1f%% MC", project.shopRH, movement.shopMC)),
            ("Home air", String(format: "%.0f%% RH · %.1f%% MC", project.homeRH, movement.homeMC)),
            ("Direction", direction),
            ("Largest part", movement.maxPartName ?? "No solid parts"),
            ("Over 1.5 mm", "\(movement.exceedsCount)")
        ])
        output.addArrangedSubview(result)

        let panel = DetailPanel(
            title: "Cut allowance",
            subtitle: "Add the allowance to the across-grain dimension when you cut. Let the piece settle before final fitting."
        )
        if movement.rows.isEmpty {
            let empty = UILabel()
            empty.text = "Add a part to see its movement allowance."
            empty.font = Typeface.body(12)
            empty.textColor = Palette.inkFaint
            panel.add(empty)
        } else {
            let rows = UIStackView(axis: .vertical, spacing: 0)
            for (index, row) in movement.rows.enumerated() {
                rows.addArrangedSubview(MovementRowView(row: row, unit: project.unit))
                if index < movement.rows.count - 1 {
                    rows.addArrangedSubview(DividerLine())
                }
            }
            panel.add(rows)
        }
        output.addArrangedSubview(panel)

        output.addArrangedSubview(
            ToolNoteView(
                text: "Quarter-sawn stock moves roughly half as much across the width. These figures are typical values for seasoned wood — measure your own stock and leave a little extra."
            )
        )
    }

    // MARK: - Steps

    private func renderSteps() {
        guard let project else { return }

        let progressPanel = DetailPanel(
            title: "Build order",
            info: "\(project.doneSteps) / \(project.steps.count)"
        )
        let bar = BenchProgressBar(
            height: 8,
            trackColor: Palette.cream,
            tint: Palette.terracotta
        )
        bar.progress = CGFloat(project.progress)
        progressPanel.add(bar)

        let next = UILabel()
        if let step = project.nextStep {
            next.text = "Next: \(step.title)"
            next.textColor = Palette.terracotta
            next.font = Typeface.chip(12, weight: .semibold)
        } else {
            next.text = project.steps.isEmpty ? "No build steps yet." : "Every step is done."
            next.textColor = Palette.moss
            next.font = Typeface.chip(12, weight: .semibold)
        }
        next.numberOfLines = 0
        progressPanel.add(next, spacing: 10)
        contentStack.addArrangedSubview(progressPanel)

        let stepsPanel = DetailPanel(
            title: "Steps",
            subtitle: "Tap a row to mark it done. Use the menu to edit or remove a step."
        )
        if project.steps.isEmpty {
            let empty = UILabel()
            empty.text = "Break the build into stages. A dry fit and a glue-up are steps too."
            empty.font = Typeface.body(12)
            empty.textColor = Palette.inkFaint
            empty.numberOfLines = 0
            empty.setLineHeight(3)
            stepsPanel.add(empty)
        } else {
            let rows = UIStackView(axis: .vertical, spacing: 0)
            for (index, step) in project.steps.enumerated() {
                let row = BuildStepRow(index: index, step: step)
                row.onToggle = { [weak self] in self?.toggleStep(index: index) }
                row.onMenu = { [weak self] in self?.showStepMenu(index: index) }
                rows.addArrangedSubview(row)
                if index < project.steps.count - 1 {
                    rows.addArrangedSubview(DividerLine())
                }
            }
            stepsPanel.add(rows)
        }
        stepsPanel.add(DetailAddRow(title: "Add a step") { [weak self] in self?.addStep() }, spacing: 6)
        contentStack.addArrangedSubview(stepsPanel)

        contentStack.addArrangedSubview(
            ToolNoteView(
                text: "Progress is saved with the project, so the bench remembers exactly where you stopped."
            )
        )
    }

    private func toggleStep(index: Int) {
        guard var project, index < project.steps.count else { return }
        project.steps[index].isDone.toggle()
        let done = project.steps[index].isDone
        store.update(project)
        if done {
            Haptics.success()
        } else {
            Haptics.tap()
        }
    }

    private func addStep() {
        TextPromptSheetViewController.present(
            from: self,
            title: "Add a build step",
            fieldTitle: "Step title",
            placeholder: "e.g. Cut the mortises",
            confirmTitle: "Add step"
        ) { [weak self] text in
            guard var project = self?.project else { return }
            project.steps.append(ProjectStep(title: text))
            self?.store.update(project)
            self?.showToast("Step added", icon: "checkmark")
        }
    }

    private func showStepMenu(index: Int) {
        guard let project, index < project.steps.count else { return }
        let step = project.steps[index]
        ActionSheetViewController.present(
            from: self,
            title: step.title,
            options: [
                .init(title: "Edit step", symbol: "pencil", destructive: false) { [weak self] in
                    self?.editStep(index: index)
                },
                .init(title: "Delete step", symbol: "trash", destructive: true) { [weak self] in
                    self?.deleteStep(index: index)
                }
            ]
        )
    }

    private func editStep(index: Int) {
        guard let project, index < project.steps.count else { return }
        let step = project.steps[index]
        TextPromptSheetViewController.present(
            from: self,
            title: "Edit step",
            fieldTitle: "Step title",
            initialText: step.title,
            confirmTitle: "Save step"
        ) { [weak self] text in
            guard var project = self?.project, index < project.steps.count else { return }
            project.steps[index].title = text
            self?.store.update(project)
        }
    }

    private func deleteStep(index: Int) {
        guard let project, index < project.steps.count else { return }
        let step = project.steps[index]
        ConfirmSheetViewController.present(
            from: self,
            title: "Delete this step?",
            message: "“\(step.title)” will be removed from the build order.",
            confirmTitle: "Delete step",
            destructive: true
        ) { [weak self] in
            guard var project = self?.project, index < project.steps.count else { return }
            project.steps.remove(at: index)
            self?.store.update(project)
            self?.showToast("Step removed", icon: "trash")
        }
    }

    // MARK: - Presentation

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

    // MARK: - Keyboard

    @objc private func keyboardChanged(_ note: Notification) {
        guard
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY)
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = 40 + overlap
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
        }
        if notesView?.isFirstResponder == true, let notesView {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, weak notesView] in
                guard let self, let notesView else { return }
                let rect = notesView.convert(notesView.bounds, to: self.scrollView).insetBy(dx: 0, dy: -20)
                self.scrollView.scrollRectToVisible(rect, animated: true)
            }
        }
    }

    @objc private func keyboardHidden() {
        UIView.animate(withDuration: 0.24) {
            self.scrollView.contentInset.bottom = 40
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
}

// MARK: - Notes

extension ProjectDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        notesPlaceholder?.isHidden = !textView.text.trimmed.isEmpty
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        saveNotes()
    }
}
