import UIKit

// MARK: - Panel

final class DetailPanel: UIView {
    private let stack = UIStackView()

    init(title: String, info: String? = nil, subtitle: String? = nil) {
        super.init(frame: .zero)
        backgroundColor = Palette.card
        layer.cornerRadius = 26
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.ink.withAlphaComponent(0.055).cgColor
        applySoftShadow(opacity: 0.07, radius: 18, y: 9)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typeface.display(20, weight: .semibold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0

        let header = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [titleLabel])
        header.addArrangedSubview(UIView())
        if let info {
            let infoLabel = UILabel()
            infoLabel.text = info
            infoLabel.font = Typeface.chip(10, weight: .medium)
            infoLabel.textColor = Palette.inkFaint
            infoLabel.textAlignment = .right
            infoLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            header.addArrangedSubview(infoLabel)
        }

        stack.axis = .vertical
        stack.spacing = 14
        stack.addArrangedSubview(header)

        if let subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.font = Typeface.body(11.5)
            subtitleLabel.textColor = Palette.inkSoft
            subtitleLabel.numberOfLines = 0
            subtitleLabel.setLineHeight(3)
            stack.addArrangedSubview(subtitleLabel)
            stack.setCustomSpacing(7, after: header)
        }

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 20, left: 18, bottom: 20, right: 18))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func add(_ view: UIView, spacing: CGFloat = 12) {
        stack.addArrangedSubview(view)
        if stack.arrangedSubviews.count >= 2 {
            stack.setCustomSpacing(spacing, after: stack.arrangedSubviews[stack.arrangedSubviews.count - 2])
        }
    }
}

final class DetailAddRow: UIControl {
    private let action: () -> Void

    init(title: String, action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 42).isActive = true

        let plus = UIImageView(
            image: UIImage(
                systemName: "plus",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
            )
        )
        plus.tintColor = Palette.terracotta

        let label = UILabel()
        label.text = title
        label.font = Typeface.chip(12.5, weight: .semibold)
        label.textColor = Palette.terracotta

        plus.isUserInteractionEnabled = false
        label.isUserInteractionEnabled = false
        addSubviews(plus, label)
        NSLayoutConstraint.activate([
            plus.leadingAnchor.constraint(equalTo: leadingAnchor),
            plus.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: plus.trailingAnchor, constant: 7),
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

// MARK: - Part row

final class PartRow: UIControl {
    var onOpen: (() -> Void)?

    init(part: ProjectPart, project: BenchProject, colorIndex: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 64).isActive = true

        let dot = UIView()
        dot.backgroundColor = BenchPalette.cutColor(colorIndex)
        dot.layer.cornerRadius = 2.5
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 8).isActive = true

        let name = UILabel()
        name.text = part.name
        name.font = Typeface.chip(14, weight: .semibold)
        name.textColor = Palette.ink
        name.numberOfLines = 1

        let summary = UILabel()
        let materialSuffix = part.material == .plywood ? "  ·  Plywood" : ""
        summary.text = project.partSummary(part) + materialSuffix
        summary.font = Typeface.body(10.5)
        summary.textColor = Palette.inkFaint
        summary.numberOfLines = 1
        summary.adjustsFontSizeToFitWidth = true
        summary.minimumScaleFactor = 0.8

        let chevron = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
            )
        )
        chevron.tintColor = Palette.inkFaint

        dot.isUserInteractionEnabled = false
        name.isUserInteractionEnabled = false
        summary.isUserInteractionEnabled = false
        chevron.isUserInteractionEnabled = false
        addSubviews(dot, name, summary, chevron)
        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: leadingAnchor),
            dot.topAnchor.constraint(equalTo: topAnchor, constant: 9),

            name.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 10),
            name.topAnchor.constraint(equalTo: topAnchor),
            name.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

            summary.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            summary.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 3),
            summary.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        addTarget(self, action: #selector(pressed), for: .touchDown)
        addTarget(self, action: #selector(released), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() { onOpen?() }

    @objc private func pressed() {
        UIView.animate(withDuration: 0.1) { self.alpha = 0.55 }
    }

    @objc private func released() {
        UIView.animate(withDuration: 0.18) { self.alpha = 1 }
    }
}

// MARK: - Stock row

final class StockRow: UIControl {
    var onOpen: (() -> Void)?

    init(stock: StockBoard, project: BenchProject) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 64).isActive = true

        let bar = UIView()
        bar.backgroundColor = stock.material == .plywood
            ? Palette.sand
            : UIColor(hex: project.species.swatch).withAlphaComponent(0.6)
        bar.layer.cornerRadius = 2.5
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.widthAnchor.constraint(equalToConstant: 8).isActive = true
        bar.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let name = UILabel()
        name.text = stock.label
        name.font = Typeface.chip(14, weight: .semibold)
        name.textColor = Palette.ink
        name.numberOfLines = 1

        let dims = UILabel()
        var text = BenchFormat.stockDimensions(
            thicknessMM: stock.thicknessMM,
            widthMM: stock.widthMM,
            lengthMM: stock.lengthMM,
            unit: project.unit
        ) + "  ·  ×\(max(1, stock.quantity))"
        if stock.pricePerBoardFoot > 0 {
            text += String(format: "  ·  $%.2f/bf", stock.pricePerBoardFoot)
        }
        dims.text = text
        dims.font = Typeface.body(10.5)
        dims.textColor = Palette.inkFaint
        dims.numberOfLines = 1
        dims.adjustsFontSizeToFitWidth = true
        dims.minimumScaleFactor = 0.75

        let chevron = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
            )
        )
        chevron.tintColor = Palette.inkFaint

        bar.isUserInteractionEnabled = false
        name.isUserInteractionEnabled = false
        dims.isUserInteractionEnabled = false
        chevron.isUserInteractionEnabled = false
        addSubviews(bar, name, dims, chevron)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.centerYAnchor.constraint(equalTo: centerYAnchor),

            name.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: 12),
            name.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            name.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

            dims.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            dims.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 3),
            dims.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        addTarget(self, action: #selector(pressed), for: .touchDown)
        addTarget(self, action: #selector(released), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() { onOpen?() }

    @objc private func pressed() {
        UIView.animate(withDuration: 0.1) { self.alpha = 0.55 }
    }

    @objc private func released() {
        UIView.animate(withDuration: 0.18) { self.alpha = 1 }
    }
}

// MARK: - Shopping row

final class ShoppingRow: UIView {
    init(summary: BenchPlan.StockSummary, project: BenchProject) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let name = UILabel()
        name.text = summary.label
        name.font = Typeface.chip(13.5, weight: .semibold)
        name.textColor = Palette.ink

        var subParts = [
            summary.dimensionText,
            "need \(summary.needed)",
            "have \(summary.available)"
        ]
        if summary.pricePerBoardFoot > 0 {
            subParts.append(String(format: "$%.2f/bf", summary.pricePerBoardFoot))
        }
        let sub = UILabel()
        sub.text = subParts.joined(separator: "  ·  ")
        sub.font = Typeface.body(10)
        sub.textColor = Palette.inkFaint
        sub.numberOfLines = 1
        sub.adjustsFontSizeToFitWidth = true
        sub.minimumScaleFactor = 0.75

        let left = UIStackView(axis: .vertical, spacing: 2, views: [name, sub])

        let status = UILabel()
        status.text = summary.extra > 0 ? "BUY \(summary.extra)" : "ON HAND"
        status.font = Typeface.eyebrow(8)
        status.textColor = summary.extra > 0 ? Palette.terracotta : Palette.moss
        status.textAlignment = .right

        let cost = UILabel()
        if let value = summary.costToBuy {
            cost.text = String(format: "$%.2f", value)
        } else {
            cost.text = summary.extra > 0 ? "—" : "Covered"
        }
        cost.font = Typeface.chip(10.5, weight: .semibold)
        cost.textColor = Palette.inkSoft
        cost.textAlignment = .right

        let right = UIStackView(axis: .vertical, spacing: 2, alignment: .trailing, views: [status, cost])

        addSubviews(left, right)
        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: leadingAnchor),
            left.centerYAnchor.constraint(equalTo: centerYAnchor),
            left.trailingAnchor.constraint(lessThanOrEqualTo: right.leadingAnchor, constant: -10),
            right.trailingAnchor.constraint(equalTo: trailingAnchor),
            right.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 54)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Board diagram

final class BenchBoardView: UIView {
    init(board: BenchPlan.Board, index: Int, project: BenchProject) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let eyebrow = UILabel()
        eyebrow.text = String(format: "BOARD %02d", index + 1)
        eyebrow.font = Typeface.eyebrow(8.5)
        eyebrow.textColor = Palette.inkFaint

        let stockLabel = UILabel()
        stockLabel.text = board.stockLabel
        stockLabel.font = Typeface.chip(9.5, weight: .medium)
        stockLabel.textColor = Palette.inkFaint

        let count = UILabel()
        count.text = "\(board.partCount) parts"
        count.font = Typeface.chip(9.5, weight: .medium)
        count.textColor = Palette.inkFaint
        count.textAlignment = .right

        let header = UIStackView(axis: .horizontal, spacing: 7, alignment: .center, views: [eyebrow, stockLabel])
        header.addArrangedSubview(UIView())
        header.addArrangedSubview(count)

        let diagram = BenchBoardDiagramView(
            board: board,
            trim: project.trimMM,
            kerf: project.kerfMM
        )
        diagram.translatesAutoresizingMaskIntoConstraints = false
        diagram.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let legend = UILabel()
        legend.numberOfLines = 2
        var seen: [Int: String] = [:]
        for strip in board.strips {
            for part in strip.parts {
                seen[part.colorIndex] = part.name
            }
        }
        let attributed = NSMutableAttributedString()
        for colorIndex in seen.keys.sorted() {
            attributed.append(
                NSAttributedString(
                    string: "● ",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 9, weight: .bold),
                        .foregroundColor: BenchPalette.cutColor(colorIndex)
                    ]
                )
            )
            attributed.append(
                NSAttributedString(
                    string: "\(seen[colorIndex] ?? "Part")   ",
                    attributes: [
                        .font: Typeface.body(9.5, weight: .medium),
                        .foregroundColor: Palette.inkSoft
                    ]
                )
            )
        }
        legend.attributedText = attributed

        let stack = UIStackView(axis: .vertical, spacing: 7, views: [header, diagram, legend])
        stack.setCustomSpacing(3, after: diagram)
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class BenchBoardDiagramView: UIView {
    private let board: BenchPlan.Board
    private let trim: Double
    private let kerf: Double

    init(board: BenchPlan.Board, trim: Double, kerf: Double) {
        self.board = board
        self.trim = trim
        self.kerf = kerf
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard board.widthMM > 0, board.lengthMM > 0 else { return }
        let inset: CGFloat = 1
        let area = rect.insetBy(dx: inset, dy: inset)

        let background = UIBezierPath(roundedRect: area, cornerRadius: 8)
        Palette.sand.withAlphaComponent(0.4).setFill()
        background.fill()

        let scaleX = area.width / CGFloat(board.lengthMM)
        let scaleY = area.height / CGFloat(board.widthMM)
        let trimX = CGFloat(trim) * scaleX

        var y: CGFloat = 0
        for strip in board.strips {
            let stripHeight = CGFloat(strip.widthMM) * scaleY
            var x = area.minX + trimX
            for part in strip.parts {
                let width = CGFloat(part.lengthMM) * scaleX
                let segment = CGRect(
                    x: x,
                    y: area.minY + y + 0.7,
                    width: max(0, width - 0.8),
                    height: max(1.5, stripHeight - 1.4)
                )
                let path = UIBezierPath(roundedRect: segment, cornerRadius: min(3, stripHeight / 3))
                BenchPalette.cutColor(part.colorIndex).withAlphaComponent(0.9).setFill()
                path.fill()

                if width > 17, stripHeight > 12 {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .center
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.monospacedSystemFont(ofSize: 7, weight: .bold),
                        .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                        .paragraphStyle: style
                    ]
                    "\(part.colorIndex + 1)".draw(
                        in: CGRect(
                            x: x,
                            y: area.minY + y + (stripHeight - 8) / 2,
                            width: width,
                            height: 9
                        ),
                        withAttributes: attributes
                    )
                }
                x += (CGFloat(part.lengthMM) + CGFloat(kerf)) * scaleX
            }
            y += (CGFloat(strip.widthMM) + CGFloat(kerf)) * scaleY
        }

        let outline = UIBezierPath(
            roundedRect: area.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: 8
        )
        Palette.ink.withAlphaComponent(0.07).setStroke()
        outline.lineWidth = 1
        outline.stroke()

        if trimX > 0 {
            let trimPath = UIBezierPath()
            trimPath.move(to: CGPoint(x: area.minX + trimX, y: area.minY))
            trimPath.addLine(to: CGPoint(x: area.minX + trimX, y: area.maxY))
            trimPath.move(to: CGPoint(x: area.maxX - trimX, y: area.minY))
            trimPath.addLine(to: CGPoint(x: area.maxX - trimX, y: area.maxY))
            Palette.brass.withAlphaComponent(0.35).setStroke()
            trimPath.lineWidth = 0.8
            trimPath.stroke()
        }
    }
}

// MARK: - Movement row

final class MovementRowView: UIView {
    init(row: BenchMovement.Row, unit: BenchUnit) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let name = UILabel()
        name.text = row.name
        name.font = Typeface.chip(13.5, weight: .semibold)
        name.textColor = Palette.ink

        let detail = UILabel()
        if row.isStable {
            detail.text = row.material == .plywood ? "Plywood · stable" : "No grain movement"
        } else {
            detail.text = "\(row.axis) \(BenchFormat.length(row.dimensionMM, unit: unit))  ·  across grain"
        }
        detail.font = Typeface.body(10)
        detail.textColor = Palette.inkFaint
        detail.numberOfLines = 1
        detail.adjustsFontSizeToFitWidth = true
        detail.minimumScaleFactor = 0.8

        let left = UIStackView(axis: .vertical, spacing: 2, views: [name, detail])

        let movement = UILabel()
        let cut = UILabel()
        if row.isStable {
            movement.text = "—"
            movement.textColor = Palette.inkFaint
            cut.text = "Cut to finished size"
            cut.textColor = Palette.inkFaint
        } else {
            movement.text = BenchFormat.movement(row.movementMM, unit: unit)
            movement.textColor = row.exceeds ? Palette.terracotta : Palette.inkSoft
            cut.text = "Cut to \(BenchFormat.length(row.cutToMM, unit: unit))"
            cut.textColor = Palette.inkFaint
        }
        movement.font = Typeface.chip(12, weight: .bold)
        movement.textAlignment = .right
        cut.font = Typeface.body(9.5)
        cut.textAlignment = .right

        let right = UIStackView(axis: .vertical, spacing: 2, alignment: .trailing, views: [movement, cut])

        addSubviews(left, right)
        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: leadingAnchor),
            left.centerYAnchor.constraint(equalTo: centerYAnchor),
            left.trailingAnchor.constraint(lessThanOrEqualTo: right.leadingAnchor, constant: -10),
            right.trailingAnchor.constraint(equalTo: trailingAnchor),
            right.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 54)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Build step row

final class BuildStepRow: UIControl {
    var onToggle: (() -> Void)?
    var onMenu: (() -> Void)?

    private let circle = UIView()
    private let check = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()

    init(index: Int, step: ProjectStep) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let number = UILabel()
        number.text = String(format: "%02d", index + 1)
        number.font = Typeface.eyebrow(7.5)
        number.textColor = Palette.inkFaint

        circle.layer.cornerRadius = 13
        circle.layer.borderWidth = 1.4
        circle.layer.borderColor = Palette.inkFaint.withAlphaComponent(0.55).cgColor
        circle.backgroundColor = step.isDone ? Palette.terracotta : .clear
        circle.layer.borderColor = step.isDone ? UIColor.clear.cgColor : Palette.inkFaint.withAlphaComponent(0.55).cgColor
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 26).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 26).isActive = true

        check.image = UIImage(
            systemName: "checkmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        )
        check.tintColor = .white
        check.isHidden = !step.isDone
        circle.addSubview(check)
        check.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            check.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: circle.centerYAnchor)
        ])

        titleLabel.text = step.title
        titleLabel.font = Typeface.chip(14, weight: .semibold)
        titleLabel.textColor = step.isDone ? Palette.inkFaint : Palette.ink
        titleLabel.numberOfLines = 0
        if step.isDone {
            titleLabel.attributedText = NSAttributedString(
                string: step.title,
                attributes: [
                    .font: Typeface.chip(14, weight: .semibold),
                    .foregroundColor: Palette.inkFaint,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: Palette.inkFaint
                ]
            )
        }

        detailLabel.text = step.detail
        detailLabel.font = Typeface.body(10.5)
        detailLabel.textColor = Palette.inkFaint
        detailLabel.numberOfLines = 2
        detailLabel.isHidden = step.detail.trimmed.isEmpty
        if step.isDone { detailLabel.alpha = 0.6 }

        let textStack = UIStackView(axis: .vertical, spacing: 3, views: [number, titleLabel, detailLabel])
        textStack.setCustomSpacing(2, after: number)

        let menu = UIButton(type: .system)
        menu.setImage(
            UIImage(
                systemName: "ellipsis",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            ),
            for: .normal
        )
        menu.tintColor = Palette.inkFaint
        menu.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        menu.translatesAutoresizingMaskIntoConstraints = false

        circle.isUserInteractionEnabled = false
        textStack.isUserInteractionEnabled = false
        addSubviews(circle, textStack, menu)
        NSLayoutConstraint.activate([
            circle.leadingAnchor.constraint(equalTo: leadingAnchor),
            circle.topAnchor.constraint(equalTo: topAnchor, constant: 12),

            textStack.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 11),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: menu.leadingAnchor, constant: -4),

            menu.trailingAnchor.constraint(equalTo: trailingAnchor),
            menu.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            menu.widthAnchor.constraint(equalToConstant: 30),
            menu.heightAnchor.constraint(equalToConstant: 30),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 58)
        ])

        addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func toggleTapped() { onToggle?() }

    @objc private func menuTapped() { onMenu?() }
}

// MARK: - Humidity slider

final class RHSliderRow: UIView {
    let slider = UISlider()
    private let valueLabel = UILabel()
    var onChange: ((Double) -> Void)?

    init(title: String, value: Double) {
        super.init(frame: .zero)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typeface.chip(12.5, weight: .semibold)
        titleLabel.textColor = Palette.ink

        valueLabel.text = "\(Int(value.rounded()))%"
        valueLabel.font = Typeface.chip(11.5, weight: .bold)
        valueLabel.textColor = Palette.terracotta
        valueLabel.textAlignment = .right

        let top = UIStackView(axis: .horizontal, spacing: 8, views: [titleLabel])
        top.addArrangedSubview(UIView())
        top.addArrangedSubview(valueLabel)

        slider.minimumValue = 20
        slider.maximumValue = 80
        slider.value = Float(value)
        slider.minimumTrackTintColor = Palette.terracotta
        slider.maximumTrackTintColor = Palette.cream
        slider.thumbTintColor = Palette.terracotta
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        let stack = UIStackView(axis: .vertical, spacing: 4, views: [top, slider])
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self)
        heightAnchor.constraint(equalToConstant: 54).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func sliderChanged() {
        valueLabel.text = "\(Int(slider.value.rounded()))%"
        onChange?(Double(slider.value))
    }
}

// MARK: - Unplaced warning

final class BenchUnplacedCard: UIView {
    init(plan: BenchPlan) {
        super.init(frame: .zero)
        backgroundColor = Palette.terracotta.withAlphaComponent(0.08)
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous

        let icon = UIImageView(
            image: UIImage(
                systemName: "exclamationmark.triangle",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            )
        )
        icon.tintColor = Palette.terracotta
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let title = UILabel()
        title.text = "Not on the plan"
        title.font = Typeface.chip(12.5, weight: .semibold)
        title.textColor = Palette.terracottaDeep

        let titleRow = UIStackView(axis: .horizontal, spacing: 7, alignment: .center, views: [icon, title])

        let body = UILabel()
        body.text = plan.unplaced.map { "\($0.quantity) × \($0.name) — \($0.reason)" }.joined(separator: "\n")
        body.font = Typeface.body(11)
        body.textColor = Palette.inkSoft
        body.numberOfLines = 0
        body.setLineHeight(3)

        let hint = UILabel()
        hint.text = "Adjust the part, or add stock that can yield it."
        hint.font = Typeface.body(10.5)
        hint.textColor = Palette.inkFaint
        hint.numberOfLines = 0

        let stack = UIStackView(axis: .vertical, spacing: 7, views: [titleRow, body, hint])
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 14, left: 15, bottom: 14, right: 15))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
