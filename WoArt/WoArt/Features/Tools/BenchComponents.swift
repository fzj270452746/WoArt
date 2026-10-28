import UIKit

enum BenchPalette {
    static let cutColors: [UIColor] = [
        Palette.terracotta,
        Palette.brass,
        Palette.moss,
        Palette.teal,
        Palette.clay,
        Palette.inkSoft,
        Palette.terracottaDeep,
        Palette.brassLight
    ]

    static func cutColor(_ index: Int) -> UIColor {
        cutColors[index % cutColors.count]
    }
}

// MARK: - Progress

final class BenchProgressBar: UIView {
    private let track = UIView()
    private let fill = UIView()
    private var fillWidth: NSLayoutConstraint?
    private let barHeight: CGFloat

    var progress: CGFloat = 0 {
        didSet { updateFill() }
    }

    init(height: CGFloat = 5, trackColor: UIColor = Palette.paper.withAlphaComponent(0.14), tint: UIColor = Palette.brassLight) {
        barHeight = height
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true

        track.backgroundColor = trackColor
        track.layer.cornerRadius = height / 2
        track.clipsToBounds = true
        addSubview(track)
        track.translatesAutoresizingMaskIntoConstraints = false

        fill.backgroundColor = tint
        fill.layer.cornerRadius = height / 2
        track.addSubview(fill)
        fill.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            track.leadingAnchor.constraint(equalTo: leadingAnchor),
            track.trailingAnchor.constraint(equalTo: trailingAnchor),
            track.topAnchor.constraint(equalTo: topAnchor),
            track.bottomAnchor.constraint(equalTo: bottomAnchor),

            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor)
        ])
        updateFill()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func updateFill() {
        fillWidth?.isActive = false
        let clamped = max(0, min(1, progress))
        fill.isHidden = clamped <= 0.001
        fillWidth = fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: clamped)
        fillWidth?.isActive = true
    }
}

final class BenchProgressRingView: UIView {
    private let trackLayer = CAShapeLayer()
    private let arcLayer = CAShapeLayer()
    private let label = UILabel()
    private let lineWidth: CGFloat

    var progress: CGFloat = 0 {
        didSet { arcLayer.strokeEnd = progress <= 0.001 ? 0 : min(1, progress) }
    }

    var text: String = "" {
        didSet { label.text = text }
    }

    var tint: UIColor = Palette.terracotta {
        didSet {
            arcLayer.strokeColor = tint.cgColor
            label.textColor = tint
        }
    }

    init(diameter: CGFloat = 44, lineWidth: CGFloat = 4) {
        self.lineWidth = lineWidth
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: diameter).isActive = true
        heightAnchor.constraint(equalToConstant: diameter).isActive = true

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = Palette.ink.withAlphaComponent(0.08).cgColor
        trackLayer.lineWidth = lineWidth
        layer.addSublayer(trackLayer)

        arcLayer.fillColor = UIColor.clear.cgColor
        arcLayer.strokeColor = tint.cgColor
        arcLayer.lineWidth = lineWidth
        arcLayer.lineCap = .round
        arcLayer.strokeEnd = 0.001
        layer.addSublayer(arcLayer)

        label.font = Typeface.chip(10, weight: .bold)
        label.textColor = tint
        label.textAlignment = .center
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = lineWidth / 2 + 1
        let rect = bounds.insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(ovalIn: rect).cgPath
        trackLayer.frame = bounds
        arcLayer.frame = bounds
        trackLayer.path = path
        arcLayer.path = path
        if arcLayer.strokeEnd > 0 {
            arcLayer.strokeEnd = max(0.001, min(1, progress))
        }
    }
}

// MARK: - Rows

final class BenchProjectRow: UIControl {
    var onOpen: (() -> Void)?
    private let card = UIView()
    private let ring: BenchProgressRingView

    init(project: BenchProject, metrics: BenchMetrics, isActive: Bool) {
        ring = BenchProgressRingView(diameter: 44, lineWidth: 4)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 102).isActive = true

        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 22
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = isActive ? 1.4 : 1
        card.layer.borderColor = (isActive
            ? Palette.terracotta.withAlphaComponent(0.5)
            : Palette.ink.withAlphaComponent(0.055)).cgColor
        card.applySoftShadow(opacity: isActive ? 0.13 : 0.07, radius: 16, y: 8)
        card.isUserInteractionEnabled = false
        addSubview(card)
        card.pinEdges(to: self)

        let swatch = SpeciesSwatchView(color: UIColor(hex: project.species.swatch), seed: project.species.id)
        swatch.layer.cornerRadius = 13
        swatch.layer.cornerCurve = .continuous
        swatch.clipsToBounds = true
        swatch.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = project.title
        title.font = Typeface.display(19, weight: .semibold)
        title.textColor = Palette.ink
        title.numberOfLines = 1
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.8

        let meta = UILabel()
        var parts = [project.species.name, BenchFormat.count(project.partCount, "part"), BenchFormat.boardFeetText(metrics.netBoardFeet)]
        if isActive { parts.insert("On the bench", at: 0) }
        if metrics.unplacedCount > 0 {
            parts.append("\(metrics.unplacedCount) unplaced")
        }
        meta.text = parts.joined(separator: "  ·  ")
        meta.font = Typeface.body(10.5, weight: .medium)
        meta.textColor = metrics.unplacedCount > 0 ? Palette.terracotta : Palette.inkFaint
        meta.numberOfLines = 1
        meta.adjustsFontSizeToFitWidth = true
        meta.minimumScaleFactor = 0.78

        let textStack = UIStackView(axis: .vertical, spacing: 3, views: [title, meta])

        ring.progress = CGFloat(metrics.progress)
        ring.text = metrics.stepCount > 0 ? "\(metrics.doneSteps)/\(metrics.stepCount)" : "—"
        ring.tint = isActive ? Palette.terracotta : Palette.inkSoft

        let chevron = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
            )
        )
        chevron.tintColor = Palette.inkFaint

        card.addSubviews(swatch, textStack, ring, chevron)
        NSLayoutConstraint.activate([
            swatch.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            swatch.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            swatch.widthAnchor.constraint(equalToConstant: 46),
            swatch.heightAnchor.constraint(equalToConstant: 62),

            textStack.leadingAnchor.constraint(equalTo: swatch.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: ring.leadingAnchor, constant: -10),

            ring.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            ring.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        addTarget(self, action: #selector(pressed), for: .touchDown)
        addTarget(self, action: #selector(released), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() { onOpen?() }

    @objc private func pressed() {
        UIView.animate(withDuration: 0.12) {
            self.transform = CGAffineTransform(scaleX: 0.985, y: 0.985)
        }
    }

    @objc private func released() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.3) {
            self.transform = .identity
        }
    }
}

final class BenchSectionHeading: UIView {
    let actionButton = UIButton(type: .system)

    init(eyebrow: String, title: String, actionTitle: String? = nil) {
        super.init(frame: .zero)

        let eyebrowLabel = EyebrowLabel(eyebrow, color: Palette.terracotta, size: 9)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typeface.display(23, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0

        let textStack = UIStackView(axis: .vertical, spacing: 4, views: [eyebrowLabel, titleLabel])
        addSubview(textStack)
        textStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            textStack.topAnchor.constraint(equalTo: topAnchor),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        if let actionTitle {
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.setTitleColor(Palette.terracotta, for: .normal)
            actionButton.titleLabel?.font = Typeface.chip(12.5, weight: .semibold)
            addSubview(actionButton)
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                actionButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                actionButton.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
                actionButton.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 10)
            ])
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class BenchStatStrip: UIView {
    init(stats: [(value: String, label: String)]) {
        super.init(frame: .zero)
        backgroundColor = Palette.cream.withAlphaComponent(0.55)
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.ink.withAlphaComponent(0.05).cgColor

        let row = UIStackView(axis: .horizontal, spacing: 0, alignment: .fill)
        var columns: [UIStackView] = []
        for (index, stat) in stats.enumerated() {
            if index > 0 {
                let divider = UIView()
                divider.backgroundColor = Palette.ink.withAlphaComponent(0.08)
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
                divider.heightAnchor.constraint(equalToConstant: 26).isActive = true
                let holder = UIView()
                holder.addSubview(divider)
                NSLayoutConstraint.activate([
                    divider.centerXAnchor.constraint(equalTo: holder.centerXAnchor),
                    divider.centerYAnchor.constraint(equalTo: holder.centerYAnchor),
                    holder.widthAnchor.constraint(equalToConstant: 1)
                ])
                row.addArrangedSubview(holder)
            }

            let value = UILabel()
            value.text = stat.value
            value.font = Typeface.display(19, weight: .bold)
            value.textColor = Palette.ink
            value.textAlignment = .center
            value.adjustsFontSizeToFitWidth = true
            value.minimumScaleFactor = 0.7

            let label = UILabel()
            label.text = stat.label.uppercased()
            label.font = Typeface.eyebrow(7.5)
            label.textColor = Palette.inkFaint
            label.textAlignment = .center
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7

            let column = UIStackView(axis: .vertical, spacing: 3, views: [value, label])
            column.alignment = .center
            column.translatesAutoresizingMaskIntoConstraints = false
            columns.append(column)
            row.addArrangedSubview(column)
        }
        for column in columns.dropFirst() {
            column.widthAnchor.constraint(equalTo: columns[0].widthAnchor).isActive = true
        }

        addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.pinEdges(to: self, insets: UIEdgeInsets(top: 11, left: 4, bottom: 10, right: 4))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class BenchStepperRow: UIView {
    private let valueLabel = UILabel()
    private let stepper = UIStepper()
    private(set) var value: Double
    var onChange: ((Double) -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        value: Double,
        minimum: Double,
        maximum: Double,
        step: Double = 1
    ) {
        self.value = value
        super.init(frame: .zero)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typeface.chip(13.5, weight: .semibold)
        titleLabel.textColor = Palette.ink

        var textViews: [UIView] = [titleLabel]
        if let subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.font = Typeface.body(10.5)
            subtitleLabel.textColor = Palette.inkFaint
            subtitleLabel.numberOfLines = 0
            textViews.append(subtitleLabel)
        }
        let textStack = UIStackView(axis: .vertical, spacing: 2, views: textViews)

        valueLabel.text = Self.format(value, step: step)
        valueLabel.font = Typeface.display(18, weight: .semibold)
        valueLabel.textColor = Palette.ink
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        stepper.minimumValue = minimum
        stepper.maximumValue = maximum
        stepper.stepValue = step
        stepper.value = value
        stepper.tintColor = Palette.terracotta
        stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)

        addSubviews(textStack, valueLabel, stepper)
        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: valueLabel.leadingAnchor, constant: -8),

            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -8),

            stepper.trailingAnchor.constraint(equalTo: trailingAnchor),
            stepper.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: subtitle == nil ? 44 : 52)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static func format(_ value: Double, step: Double) -> String {
        if step < 1 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.0f", value)
    }

    @objc private func stepperChanged() {
        value = stepper.value
        valueLabel.text = Self.format(stepper.value, step: stepper.stepValue)
        onChange?(stepper.value)
    }
}

// MARK: - Measure input

final class MeasureFieldView: UIView {
    let textField = UITextField()
    private let titleLabel = UILabel()
    private let unitLabel = UILabel()
    private let line = UIView()
    private let titleText: String
    private let placeholderText: String
    var onChange: (() -> Void)?
    private(set) var unit: BenchUnit

    var valueMM: Double? {
        BenchFormat.parse(textField.text ?? "", unit: unit)
    }

    init(title: String, unit: BenchUnit, placeholder: String = "0") {
        self.titleText = title
        self.unit = unit
        self.placeholderText = placeholder
        super.init(frame: .zero)

        titleLabel.text = title.uppercased()
        titleLabel.font = Typeface.eyebrow(8.5)
        titleLabel.textColor = Palette.inkFaint

        textField.font = Typeface.display(22, weight: .semibold)
        textField.textColor = Palette.ink
        textField.tintColor = Palette.terracotta
        textField.autocorrectionType = .no
        textField.addTarget(self, action: #selector(changed), for: .editingChanged)

        unitLabel.font = Typeface.chip(10, weight: .bold)
        unitLabel.textColor = Palette.inkSoft
        unitLabel.textAlignment = .right
        unitLabel.setContentHuggingPriority(.required, for: .horizontal)

        line.backgroundColor = Palette.ink.withAlphaComponent(0.14)
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 1.2).isActive = true

        addSubviews(titleLabel, textField, unitLabel, line)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.bottomAnchor.constraint(equalTo: line.topAnchor, constant: -4),

            unitLabel.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 6),
            unitLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            unitLabel.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            unitLabel.widthAnchor.constraint(equalToConstant: 24),

            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyUnit()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setValueMM(_ mm: Double) {
        guard mm > 0 else {
            textField.text = ""
            return
        }
        textField.text = BenchFormat.length(mm, unit: unit, withUnit: false, fractionDenominator: 32)
    }

    func setUnit(_ newUnit: BenchUnit) {
        unit = newUnit
        applyUnit()
    }

    private func applyUnit() {
        unitLabel.text = unit == .metric ? "MM" : "IN"
        titleLabel.text = titleText.uppercased()
        textField.keyboardType = unit == .metric ? .decimalPad : .numbersAndPunctuation
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [
                .font: Typeface.display(22, weight: .semibold),
                .foregroundColor: Palette.inkFaint.withAlphaComponent(0.5)
            ]
        )
        textField.inputAccessoryView = makeToolbar()
    }

    private func makeToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        var items: [UIBarButtonItem] = []
        if unit == .imperial {
            items.append(
                UIBarButtonItem(title: "/", style: .plain, target: self, action: #selector(insertSlash))
            )
            items.append(UIBarButtonItem(systemItem: .flexibleSpace))
        } else {
            items.append(UIBarButtonItem(systemItem: .flexibleSpace))
        }
        items.append(
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(finishEditing))
        )
        toolbar.items = items
        toolbar.tintColor = Palette.terracotta
        return toolbar
    }

    @objc private func changed() {
        onChange?()
    }

    @objc private func insertSlash() {
        textField.insertText("/")
        onChange?()
    }

    @objc private func finishEditing() {
        textField.resignFirstResponder()
    }
}

// MARK: - Species row

final class BenchSpeciesRow: UIControl {
    private let swatch = UIView()
    private let nameLabel = UILabel()
    private let botanicalLabel = UILabel()
    var onTap: (() -> Void)?

    init(species: WoodSpecies) {
        super.init(frame: .zero)

        backgroundColor = Palette.cream.withAlphaComponent(0.45)
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.ink.withAlphaComponent(0.06).cgColor

        swatch.layer.cornerRadius = 11
        swatch.layer.cornerCurve = .continuous
        swatch.translatesAutoresizingMaskIntoConstraints = false
        swatch.widthAnchor.constraint(equalToConstant: 38).isActive = true
        swatch.heightAnchor.constraint(equalToConstant: 48).isActive = true

        nameLabel.font = Typeface.display(17, weight: .semibold)
        nameLabel.textColor = Palette.ink
        botanicalLabel.font = Typeface.body(10.5)
        botanicalLabel.textColor = Palette.inkFaint

        let textStack = UIStackView(axis: .vertical, spacing: 1, views: [nameLabel, botanicalLabel])

        let action = UILabel()
        action.text = "CHANGE"
        action.font = Typeface.eyebrow(8.5)
        action.textColor = Palette.terracotta

        swatch.isUserInteractionEnabled = false
        textStack.isUserInteractionEnabled = false
        action.isUserInteractionEnabled = false
        addSubviews(swatch, textStack, action)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 66),
            swatch.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            swatch.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: swatch.trailingAnchor, constant: 11),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: action.leadingAnchor, constant: -8),
            action.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            action.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        update(species: species)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(species: WoodSpecies) {
        swatch.backgroundColor = UIColor(hex: species.swatch)
        nameLabel.text = species.name
        botanicalLabel.text = species.botanical
    }

    @objc private func tapped() {
        Haptics.tap()
        onTap?()
    }
}

// MARK: - Text prompt

final class TextPromptSheetViewController: UIViewController {
    private let dimView = UIView()
    private let sheet = UIView()
    private let field = InputFieldView(title: "Name", placeholder: "")
    private let sheetTitle: String
    private let message: String?
    private let confirmTitle: String
    private let onConfirm: (String) -> Void

    static func present(
        from presenter: UIViewController,
        title: String,
        message: String? = nil,
        fieldTitle: String = "Name",
        placeholder: String = "",
        initialText: String = "",
        confirmTitle: String = "Save",
        onConfirm: @escaping (String) -> Void
    ) {
        let controller = TextPromptSheetViewController(
            title: title,
            message: message,
            fieldTitle: fieldTitle,
            placeholder: placeholder,
            initialText: initialText,
            confirmTitle: confirmTitle,
            onConfirm: onConfirm
        )
        controller.modalPresentationStyle = .overFullScreen
        presenter.present(controller, animated: false)
    }

    private init(
        title: String,
        message: String?,
        fieldTitle: String,
        placeholder: String,
        initialText: String,
        confirmTitle: String,
        onConfirm: @escaping (String) -> Void
    ) {
        sheetTitle = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.onConfirm = onConfirm
        super.init(nibName: nil, bundle: nil)
        field.setTitle(fieldTitle)
        field.textField.text = initialText
        field.textField.placeholder = placeholder
        field.textField.autocapitalizationType = .sentences
        field.textField.returnKeyType = .done
        field.textField.delegate = self
        field.textField.accessibilityLabel = fieldTitle
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        dimView.backgroundColor = Palette.scrim
        dimView.alpha = 0
        view.addSubview(dimView)
        dimView.pinEdges(to: view)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelTapped)))

        sheet.backgroundColor = Palette.card
        sheet.layer.cornerRadius = 34
        sheet.layer.cornerCurve = .continuous
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(sheet)
        sheet.translatesAutoresizingMaskIntoConstraints = false

        let grabber = UIView()
        grabber.backgroundColor = Palette.ink.withAlphaComponent(0.16)
        grabber.layer.cornerRadius = 2.5
        grabber.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = sheetTitle
        titleLabel.font = Typeface.display(24, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0

        var views: [UIView] = [titleLabel]
        if let message {
            let messageLabel = UILabel()
            messageLabel.text = message
            messageLabel.font = Typeface.body(12.5)
            messageLabel.textColor = Palette.inkSoft
            messageLabel.numberOfLines = 0
            views.append(messageLabel)
        }
        views.append(field)

        let confirm = PillButton(title: confirmTitle, style: .dark, height: 50)
        confirm.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        views.append(confirm)

        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.setTitleColor(Palette.inkSoft, for: .normal)
        cancel.titleLabel?.font = Typeface.chip(13.5, weight: .semibold)
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        views.append(cancel)

        let stack = UIStackView(axis: .vertical, spacing: 14, views: views)
        stack.setCustomSpacing(18, after: titleLabel)
        if message != nil { stack.setCustomSpacing(16, after: views[1]) }

        sheet.addSubviews(grabber, stack)
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 10),
            grabber.centerXAnchor.constraint(equalTo: sheet.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 40),
            grabber.heightAnchor.constraint(equalToConstant: 5),

            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stack.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 34),
            stack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 26),
            stack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -26),
            stack.bottomAnchor.constraint(equalTo: sheet.safeAreaLayoutGuide.bottomAnchor, constant: -14)
        ])

        sheet.transform = CGAffineTransform(translationX: 0, y: 420)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3) { self.dimView.alpha = 1 }
        UIView.animate(
            withDuration: 0.46,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.2
        ) {
            self.sheet.transform = .identity
        }
        field.becomeFirstResponder()
    }

    @objc private func cancelTapped() {
        Haptics.tap()
        dismissSheet(then: nil)
    }

    @objc private func confirmTapped() {
        let text = field.text.trimmed
        guard !text.isEmpty else {
            Haptics.warn()
            field.textField.shake()
            return
        }
        Haptics.success()
        dismissSheet(then: text)
    }

    private func dismissSheet(then text: String?) {
        view.endEditing(true)
        UIView.animate(withDuration: 0.24, animations: {
            self.dimView.alpha = 0
            self.sheet.transform = CGAffineTransform(translationX: 0, y: 420)
        }, completion: { _ in
            self.dismiss(animated: false) {
                if let text { self.onConfirm(text) }
            }
        })
    }
}

extension TextPromptSheetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        confirmTapped()
        return false
    }
}

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.36
        animation.values = [-8, 8, -6, 6, -3, 3, 0]
        layer.add(animation, forKey: "shake")
    }
}
