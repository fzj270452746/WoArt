import UIKit

class ToolPageViewController: BaseViewController {
    private let topBar = DetailTopBar()
    private let scrollView = UIScrollView()
    let contentStack = UIStackView()
    private let eyebrowText: String
    private let titleText: String
    private let introText: String
    private let formulaText: String?

    override var hidesDock: Bool { true }

    init(eyebrow: String, title: String, intro: String, formula: String? = nil) {
        eyebrowText = eyebrow
        titleText = title
        introText = intro
        formulaText = formula
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackBar(topBar)

        let eyebrow = EyebrowLabel(eyebrowText, color: Palette.terracotta)
        let title = UILabel()
        title.text = titleText
        title.font = Typeface.display(35, weight: .bold)
        title.textColor = Palette.ink
        title.numberOfLines = 0

        let intro = UILabel()
        intro.text = introText
        intro.font = Typeface.body(14)
        intro.textColor = Palette.inkSoft
        intro.numberOfLines = 0
        intro.setLineHeight(4)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.addArrangedSubview(eyebrow)
        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(intro)

        if let formulaText {
            contentStack.addArrangedSubview(makeFormulaChip(formulaText))
        }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        contentStack.setCustomSpacing(7, after: eyebrow)
        contentStack.setCustomSpacing(12, after: title)
        contentStack.setCustomSpacing(18, after: intro)

        observeKeyboard()
        buildContent()
    }

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toolKeyboardChanged(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toolKeyboardHidden),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toolFieldBeganEditing(_:)),
            name: UITextField.textDidBeginEditingNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toolFieldBeganEditing(_:)),
            name: UITextView.textDidBeginEditingNotification,
            object: nil
        )
    }

    @objc private func toolKeyboardChanged(_ note: Notification) {
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
    }

    @objc private func toolKeyboardHidden() {
        UIView.animate(withDuration: 0.24) {
            self.scrollView.contentInset.bottom = 40
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    @objc private func toolFieldBeganEditing(_ note: Notification) {
        guard let field = note.object as? UIView, field.isDescendant(of: view) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { [weak self, weak field] in
            guard let self, let field else { return }
            let rect = field.convert(field.bounds, to: self.scrollView).insetBy(dx: 0, dy: -40)
            self.scrollView.scrollRectToVisible(rect, animated: true)
        }
    }

    func buildContent() {}

    func addSection(_ view: UIView, spacing: CGFloat = 16) {
        contentStack.addArrangedSubview(view)
        contentStack.setCustomSpacing(spacing, after: contentStack.arrangedSubviews[contentStack.arrangedSubviews.count - 2])
    }

    private func makeFormulaChip(_ formula: String) -> UIView {
        let container = UIView()
        container.backgroundColor = Palette.cream
        container.layer.cornerRadius = 16
        container.layer.cornerCurve = .continuous

        let label = UILabel()
        label.text = formula
        label.font = .monospacedSystemFont(ofSize: 11.5, weight: .medium)
        label.textColor = Palette.inkSoft
        label.numberOfLines = 0
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14)
        ])
        return container
    }
}

final class ToolSectionCard: UIView {
    private let stack = UIStackView()

    init(title: String, subtitle: String? = nil) {
        super.init(frame: .zero)
        backgroundColor = Palette.card
        layer.cornerRadius = 26
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.ink.withAlphaComponent(0.06).cgColor
        applySoftShadow(opacity: 0.08, radius: 18, y: 9)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typeface.display(20, weight: .semibold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0

        stack.axis = .vertical
        stack.spacing = 16
        stack.addArrangedSubview(titleLabel)

        if let subtitle {
            let sub = UILabel()
            sub.text = subtitle
            sub.font = Typeface.body(12.5)
            sub.textColor = Palette.inkSoft
            sub.numberOfLines = 0
            stack.addArrangedSubview(sub)
            stack.setCustomSpacing(6, after: titleLabel)
        }

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 20, left: 18, bottom: 20, right: 18))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func add(_ view: UIView, spacing: CGFloat = 14) {
        stack.addArrangedSubview(view)
        if stack.arrangedSubviews.count >= 2 {
            stack.setCustomSpacing(spacing, after: stack.arrangedSubviews[stack.arrangedSubviews.count - 2])
        }
    }
}

final class NumberFieldRow: UIView {
    let textField = UITextField()
    private let titleLabel = UILabel()
    private let unitLabel = UILabel()
    private let line = UIView()
    var onChange: (() -> Void)?

    var value: Double? {
        Double(textField.text?.replacingOccurrences(of: ",", with: ".") ?? "")
    }

    init(title: String, unit: String, placeholder: String = "0") {
        super.init(frame: .zero)

        titleLabel.text = title.uppercased()
        titleLabel.font = Typeface.eyebrow(9)
        titleLabel.textColor = Palette.inkFaint

        textField.font = Typeface.display(23, weight: .semibold)
        textField.textColor = Palette.ink
        textField.tintColor = Palette.terracotta
        textField.keyboardType = .decimalPad
        textField.placeholder = placeholder
        textField.addTarget(self, action: #selector(changed), for: .editingChanged)

        unitLabel.text = unit
        unitLabel.font = Typeface.chip(11.5, weight: .semibold)
        unitLabel.textColor = Palette.inkSoft
        unitLabel.setContentHuggingPriority(.required, for: .horizontal)

        line.backgroundColor = Palette.hairline
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(finishEditing))
        ]
        toolbar.tintColor = Palette.terracotta
        textField.inputAccessoryView = toolbar

        addSubviews(titleLabel, textField, unitLabel, line)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.bottomAnchor.constraint(equalTo: line.topAnchor, constant: -4),

            unitLabel.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 6),
            unitLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            unitLabel.centerYAnchor.constraint(equalTo: textField.centerYAnchor),

            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setValue(_ value: String) {
        textField.text = value
    }

    func setUnit(_ text: String) {
        unitLabel.text = text.uppercased()
    }

    @objc private func changed() { onChange?() }

    @objc private func finishEditing() { textField.resignFirstResponder() }
}

final class ToolResultCard: UIView {
    private let eyebrowLabel = EyebrowLabel("Result", color: Palette.brassLight, size: 9)
    let valueLabel = UILabel()
    let unitLabel = UILabel()
    private let detailStack = UIStackView()

    init(value: String = "0", unit: String = "") {
        super.init(frame: .zero)
        backgroundColor = Palette.walnut
        layer.cornerRadius = 28
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor(hex: 0x2A1810).cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 22
        layer.shadowOffset = CGSize(width: 0, height: 12)

        valueLabel.text = value
        valueLabel.font = Typeface.display(46, weight: .bold)
        valueLabel.textColor = Palette.paper
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.6

        unitLabel.text = unit
        unitLabel.font = Typeface.chip(12, weight: .semibold)
        unitLabel.textColor = Palette.paper.withAlphaComponent(0.55)

        let valueRow = UIStackView(axis: .horizontal, spacing: 8, alignment: .lastBaseline, views: [valueLabel, unitLabel])

        detailStack.axis = .vertical
        detailStack.spacing = 8

        let stack = UIStackView(axis: .vertical, spacing: 10, views: [eyebrowLabel, valueRow, detailStack])
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setDetail(rows: [(String, String)]) {
        detailStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for row in rows {
            let key = UILabel()
            key.text = row.0
            key.font = Typeface.body(12)
            key.textColor = Palette.paper.withAlphaComponent(0.55)

            let value = UILabel()
            value.text = row.1
            value.font = Typeface.chip(12, weight: .semibold)
            value.textColor = Palette.paper
            value.textAlignment = .right

            let line = UIStackView(axis: .horizontal, spacing: 10, views: [key, value])
            detailStack.addArrangedSubview(line)
        }
    }
}

final class MetricBarView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let track = UIView()
    private let fill = UIView()
    private var fillWidth: NSLayoutConstraint?

    init(title: String, value: String, fraction: Double, tint: UIColor = Palette.terracotta, dark: Bool = false) {
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = Typeface.body(12, weight: .medium)
        titleLabel.textColor = dark ? Palette.paper.withAlphaComponent(0.55) : Palette.inkSoft

        valueLabel.text = value
        valueLabel.font = Typeface.chip(11.5, weight: .semibold)
        valueLabel.textColor = dark ? Palette.paper : Palette.ink
        valueLabel.textAlignment = .right

        let labelRow = UIStackView(axis: .horizontal, spacing: 8, views: [titleLabel, valueLabel])
        labelRow.isHidden = title.isEmpty && value.isEmpty

        track.backgroundColor = dark ? UIColor.white.withAlphaComponent(0.1) : Palette.cream
        track.layer.cornerRadius = 4
        track.clipsToBounds = true
        track.translatesAutoresizingMaskIntoConstraints = false
        track.heightAnchor.constraint(equalToConstant: 8).isActive = true

        fill.backgroundColor = tint
        fill.layer.cornerRadius = 4
        track.addSubview(fill)
        fill.translatesAutoresizingMaskIntoConstraints = false

        let clamped = max(0.02, min(1.0, fraction))
        NSLayoutConstraint.activate([
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor)
        ])
        fillWidth = fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: clamped)
        fillWidth?.isActive = true

        let stack = UIStackView(axis: .vertical, spacing: 7, views: [labelRow, track])
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class ChoicePillRow: UIView {
    let control = UISegmentedControl()
    var onChange: ((Int) -> Void)?

    init(options: [String], selected: Int = 0) {
        super.init(frame: .zero)
        control.removeAllSegments()
        options.enumerated().forEach { index, option in
            control.insertSegment(withTitle: option, at: index, animated: false)
        }
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
        control.addTarget(self, action: #selector(changed), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.heightAnchor.constraint(equalToConstant: 34).isActive = true
        addSubview(control)
        control.pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func changed() {
        onChange?(control.selectedSegmentIndex)
    }
}

final class ToolNoteView: UIView {
    init(text: String) {
        super.init(frame: .zero)
        backgroundColor = Palette.terracotta.withAlphaComponent(0.07)
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous

        let icon = UIImageView(
            image: UIImage(
                systemName: "lightbulb",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            )
        )
        icon.tintColor = Palette.terracotta

        let label = UILabel()
        label.text = text
        label.font = Typeface.body(12)
        label.textColor = Palette.inkSoft
        label.numberOfLines = 0
        label.setLineHeight(3)

        addSubviews(icon, label)
        icon.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            icon.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            icon.widthAnchor.constraint(equalToConstant: 18),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
