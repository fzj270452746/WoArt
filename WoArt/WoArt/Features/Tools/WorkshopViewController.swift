import UIKit

final class WorkshopViewController: BaseViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let store = BenchStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        buildScaffold()
        rebuild()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataChanged),
            name: .benchDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rebuild()
    }

    // MARK: - Scaffold

    private func buildScaffold() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: Metrics.contentBottomInset,
            right: 0
        )
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.spacing = 14

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 6),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Metrics.gutter),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Metrics.gutter),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Metrics.gutter * 2)
        ])
    }

    // MARK: - Rebuild

    private func rebuild() {
        contentStack.arrangedSubviews.forEach { view in
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let header = makeHeader()
        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(20, after: header)

        if let active = store.activeProject {
            let card = BenchActiveProjectCard(
                project: active,
                metrics: BenchEngine.metrics(project: active)
            )
            card.onOpen = { [weak self] in self?.openProject(active) }
            contentStack.addArrangedSubview(card)
            contentStack.setCustomSpacing(24, after: card)
        } else {
            let start = BenchStartCard { [weak self] in self?.presentNewProject() }
            contentStack.addArrangedSubview(start)
            contentStack.setCustomSpacing(24, after: start)
        }

        if !store.projects.isEmpty {
            let heading = BenchSectionHeading(
                eyebrow: "Projects",
                title: "Your bench",
                actionTitle: "New"
            )
            heading.actionButton.addTarget(self, action: #selector(newProjectTapped), for: .touchUpInside)
            contentStack.addArrangedSubview(heading)
            contentStack.setCustomSpacing(10, after: heading)

            let sorted = store.orderedProjects
            let visible = Array(sorted.prefix(4))
            for project in visible {
                let row = BenchProjectRow(
                    project: project,
                    metrics: BenchEngine.metrics(project: project),
                    isActive: project.id == store.activeProjectID
                )
                row.onOpen = { [weak self] in self?.openProject(project) }
                contentStack.addArrangedSubview(row)
                contentStack.setCustomSpacing(10, after: row)
            }

            if sorted.count > visible.count {
                let all = BenchTextActionRow(
                    title: "See all \(sorted.count) projects",
                    symbol: "square.stack.3d.up"
                ) { [weak self] in
                    self?.openAllProjects()
                }
                contentStack.addArrangedSubview(all)
                contentStack.setCustomSpacing(10, after: all)
            }

            let add = BenchAddProjectRow { [weak self] in self?.presentNewProject() }
            contentStack.addArrangedSubview(add)
            contentStack.setCustomSpacing(26, after: add)
        }

        let toolsHeading = BenchSectionHeading(eyebrow: "Reference", title: "Bench tools")
        contentStack.addArrangedSubview(toolsHeading)
        contentStack.setCustomSpacing(10, after: toolsHeading)

        let grid = makeToolsGrid()
        contentStack.addArrangedSubview(grid)
        contentStack.setCustomSpacing(24, after: grid)

        let footerTitle = EyebrowLabel("Field rule", color: Palette.terracotta, size: 9)
        let footer = UILabel()
        footer.text = "Measure twice. Cut once. Leave the offcut where you can find it. Projects and tools stay on this device — no account, no signal."
        footer.font = Typeface.body(12)
        footer.textColor = Palette.inkFaint
        footer.numberOfLines = 0
        footer.setLineHeight(3)
        contentStack.addArrangedSubview(footerTitle)
        contentStack.addArrangedSubview(footer)
        contentStack.setCustomSpacing(6, after: footerTitle)
    }

    private func makeHeader() -> UIView {
        let wordmark = WordmarkView(size: 28)
        let topRow = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [wordmark])
        topRow.addArrangedSubview(UIView())
        topRow.addArrangedSubview(TagChip(text: "bench", index: 3))

        let eyebrow = EyebrowLabel("The workshop", color: Palette.terracotta)

        let title = UILabel()
        title.text = "The bench."
        title.font = Typeface.display(36, weight: .bold)
        title.textColor = Palette.ink
        title.numberOfLines = 1
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.85

        let subtitle = UILabel()
        subtitle.text = "Plan the piece, cut the stock, and keep every number honest. A project holds the parts, the cuts, the movement and the build order in one place."
        subtitle.font = Typeface.body(13)
        subtitle.textColor = Palette.inkSoft
        subtitle.numberOfLines = 0
        subtitle.setLineHeight(4)

        let ruler = BenchRulerStrip()

        let stack = UIStackView(
            axis: .vertical,
            spacing: 12,
            views: [topRow, eyebrow, title, subtitle, ruler]
        )
        stack.setCustomSpacing(16, after: topRow)
        stack.setCustomSpacing(7, after: eyebrow)
        stack.setCustomSpacing(8, after: title)
        stack.setCustomSpacing(15, after: subtitle)
        stack.setCustomSpacing(2, after: ruler)
        return stack
    }

    private func makeToolsGrid() -> UIView {
        let first = UIStackView(axis: .horizontal, spacing: 12, distribution: .fillEqually)
        let second = UIStackView(axis: .horizontal, spacing: 12, distribution: .fillEqually)
        let third = UIStackView(axis: .horizontal, spacing: 12, distribution: .fillEqually)

        first.addArrangedSubview(
            BenchToolTile(
                index: "01",
                symbol: "ruler",
                title: "Board feet",
                caption: "Volume, waste and cost",
                tint: Palette.brass
            ) { [weak self] in self?.openTool(BoardFootViewController()) }
        )
        first.addArrangedSubview(
            BenchToolTile(
                index: "02",
                symbol: "drop",
                title: "Movement",
                caption: "Moisture and width",
                tint: Palette.teal
            ) { [weak self] in self?.openTool(MoistureViewController()) }
        )
        second.addArrangedSubview(
            BenchToolTile(
                index: "03",
                symbol: "leaf",
                title: "Species",
                caption: "Fourteen woods compared",
                tint: Palette.moss
            ) { [weak self] in self?.openTool(SpeciesLibraryViewController()) }
        )
        second.addArrangedSubview(
            BenchToolTile(
                index: "04",
                symbol: "square.split.2x2",
                title: "Joinery",
                caption: "Match a joint to the job",
                tint: Palette.clay
            ) { [weak self] in self?.openTool(JoineryViewController()) }
        )
        third.addArrangedSubview(
            BenchToolTile(
                index: "05",
                symbol: "function",
                title: "Shop math",
                caption: "Fractions, angles, arcs",
                tint: Palette.terracotta
            ) { [weak self] in self?.openTool(ShopMathViewController()) }
        )
        third.addArrangedSubview(
            BenchToolTile(
                index: "06",
                symbol: "scissors",
                title: "Cut planner",
                caption: "Plan first, save later",
                tint: Palette.inkSoft
            ) { [weak self] in self?.openTool(CutListViewController()) }
        )

        let stack = UIStackView(axis: .vertical, spacing: 12, views: [first, second, third])
        return stack
    }

    // MARK: - Actions

    @objc private func dataChanged() {
        rebuild()
    }

    @objc private func newProjectTapped() {
        presentNewProject()
    }

    func presentNewProject(templateID: String? = nil) {
        Haptics.tap()
        let form = ProjectFormViewController(templateID: templateID)
        form.onCreated = { [weak self] project in
            self?.openProject(project)
        }
        form.modalPresentationStyle = .fullScreen
        present(form, animated: true)
    }

    private func openProject(_ project: BenchProject, section: ProjectDetailViewController.Section = .plan) {
        store.setActive(id: project.id)
        let detail = ProjectDetailViewController(projectID: project.id, initialSection: section)
        navigationController?.pushViewController(detail, animated: true)
    }

    private func openAllProjects() {
        let list = ProjectsViewController { [weak self] project in
            self?.openProject(project)
        }
        navigationController?.pushViewController(list, animated: true)
    }

    private func openTool(_ viewController: UIViewController) {
        Haptics.tap()
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - Active project card

private final class BenchActiveProjectCard: UIControl {
    var onOpen: (() -> Void)?

    init(project: BenchProject, metrics: BenchMetrics) {
        super.init(frame: .zero)

        backgroundColor = Palette.walnut
        layer.cornerRadius = 28
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor(hex: 0x2A1810).cgColor
        layer.shadowOpacity = 0.24
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: 13)

        let eyebrow = EyebrowLabel("On the bench", color: Palette.brassLight, size: 9)

        let stepLabel = UILabel()
        stepLabel.text = metrics.stepCount > 0
            ? "\(metrics.doneSteps) / \(BenchFormat.count(metrics.stepCount, "step"))"
            : "No steps yet"
        stepLabel.font = Typeface.chip(10.5, weight: .semibold)
        stepLabel.textColor = Palette.paper.withAlphaComponent(0.5)

        let topRow = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [eyebrow])
        topRow.addArrangedSubview(UIView())
        topRow.addArrangedSubview(stepLabel)

        let title = UILabel()
        title.text = project.title
        title.font = Typeface.display(25, weight: .bold)
        title.textColor = Palette.paper
        title.numberOfLines = 2

        let meta = UILabel()
        var metaParts = [project.species.name, BenchFormat.count(project.partCount, "part"), BenchFormat.boardFeetText(metrics.netBoardFeet)]
        if metrics.unplacedCount > 0 {
            metaParts.append("\(metrics.unplacedCount) unplaced")
        }
        meta.text = metaParts.joined(separator: "  ·  ")
        meta.font = Typeface.body(11.5, weight: .medium)
        meta.textColor = metrics.unplacedCount > 0
            ? Palette.clay
            : Palette.paper.withAlphaComponent(0.58)
        meta.numberOfLines = 1
        meta.adjustsFontSizeToFitWidth = true
        meta.minimumScaleFactor = 0.8

        let bar = BenchProgressBar(
            height: 5,
            trackColor: Palette.paper.withAlphaComponent(0.14),
            tint: Palette.brassLight
        )
        bar.progress = CGFloat(metrics.progress)

        let nextIcon = UIImageView(
            image: UIImage(
                systemName: "arrow.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
            )
        )
        nextIcon.tintColor = Palette.brassLight

        let nextLabel = UILabel()
        nextLabel.text = project.nextStep.map { "Next: \($0.title.lowercased())" } ?? "Open the project"
        nextLabel.font = Typeface.chip(11.5, weight: .semibold)
        nextLabel.textColor = Palette.brassLight
        nextLabel.numberOfLines = 1
        nextLabel.adjustsFontSizeToFitWidth = true
        nextLabel.minimumScaleFactor = 0.8

        let nextRow = UIStackView(axis: .horizontal, spacing: 7, alignment: .center, views: [nextLabel])
        nextRow.addArrangedSubview(UIView())
        nextRow.addArrangedSubview(nextIcon)

        let stack = UIStackView(
            axis: .vertical,
            spacing: 10,
            views: [topRow, title, meta, bar, nextRow]
        )
        stack.setCustomSpacing(12, after: topRow)
        stack.setCustomSpacing(6, after: title)
        stack.setCustomSpacing(13, after: meta)
        stack.setCustomSpacing(12, after: bar)
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 20, left: 20, bottom: 18, right: 20))

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        addTarget(self, action: #selector(pressed), for: .touchDown)
        addTarget(self, action: #selector(released), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() { onOpen?() }

    @objc private func pressed() {
        UIView.animate(withDuration: 0.12) {
            self.transform = CGAffineTransform(scaleX: 0.986, y: 0.986)
        }
    }

    @objc private func released() {
        UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.3) {
            self.transform = .identity
        }
    }
}

// MARK: - Start card

private final class BenchStartCard: UIView {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)

        backgroundColor = Palette.walnut
        layer.cornerRadius = 28
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor(hex: 0x2A1810).cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: 13)

        let iconCircle = UIView()
        iconCircle.backgroundColor = Palette.brassLight.withAlphaComponent(0.16)
        iconCircle.layer.cornerRadius = 23
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.widthAnchor.constraint(equalToConstant: 46).isActive = true
        iconCircle.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let icon = UIImageView(
            image: UIImage(
                systemName: "hammer",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)
            )
        )
        icon.tintColor = Palette.brassLight
        iconCircle.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor)
        ])

        let eyebrow = EyebrowLabel("Start here", color: Palette.brassLight, size: 9)

        let title = UILabel()
        title.text = "Give the bench a job."
        title.font = Typeface.display(26, weight: .bold)
        title.textColor = Palette.paper
        title.numberOfLines = 2

        let body = UILabel()
        body.text = "Parts, a real cut plan, seasonal movement and build steps — one project, all the numbers."
        body.font = Typeface.body(12.5)
        body.textColor = Palette.paper.withAlphaComponent(0.58)
        body.numberOfLines = 0
        body.setLineHeight(3)

        let button = PillButton(title: "New project", style: .primary, icon: "plus", height: 48)
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        let hint = UILabel()
        hint.text = "Templates for a side table, stool, cutting board and wall shelf."
        hint.font = Typeface.body(10.5)
        hint.textColor = Palette.paper.withAlphaComponent(0.4)
        hint.numberOfLines = 0

        let iconRow = UIStackView(axis: .horizontal, spacing: 0, alignment: .center, views: [iconCircle])
        iconRow.addArrangedSubview(UIView())

        let stack = UIStackView(
            axis: .vertical,
            spacing: 12,
            views: [iconRow, eyebrow, title, body, button, hint]
        )
        stack.setCustomSpacing(16, after: iconRow)
        stack.setCustomSpacing(7, after: eyebrow)
        stack.setCustomSpacing(8, after: title)
        stack.setCustomSpacing(18, after: body)
        stack.setCustomSpacing(12, after: button)
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() { action() }
}

// MARK: - Tool tile

private final class BenchToolTile: UIControl {
    private let action: () -> Void

    init(
        index: String,
        symbol: String,
        title: String,
        caption: String,
        tint: UIColor,
        action: @escaping () -> Void
    ) {
        self.action = action
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 126).isActive = true

        backgroundColor = Palette.card
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.ink.withAlphaComponent(0.055).cgColor
        applySoftShadow(opacity: 0.07, radius: 14, y: 7)

        let indexLabel = UILabel()
        indexLabel.text = index
        indexLabel.font = Typeface.eyebrow(8)
        indexLabel.textColor = Palette.inkFaint

        let arrow = UIImageView(
            image: UIImage(
                systemName: "arrow.up.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
            )
        )
        arrow.tintColor = Palette.inkFaint

        let topRow = UIStackView(axis: .horizontal, spacing: 6, alignment: .center, views: [indexLabel])
        topRow.addArrangedSubview(UIView())
        topRow.addArrangedSubview(arrow)

        let iconCircle = UIView()
        iconCircle.backgroundColor = tint.withAlphaComponent(0.14)
        iconCircle.layer.cornerRadius = 17
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.widthAnchor.constraint(equalToConstant: 34).isActive = true
        iconCircle.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let icon = UIImageView(
            image: UIImage(
                systemName: symbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            )
        )
        icon.tintColor = tint
        iconCircle.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typeface.display(18, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8

        let captionLabel = UILabel()
        captionLabel.text = caption
        captionLabel.font = Typeface.body(9.5)
        captionLabel.textColor = Palette.inkSoft
        captionLabel.numberOfLines = 2

        topRow.isUserInteractionEnabled = false
        iconCircle.isUserInteractionEnabled = false
        addSubviews(topRow, iconCircle, titleLabel, captionLabel)
        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            topRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            topRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13),

            iconCircle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconCircle.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 9),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: iconCircle.bottomAnchor, constant: 8),

            captionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            captionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            captionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        addTarget(self, action: #selector(pressed), for: .touchDown)
        addTarget(self, action: #selector(released), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() { action() }

    @objc private func pressed() {
        UIView.animate(withDuration: 0.12) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    @objc private func released() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.3) {
            self.transform = .identity
        }
    }
}

// MARK: - Small rows

final class BenchAddProjectRow: UIControl {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 56).isActive = true

        backgroundColor = Palette.cream.withAlphaComponent(0.45)
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.ink.withAlphaComponent(0.1).cgColor

        let plus = UIImageView(
            image: UIImage(
                systemName: "plus",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            )
        )
        plus.tintColor = Palette.terracotta

        let label = UILabel()
        label.text = "New project"
        label.font = Typeface.chip(13.5, weight: .semibold)
        label.textColor = Palette.inkSoft

        plus.isUserInteractionEnabled = false
        label.isUserInteractionEnabled = false
        addSubviews(plus, label)
        NSLayoutConstraint.activate([
            plus.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            plus.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: plus.trailingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() {
        Haptics.tap()
        action()
    }
}

final class BenchTextActionRow: UIControl {
    private let action: () -> Void

    init(title: String, symbol: String, action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 42).isActive = true

        let icon = UIImageView(
            image: UIImage(
                systemName: symbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
            )
        )
        icon.tintColor = Palette.inkFaint

        let label = UILabel()
        label.text = title
        label.font = Typeface.chip(12, weight: .semibold)
        label.textColor = Palette.inkSoft

        let chevron = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
            )
        )
        chevron.tintColor = Palette.inkFaint

        icon.isUserInteractionEnabled = false
        label.isUserInteractionEnabled = false
        chevron.isUserInteractionEnabled = false
        addSubviews(icon, label, chevron)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 7),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() {
        Haptics.tap()
        action()
    }
}

final class BenchRulerStrip: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 14).isActive = true
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(Palette.ink.withAlphaComponent(0.16).cgColor)
        context.setLineWidth(1)
        var x: CGFloat = 0
        var index = 0
        while x < rect.width {
            let isLong = index % 5 == 0
            let height: CGFloat = isLong ? 10 : 5
            context.move(to: CGPoint(x: x, y: rect.height - height))
            context.addLine(to: CGPoint(x: x, y: rect.height))
            x += 6
            index += 1
        }
        context.strokePath()

        context.setStrokeColor(Palette.brass.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1.5)
        context.move(to: CGPoint(x: 0, y: rect.height - 0.75))
        context.addLine(to: CGPoint(x: rect.width, y: rect.height - 0.75))
        context.strokePath()
    }
}
