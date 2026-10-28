import UIKit

final class BoardFootViewController: ToolPageViewController {
    private let thickness = NumberFieldRow(title: "Thickness", unit: "in")
    private let width = NumberFieldRow(title: "Width", unit: "in")
    private let length = NumberFieldRow(title: "Length", unit: "ft")
    private let quantity = NumberFieldRow(title: "Pieces", unit: "pcs")
    private let price = NumberFieldRow(title: "Price", unit: "$ / bf")
    private let wasteSlider = UISlider()
    private let wasteLabel = UILabel()
    private let result = ToolResultCard()
    private let sketch = BoardSketchView()
    private var waste: Double = 0.1

    init() {
        super.init(
            eyebrow: "Workshop tool 01",
            title: "Board feet,\nno guesswork.",
            intro: "Work out the volume and the real cost of a pile of lumber before you load it into the car.",
            formula: "board feet = T (in) × W (in) × L (in) ÷ 144"
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        thickness.setValue("1")
        width.setValue("8")
        length.setValue("6")
        quantity.setValue("2")
        price.setValue("9.50")

        [thickness, width, length, quantity, price].forEach {
            $0.onChange = { [weak self] in self?.recompute() }
        }

        let dimensionsCard = ToolSectionCard(
            title: "The board",
            subtitle: "Measure the rough stock, not the finished piece."
        )

        let topRow = UIStackView(axis: .horizontal, spacing: 18, distribution: .fillEqually, views: [thickness, width])
        let midRow = UIStackView(axis: .horizontal, spacing: 18, distribution: .fillEqually, views: [length, quantity])
        dimensionsCard.add(topRow)
        dimensionsCard.add(midRow, spacing: 18)
        dimensionsCard.add(makeWasteControl(), spacing: 20)
        dimensionsCard.add(price, spacing: 18)
        addSection(dimensionsCard)

        result.valueLabel.text = "0"
        result.unitLabel.text = "board feet"
        addSection(result)

        let sketchCard = ToolSectionCard(
            title: "What you are buying",
            subtitle: "A quick read of the proportions you entered."
        )
        sketchCard.add(sketch)
        addSection(sketchCard)

        addSection(
            ToolNoteView(
                text: "Add 10–15% for defects, snipe and trimming. If you are milling both faces, take the thickness down by 1/4 in before you calculate the final size."
            )
        )

        recompute()
    }

    private func makeWasteControl() -> UIView {
        wasteLabel.font = Typeface.chip(11.5, weight: .semibold)
        wasteLabel.textColor = Palette.inkSoft
        wasteLabel.text = "Waste allowance · 10%"

        wasteSlider.minimumValue = 0
        wasteSlider.maximumValue = 0.3
        wasteSlider.value = Float(waste)
        wasteSlider.minimumTrackTintColor = Palette.terracotta
        wasteSlider.maximumTrackTintColor = Palette.cream
        wasteSlider.thumbTintColor = Palette.terracotta
        wasteSlider.addTarget(self, action: #selector(wasteChanged), for: .valueChanged)

        let stack = UIStackView(axis: .vertical, spacing: 8, views: [wasteLabel, wasteSlider])
        return stack
    }

    @objc private func wasteChanged() {
        waste = Double(wasteSlider.value)
        wasteLabel.text = "Waste allowance · \(Int((waste * 100).rounded()))%"
        recompute()
    }

    private func recompute() {
        let t = thickness.value ?? 0
        let w = width.value ?? 0
        let l = length.value ?? 0
        let qty = max(1, Int((quantity.value ?? 1).rounded()))
        let unitPrice = price.value ?? 0

        let perPiece = BenchMath.boardFeet(
            thicknessInches: t,
            widthInches: w,
            lengthFeet: l,
            quantity: 1,
            waste: 0
        )
        let total = BenchMath.boardFeet(
            thicknessInches: t,
            widthInches: w,
            lengthFeet: l,
            quantity: qty,
            waste: waste
        )
        let cost = total * unitPrice

        result.valueLabel.text = String(format: "%.2f", total)
        result.unitLabel.text = "board feet"
        result.setDetail(rows: [
            ("Per piece", String(format: "%.2f bf", perPiece)),
            ("Pieces", "\(qty)"),
            ("Waste", "\(Int((waste * 100).rounded()))%"),
            ("Estimated cost", unitPrice > 0 ? String(format: "$%.2f", cost) : "–")
        ])
        sketch.update(widthInches: w, thicknessInches: t, lengthFeet: l, pieces: qty)
    }
}

final class BoardSketchView: UIView {
    private var widthText = "8″ wide"
    private var thicknessText = "1″ thick"
    private var lengthText = "6′ long"
    private var piecesText = "2 pieces"

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 150).isActive = true
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(widthInches: Double, thicknessInches: Double, lengthFeet: Double, pieces: Int) {
        widthText = "\(format(widthInches))″ wide"
        thicknessText = "\(format(thicknessInches))″ thick"
        lengthText = "\(format(lengthFeet))′ long"
        piecesText = "\(pieces) piece\(pieces == 1 ? "" : "s")"
        setNeedsDisplay()
    }

    private func format(_ value: Double) -> String {
        if value == value.rounded() { return String(format: "%.0f", value) }
        return String(format: "%.2f", value)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let plank = CGRect(x: 22, y: 36, width: rect.width - 44, height: 68)

        let edge = UIBezierPath(
            roundedRect: plank.offsetBy(dx: 0, dy: 7),
            cornerRadius: 12
        )
        Palette.walnut.withAlphaComponent(0.12).setFill()
        edge.fill()

        let body = UIBezierPath(roundedRect: plank, cornerRadius: 12)
        body.addClip()
        let colors = [
            UIColor(hex: 0xD7A873).cgColor,
            UIColor(hex: 0xB47A46).cgColor
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: plank.minX, y: plank.minY),
                end: CGPoint(x: plank.maxX, y: plank.maxY),
                options: []
            )
        }

        context.setStrokeColor(UIColor(hex: 0x6A432C, alpha: 0.22).cgColor)
        context.setLineWidth(0.8)
        for index in 0..<10 {
            let y = plank.minY + 6 + CGFloat(index) * 6.2
            let path = UIBezierPath()
            path.move(to: CGPoint(x: plank.minX, y: y))
            path.addCurve(
                to: CGPoint(x: plank.maxX, y: y + CGFloat(index % 3) * 2),
                controlPoint1: CGPoint(x: plank.midX - 40, y: y - 5),
                controlPoint2: CGPoint(x: plank.midX + 50, y: y + 6)
            )
            path.stroke()
        }
        context.resetClip()

        let labelStyle = NSMutableParagraphStyle()
        labelStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Typeface.chip(10, weight: .semibold),
            .foregroundColor: Palette.inkSoft,
            .paragraphStyle: labelStyle
        ]
        let rightAttributes: [NSAttributedString.Key: Any] = [
            .font: Typeface.chip(10, weight: .semibold),
            .foregroundColor: Palette.inkFaint,
            .paragraphStyle: labelStyle
        ]

        widthText.draw(in: CGRect(x: 22, y: 12, width: rect.width - 44, height: 16), withAttributes: attributes)
        thicknessText.draw(in: CGRect(x: 22, y: 112, width: rect.width - 44, height: 16), withAttributes: rightAttributes)
        lengthText.draw(in: CGRect(x: 22, y: 132, width: rect.width - 44, height: 16), withAttributes: rightAttributes)
        piecesText.draw(
            in: CGRect(x: rect.width - 120, y: 12, width: 98, height: 16),
            withAttributes: rightAttributes
        )

        context.setStrokeColor(Palette.brass.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: plank.minX, y: 30))
        context.addLine(to: CGPoint(x: plank.maxX, y: 30))
        context.move(to: CGPoint(x: plank.minX, y: 30))
        context.addLine(to: CGPoint(x: plank.minX, y: 35))
        context.move(to: CGPoint(x: plank.maxX, y: 30))
        context.addLine(to: CGPoint(x: plank.maxX, y: 35))
        context.strokePath()
    }
}
