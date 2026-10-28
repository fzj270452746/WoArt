import UIKit

enum BenchUI {
    static func segmented(items: [String], selected: Int = 0) -> UISegmentedControl {
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = selected
        control.selectedSegmentTintColor = Palette.ink
        control.backgroundColor = Palette.cream
        control.setTitleTextAttributes(
            [.font: Typeface.chip(11.5, weight: .semibold), .foregroundColor: Palette.inkSoft],
            for: .normal
        )
        control.setTitleTextAttributes(
            [.font: Typeface.chip(11.5, weight: .semibold), .foregroundColor: Palette.paper],
            for: .selected
        )
        control.translatesAutoresizingMaskIntoConstraints = false
        control.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return control
    }

    static func labeled(_ title: String, _ view: UIView, spacing: CGFloat = 8) -> UIView {
        let label = EyebrowLabel(title, color: Palette.inkFaint, size: 8.5)
        let stack = UIStackView(axis: .vertical, spacing: spacing, views: [label, view])
        return stack
    }

    static func twoColumns(_ left: UIView, _ right: UIView, spacing: CGFloat = 16) -> UIView {
        let row = UIStackView(axis: .horizontal, spacing: spacing, distribution: .fillEqually, views: [left, right])
        return row
    }
}

class BenchFormViewController: BaseViewController {
    let scrollView = UIScrollView()
    let contentStack = UIStackView()
    let saveButton: PillButton

    private let eyebrowText: String
    private let headerTitle: String
    private let headerSubtitle: String
    private let bar = UIView()
    private var barBottom: NSLayoutConstraint!

    init(eyebrow: String, title: String, subtitle: String, saveTitle: String) {
        eyebrowText = eyebrow
        headerTitle = title
        headerSubtitle = subtitle
        saveButton = PillButton(title: saveTitle, style: .primary, height: 52)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildScaffold()
        buildFields()
        observeKeyboard()
    }

    func buildFields() {}
    func saveTapped() {}

    // MARK: - Scaffold

    private func buildScaffold() {
        let close = CircleIconButton(symbol: "xmark", diameter: 38, pointSize: 13)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let topRow = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [close])
        topRow.addArrangedSubview(UIView())

        let eyebrow = EyebrowLabel(eyebrowText, color: Palette.terracotta, size: 9)
        let title = UILabel()
        title.text = headerTitle
        title.font = Typeface.display(32, weight: .bold)
        title.textColor = Palette.ink
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = headerSubtitle
        subtitle.font = Typeface.body(12.5)
        subtitle.textColor = Palette.inkSoft
        subtitle.numberOfLines = 0
        subtitle.setLineHeight(4)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.addArrangedSubview(topRow)
        contentStack.addArrangedSubview(eyebrow)
        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(subtitle)
        contentStack.setCustomSpacing(22, after: topRow)
        contentStack.setCustomSpacing(7, after: eyebrow)
        contentStack.setCustomSpacing(9, after: title)
        contentStack.setCustomSpacing(22, after: subtitle)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        bar.backgroundColor = Palette.paper
        view.addSubview(bar)
        bar.translatesAutoresizingMaskIntoConstraints = false

        let line = DividerLine()
        bar.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false

        saveButton.addTarget(self, action: #selector(savePressed), for: .touchUpInside)
        bar.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scrollView.bottomAnchor.constraint(equalTo: bar.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            line.topAnchor.constraint(equalTo: bar.topAnchor),
            line.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: bar.trailingAnchor),

            saveButton.topAnchor.constraint(equalTo: bar.topAnchor, constant: 12),
            saveButton.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 24),
            saveButton.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -24),
            saveButton.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -14)
        ])
        barBottom = bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        barBottom.isActive = true
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        Haptics.tap()
        view.endEditing(true)
        dismiss(animated: true)
    }

    @objc private func savePressed() {
        view.endEditing(true)
        saveTapped()
    }

    // MARK: - Keyboard

    private func observeKeyboard() {
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

    @objc private func keyboardChanged(_ note: Notification) {
        guard
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY)
        let safeInset = view.safeAreaInsets.bottom
        let shift = max(0, overlap - safeInset)
        UIView.animate(withDuration: duration) {
            self.barBottom.constant = -shift
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardHidden() {
        UIView.animate(withDuration: 0.24) {
            self.barBottom.constant = 0
            self.view.layoutIfNeeded()
        }
    }
}
