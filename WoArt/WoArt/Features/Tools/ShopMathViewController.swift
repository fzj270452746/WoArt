import UIKit

final class ShopMathViewController: ToolPageViewController {
    // Measure converter
    private let measureField = UITextField()
    private let fractionLabel = UILabel()
    private let fractionCaption = UILabel()
    private let decimalValue = UILabel()
    private let millimetreValue = UILabel()
    private let centimetreValue = UILabel()
    private let tape = TapeMeasureView()

    // Frame angles
    private let miterValue = UILabel()
    private let miterCaption = UILabel()
    private let miterMeta = UILabel()
    private let miterComplement = UILabel()
    private let miterDouble = UILabel()
    private let polygon = PolygonPreviewView()
    private var sides = 4

    // Arch
    private var archUnit: BenchUnit = .metric
    private let archUnitControl = BenchUI.segmented(items: ["mm", "in"], selected: 0)
    private let spanField = MeasureFieldView(title: "Span", unit: .metric)
    private let riseField = MeasureFieldView(title: "Rise", unit: .metric)
    private let archRadiusValue = UILabel()
    private let archRadiusUnit = UILabel()
    private let archArcValue = UILabel()
    private let archAngleValue = UILabel()
    private let archPreview = ArchPreviewView()

    init() {
        super.init(
            eyebrow: "Workshop tool 05",
            title: "Numbers for\nthe bench.",
            intro: "A fraction, a frame angle, an arch that has to fit. The quick answers that usually send you looking for a scrap of paper.",
            formula: "1 in = 25.4 mm · miter = 180° ÷ sides · R = (span² ÷ 4 + rise²) ÷ (2 × rise)"
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        buildConverter()
        buildMiter()
        buildArch()
    }

    // MARK: - Converter

    private func buildConverter() {
        let card = ToolSectionCard(
            title: "Any measure",
            subtitle: "Type a shop fraction, a decimal, or a millimetre value. It reads all three."
        )

        let inputHolder = UIView()
        inputHolder.backgroundColor = Palette.cream.withAlphaComponent(0.45)
        inputHolder.layer.cornerRadius = 14
        inputHolder.layer.cornerCurve = .continuous
        inputHolder.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let rulerIcon = UIImageView(
            image: UIImage(
                systemName: "ruler",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            )
        )
        rulerIcon.tintColor = Palette.inkFaint

        measureField.font = Typeface.display(23, weight: .semibold)
        measureField.textColor = Palette.ink
        measureField.tintColor = Palette.terracotta
        measureField.keyboardType = .numbersAndPunctuation
        measureField.autocorrectionType = .no
        measureField.spellCheckingType = .no
        measureField.placeholder = "1 3/8  ·  1.375  ·  35 mm"
        measureField.addTarget(self, action: #selector(measureChanged), for: .editingChanged)
        measureField.inputAccessoryView = makeMeasureToolbar()

        inputHolder.addSubviews(rulerIcon, measureField)
        NSLayoutConstraint.activate([
            rulerIcon.leadingAnchor.constraint(equalTo: inputHolder.leadingAnchor, constant: 13),
            rulerIcon.centerYAnchor.constraint(equalTo: inputHolder.centerYAnchor),
            measureField.leadingAnchor.constraint(equalTo: rulerIcon.trailingAnchor, constant: 9),
            measureField.trailingAnchor.constraint(equalTo: inputHolder.trailingAnchor, constant: -12),
            measureField.centerYAnchor.constraint(equalTo: inputHolder.centerYAnchor)
        ])
        card.add(inputHolder)

        let chips = UIStackView(axis: .horizontal, spacing: 7, alignment: .center)
        for value in ["1/2", "3/4", "1 1/2", "25 mm", "1.375"] {
            let chip = UIButton(type: .system)
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = Palette.cream
            config.baseForegroundColor = Palette.inkSoft
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9)
            var title = AttributedString(value)
            title.font = Typeface.chip(11, weight: .semibold)
            config.attributedTitle = title
            chip.configuration = config
            chip.addAction(UIAction { [weak self] _ in
                self?.measureField.text = value
                self?.measureChanged()
                Haptics.tap()
            }, for: .touchUpInside)
            chips.addArrangedSubview(chip)
        }
        chips.addArrangedSubview(UIView())
        card.add(chips, spacing: 10)
        card.add(DividerLine(), spacing: 16)

        fractionLabel.text = "0″"
        fractionLabel.font = Typeface.display(34, weight: .bold)
        fractionLabel.textColor = Palette.ink
        fractionLabel.adjustsFontSizeToFitWidth = true
        fractionLabel.minimumScaleFactor = 0.6

        fractionCaption.text = "NEAREST 1/32 INCH"
        fractionCaption.font = Typeface.eyebrow(8)
        fractionCaption.textColor = Palette.inkFaint

        let fractionStack = UIStackView(axis: .vertical, spacing: 2, views: [fractionLabel, fractionCaption])
        card.add(fractionStack, spacing: 12)

        tape.translatesAutoresizingMaskIntoConstraints = false
        tape.heightAnchor.constraint(equalToConstant: 58).isActive = true
        card.add(tape, spacing: 10)

        decimalValue.font = Typeface.chip(11.5, weight: .semibold)
        decimalValue.textColor = Palette.ink
        decimalValue.textAlignment = .right
        millimetreValue.font = Typeface.chip(11.5, weight: .semibold)
        millimetreValue.textColor = Palette.ink
        millimetreValue.textAlignment = .right
        centimetreValue.font = Typeface.chip(11.5, weight: .semibold)
        centimetreValue.textColor = Palette.ink
        centimetreValue.textAlignment = .right

        let details = UIStackView(
            axis: .vertical,
            spacing: 7,
            views: [
                resultLine(title: "Decimal inches", value: decimalValue),
                resultLine(title: "Millimetres", value: millimetreValue),
                resultLine(title: "Centimetres", value: centimetreValue)
            ]
        )
        card.add(details, spacing: 14)

        addSection(card)
        addSection(
            ToolNoteView(
                text: "Bare numbers are read as inches, so “1.375” and “1 3/8” mean the same thing. Add “mm” when you mean millimetres."
            )
        )
        updateConverter()
    }

    private func makeMeasureToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(title: "/", style: .plain, target: self, action: #selector(insertSlash)),
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(finishEditing))
        ]
        toolbar.tintColor = Palette.terracotta
        return toolbar
    }

    @objc private func measureChanged() {
        updateConverter()
    }

    private func updateConverter() {
        let text = measureField.text?.trimmed ?? ""
        guard !text.isEmpty, let parsed = BenchFormat.parseAny(text) else {
            fractionLabel.text = "0″"
            decimalValue.text = "—"
            millimetreValue.text = "—"
            centimetreValue.text = "—"
            tape.valueInches = nil
            return
        }

        let inches = BenchFormat.inches(fromMillimetres: parsed.mm)
        fractionLabel.text = BenchFormat.fraction(inches: inches, denominator: 32) + "″"
        decimalValue.text = String(format: "%.4f″", inches)
        millimetreValue.text = BenchFormat.length(parsed.mm, unit: .metric)
        centimetreValue.text = String(format: "%.2f cm", parsed.mm / 10)
        tape.valueInches = inches
    }

    @objc private func insertSlash() {
        measureField.insertText("/")
        updateConverter()
    }

    @objc private func finishEditing() {
        view.endEditing(true)
    }

    // MARK: - Miter

    private func buildMiter() {
        let card = ToolSectionCard(
            title: "Frame angles",
            subtitle: "For a regular frame, every corner gets the same miter. Set the saw once and repeat it."
        )

        miterValue.font = Typeface.display(38, weight: .bold)
        miterValue.textColor = Palette.ink
        miterValue.text = "45°"

        miterCaption.text = "miter each end"
        miterCaption.font = Typeface.body(11)
        miterCaption.textColor = Palette.inkFaint

        let left = UIStackView(axis: .vertical, spacing: 1, views: [miterValue, miterCaption])

        miterMeta.text = "4 sides"
        miterMeta.font = Typeface.chip(11, weight: .semibold)
        miterMeta.textColor = Palette.terracotta
        miterMeta.textAlignment = .right

        let top = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [left])
        top.addArrangedSubview(UIView())
        top.addArrangedSubview(miterMeta)
        card.add(top, spacing: 4)

        let sidesRow = BenchStepperRow(
            title: "Sides",
            subtitle: "3 to 16. Four is a picture frame.",
            value: 4,
            minimum: 3,
            maximum: 16,
            step: 1
        )
        sidesRow.onChange = { [weak self] value in
            self?.sides = Int(value)
            self?.updateMiter()
        }
        card.add(sidesRow, spacing: 16)

        polygon.translatesAutoresizingMaskIntoConstraints = false
        polygon.heightAnchor.constraint(equalToConstant: 150).isActive = true
        card.add(polygon, spacing: 10)

        miterComplement.font = Typeface.chip(11.5, weight: .semibold)
        miterComplement.textColor = Palette.ink
        miterComplement.textAlignment = .right
        miterDouble.font = Typeface.chip(11.5, weight: .semibold)
        miterDouble.textColor = Palette.ink
        miterDouble.textAlignment = .right

        let details = UIStackView(
            axis: .vertical,
            spacing: 7,
            views: [
                resultLine(title: "Complement to the edge", value: miterComplement),
                resultLine(title: "Two cuts make", value: miterDouble)
            ]
        )
        card.add(details, spacing: 12)

        addSection(card)
        addSection(
            ToolNoteView(
                text: "A miter saw’s scale is measured from the square cut. If your saw reads from the other side, use the complement instead."
            )
        )
        updateMiter()
    }

    private func updateMiter() {
        let miter = 180.0 / Double(max(3, sides))
        miterValue.text = angleText(miter)
        miterMeta.text = "\(sides) sides"
        miterComplement.text = angleText(90 - miter)
        miterDouble.text = angleText(miter * 2)
        polygon.sides = sides
        polygon.miterAngle = miter
    }

    private func angleText(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.05 {
            return String(format: "%.0f°", value)
        }
        return String(format: "%.1f°", value)
    }

    // MARK: - Arch

    private func buildArch() {
        let card = ToolSectionCard(
            title: "Arch layout",
            subtitle: "Give the opening and the rise. The radius and the curved length fall out of the geometry."
        )

        let unitLabel = EyebrowLabel("Units", color: Palette.inkFaint, size: 8.5)
        let unitRow = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, views: [unitLabel])
        unitRow.addArrangedSubview(UIView())
        archUnitControl.widthAnchor.constraint(equalToConstant: 112).isActive = true
        archUnitControl.addTarget(self, action: #selector(archUnitChanged), for: .valueChanged)
        unitRow.addArrangedSubview(archUnitControl)
        card.add(unitRow, spacing: 8)

        spanField.setValueMM(1200)
        riseField.setValueMM(240)
        spanField.onChange = { [weak self] in self?.updateArch() }
        riseField.onChange = { [weak self] in self?.updateArch() }
        card.add(BenchUI.twoColumns(spanField, riseField), spacing: 12)

        archRadiusValue.font = Typeface.display(32, weight: .bold)
        archRadiusValue.textColor = Palette.ink
        archRadiusValue.adjustsFontSizeToFitWidth = true
        archRadiusValue.minimumScaleFactor = 0.6

        archRadiusUnit.font = Typeface.chip(11.5, weight: .bold)
        archRadiusUnit.textColor = Palette.inkSoft

        let radiusRow = UIStackView(axis: .horizontal, spacing: 7, alignment: .lastBaseline, views: [archRadiusValue, archRadiusUnit])
        let radiusCaption = UILabel()
        radiusCaption.text = "radius"
        radiusCaption.font = Typeface.body(11)
        radiusCaption.textColor = Palette.inkFaint
        let radiusStack = UIStackView(axis: .vertical, spacing: 1, views: [radiusRow, radiusCaption])
        card.add(radiusStack, spacing: 14)

        archArcValue.font = Typeface.chip(11.5, weight: .semibold)
        archArcValue.textColor = Palette.ink
        archArcValue.textAlignment = .right
        archAngleValue.font = Typeface.chip(11.5, weight: .semibold)
        archAngleValue.textColor = Palette.ink
        archAngleValue.textAlignment = .right

        let details = UIStackView(
            axis: .vertical,
            spacing: 7,
            views: [
                resultLine(title: "Arc length", value: archArcValue),
                resultLine(title: "Included angle", value: archAngleValue)
            ]
        )
        card.add(details, spacing: 12)

        archPreview.translatesAutoresizingMaskIntoConstraints = false
        archPreview.heightAnchor.constraint(equalToConstant: 168).isActive = true
        card.add(archPreview, spacing: 12)

        addSection(card)
        addSection(
            ToolNoteView(
                text: "Mark the centre point and swing the arc with a trammel. On a shallow arch the radius is very large, so work from the centre instead of trying to draw a template."
            )
        )
        updateArch()
    }

    @objc private func archUnitChanged() {
        let newUnit: BenchUnit = archUnitControl.selectedSegmentIndex == 0 ? .metric : .imperial
        guard newUnit != archUnit else { return }

        let span = BenchFormat.parse(spanField.textField.text ?? "", unit: archUnit) ?? 1200
        let rise = BenchFormat.parse(riseField.textField.text ?? "", unit: archUnit) ?? 240

        archUnit = newUnit
        spanField.setUnit(newUnit)
        riseField.setUnit(newUnit)
        spanField.setValueMM(span)
        riseField.setValueMM(rise)
        updateArch()
    }

    private func updateArch() {
        let span = spanField.valueMM ?? 0
        let rise = riseField.valueMM ?? 0
        archPreview.unit = archUnit

        guard span > 0, rise > 0 else {
            archRadiusValue.text = "—"
            archRadiusUnit.text = ""
            archArcValue.text = "—"
            archAngleValue.text = "—"
            archPreview.spanMM = 0
            archPreview.riseMM = 0
            return
        }

        let radius = (span * span / 4 + rise * rise) / (2 * rise)
        let ratio = min(1, span / (2 * radius))
        let theta = 2 * asin(ratio)
        let arc = radius * theta

        archRadiusValue.text = BenchFormat.length(radius, unit: archUnit, withUnit: false)
        archRadiusUnit.text = archUnit == .metric ? "mm" : "in"
        archArcValue.text = BenchFormat.length(arc, unit: archUnit)
        archAngleValue.text = angleText(theta * 180 / .pi)

        archPreview.spanMM = span
        archPreview.riseMM = rise
        archPreview.setNeedsDisplay()
    }

    // MARK: - Helpers

    private func resultLine(title: String, value: UILabel) -> UIView {
        let key = UILabel()
        key.text = title
        key.font = Typeface.body(11.5)
        key.textColor = Palette.inkSoft
        value.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(axis: .horizontal, spacing: 8, views: [key, UIView(), value])
        return row
    }
}

// MARK: - Tape

private final class TapeMeasureView: UIView {
    var valueInches: Double? {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let left: CGFloat = 4
        let width = rect.width - 8
        let baseline = rect.height - 16
        let rangeInches = 6.0

        context.setStrokeColor(Palette.ink.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(1)
        for index in 0...96 {
            let fraction = Double(index) / 16.0
            let x = left + width * CGFloat(fraction / rangeInches)
            let height: CGFloat = index % 16 == 0 ? 13 : (index % 8 == 0 ? 9 : 5)
            context.move(to: CGPoint(x: x, y: baseline))
            context.addLine(to: CGPoint(x: x, y: baseline - height))
        }
        context.strokePath()

        context.setStrokeColor(Palette.brass.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1.5)
        context.move(to: CGPoint(x: left, y: baseline))
        context.addLine(to: CGPoint(x: left + width, y: baseline))
        context.strokePath()

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: Typeface.eyebrow(7.5),
            .foregroundColor: Palette.inkFaint
        ]
        for inch in 0...6 {
            let x = left + width * CGFloat(Double(inch) / rangeInches)
            let text = "\(inch)"
            let size = text.size(withAttributes: labelAttributes)
            text.draw(at: CGPoint(x: x - size.width / 2, y: baseline + 3), withAttributes: labelAttributes)
        }

        guard let value = valueInches else { return }
        let clamped = max(0, min(rangeInches, value))
        let x = left + width * CGFloat(clamped / rangeInches)
        context.setStrokeColor(Palette.terracotta.cgColor)
        context.setLineWidth(1.8)
        context.move(to: CGPoint(x: x, y: 3))
        context.addLine(to: CGPoint(x: x, y: baseline))
        context.strokePath()

        let triangle = UIBezierPath()
        triangle.move(to: CGPoint(x: x, y: 3))
        triangle.addLine(to: CGPoint(x: x - 4, y: -2))
        triangle.addLine(to: CGPoint(x: x + 4, y: -2))
        triangle.close()
        Palette.terracotta.setFill()
        triangle.fill()
    }
}

// MARK: - Polygon

private final class PolygonPreviewView: UIView {
    var sides: Int = 4 {
        didSet { setNeedsDisplay() }
    }
    var miterAngle: Double = 45 {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.cream.withAlphaComponent(0.35)
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard sides >= 3 else { return }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 24
        let rotation = -CGFloat.pi / 2 + (sides % 2 == 0 ? CGFloat.pi / CGFloat(sides) : 0)
        let path = UIBezierPath()

        var points: [CGPoint] = []
        for index in 0..<sides {
            let angle = rotation + CGFloat(index) * 2 * .pi / CGFloat(sides)
            points.append(
                CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
            )
        }
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.close()

        Palette.card.setFill()
        path.fill()
        Palette.inkSoft.withAlphaComponent(0.65).setStroke()
        path.lineWidth = 1.8
        path.stroke()

        for point in points {
            let dot = UIBezierPath(ovalIn: CGRect(x: point.x - 2.2, y: point.y - 2.2, width: 4.4, height: 4.4))
            Palette.terracotta.setFill()
            dot.fill()
        }

        let angle = miterAngle
        let text = (abs(angle - angle.rounded()) < 0.05
            ? String(format: "%.0f°", angle)
            : String(format: "%.1f°", angle)) + " miter"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Typeface.chip(12, weight: .bold),
            .foregroundColor: Palette.ink
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2),
            withAttributes: attributes
        )
    }
}

// MARK: - Arch

private final class ArchPreviewView: UIView {
    var spanMM: Double = 0 {
        didSet { setNeedsDisplay() }
    }
    var riseMM: Double = 0 {
        didSet { setNeedsDisplay() }
    }
    var unit: BenchUnit = .metric {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.cream.withAlphaComponent(0.32)
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard spanMM > 0, riseMM > 0 else { return }
        let radius = (spanMM * spanMM / 4 + riseMM * riseMM) / (2 * riseMM)
        guard radius.isFinite, radius > 0 else { return }

        let availableWidth = rect.width - 44
        let availableHeight = rect.height - 58
        let scale = min(availableWidth / CGFloat(spanMM), availableHeight / CGFloat(riseMM))
        let chordWidth = CGFloat(spanMM) * scale
        let riseHeight = CGFloat(riseMM) * scale
        let midX = rect.midX
        let chordY = rect.maxY - 26
        let apexY = chordY - riseHeight
        let centerY = chordY + CGFloat(radius - riseMM) * scale
        let theta = 2 * asin(min(1, spanMM / (2 * radius)))

        let arc = UIBezierPath()
        let steps = 90
        for index in 0...steps {
            let t = -theta / 2 + theta * Double(index) / Double(steps)
            let angle = -Double.pi / 2 + t
            let point = CGPoint(
                x: midX + CGFloat(radius * cos(angle)) * scale,
                y: centerY + CGFloat(radius * sin(angle)) * scale
            )
            if index == 0 { arc.move(to: point) } else { arc.addLine(to: point) }
        }
        Palette.terracotta.setStroke()
        arc.lineWidth = 2.4
        arc.lineCapStyle = .round
        arc.stroke()

        let chord = UIBezierPath()
        chord.move(to: CGPoint(x: midX - chordWidth / 2, y: chordY))
        chord.addLine(to: CGPoint(x: midX + chordWidth / 2, y: chordY))
        Palette.brass.withAlphaComponent(0.65).setStroke()
        chord.lineWidth = 1.2
        chord.setLineDash([4, 4], count: 2, phase: 0)
        chord.stroke()

        let riseLine = UIBezierPath()
        riseLine.move(to: CGPoint(x: midX, y: chordY))
        riseLine.addLine(to: CGPoint(x: midX, y: apexY))
        Palette.inkFaint.withAlphaComponent(0.5).setStroke()
        riseLine.lineWidth = 1
        riseLine.setLineDash([3, 4], count: 2, phase: 0)
        riseLine.stroke()

        for point in [
            CGPoint(x: midX - chordWidth / 2, y: chordY),
            CGPoint(x: midX + chordWidth / 2, y: chordY)
        ] {
            let dot = UIBezierPath(ovalIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4))
            Palette.inkSoft.setFill()
            dot.fill()
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: Typeface.eyebrow(7.5),
            .foregroundColor: Palette.inkFaint
        ]
        let spanText = "SPAN " + BenchFormat.length(spanMM, unit: unit)
        let riseText = "RISE " + BenchFormat.length(riseMM, unit: unit)
        let spanSize = spanText.size(withAttributes: attributes)
        let riseSize = riseText.size(withAttributes: attributes)
        spanText.draw(
            at: CGPoint(x: midX - spanSize.width / 2, y: chordY + 7),
            withAttributes: attributes
        )
        riseText.draw(
            at: CGPoint(x: midX + 7, y: apexY + (chordY - apexY) / 2 - riseSize.height / 2),
            withAttributes: attributes
        )
    }
}
