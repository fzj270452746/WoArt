import UIKit

final class ProjectsViewController: BaseViewController {
    private let store = BenchStore.shared
    private let topBar = DetailTopBar()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let onOpen: (BenchProject) -> Void

    override var hidesDock: Bool { true }

    init(onOpen: @escaping (BenchProject) -> Void) {
        self.onOpen = onOpen
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackBar(topBar)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 11

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 18),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Metrics.gutter),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Metrics.gutter),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Metrics.gutter * 2)
        ])

        rebuild()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataChanged),
            name: .benchDidChange,
            object: nil
        )
    }

    private func rebuild() {
        contentStack.arrangedSubviews.forEach { view in
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let eyebrow = EyebrowLabel("Projects", color: Palette.terracotta, size: 9)
        let title = UILabel()
        title.text = "Your bench."
        title.font = Typeface.display(33, weight: .bold)
        title.textColor = Palette.ink

        let subtitle = UILabel()
        subtitle.text = store.projects.isEmpty
            ? "Start with a template, then make it yours."
            : "\(BenchFormat.count(store.projects.count, "project")), all kept on this device."
        subtitle.font = Typeface.body(13)
        subtitle.textColor = Palette.inkSoft
        subtitle.numberOfLines = 0

        let header = UIStackView(axis: .vertical, spacing: 6, views: [eyebrow, title, subtitle])
        header.setCustomSpacing(7, after: eyebrow)
        header.setCustomSpacing(7, after: title)
        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(20, after: header)

        if store.projects.isEmpty {
            let empty = EmptyStateView(
                title: "Nothing on the bench",
                message: "Start a project and the parts, cut plan and build steps will live together.",
                actionTitle: "New project"
            ) { [weak self] in
                self?.presentForm()
            }
            empty.heightAnchor.constraint(equalToConstant: 320).isActive = true
            contentStack.addArrangedSubview(empty)
            return
        }

        for project in store.orderedProjects {
            let row = BenchProjectRow(
                project: project,
                metrics: BenchEngine.metrics(project: project),
                isActive: project.id == store.activeProjectID
            )
            row.onOpen = { [weak self] in self?.onOpen(project) }
            contentStack.addArrangedSubview(row)
            contentStack.setCustomSpacing(10, after: row)
        }

        let add = BenchAddProjectRow { [weak self] in self?.presentForm() }
        contentStack.addArrangedSubview(add)
        contentStack.setCustomSpacing(6, after: add)

        let note = UILabel()
        note.text = "Open a project to edit its parts, stock and build order."
        note.font = Typeface.body(11)
        note.textColor = Palette.inkFaint
        note.numberOfLines = 0
        contentStack.addArrangedSubview(note)
    }

    private func presentForm() {
        let form = ProjectFormViewController()
        form.onCreated = { [weak self] project in
            self?.onOpen(project)
        }
        form.modalPresentationStyle = .fullScreen
        present(form, animated: true)
    }

    @objc private func dataChanged() {
        rebuild()
    }
}
