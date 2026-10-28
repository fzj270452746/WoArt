import UIKit

final class StockFormViewController: BenchFormViewController {
    var onSaved: ((StockBoard) -> Void)?
    var onDeleted: (() -> Void)?

    private let isNew: Bool
    private var stock: StockBoard
    private var unit: BenchUnit

    private let labelField = InputFieldView(title: "Stock name", placeholder: "e.g. Walnut boards")
    private let unitControl: UISegmentedControl
    private let thicknessField: MeasureFieldView
    private let widthField: MeasureFieldView
    private let lengthField: MeasureFieldView
    private let quantityRow: BenchStepperRow
    private let materialControl: UISegmentedControl
    private let priceField = InputFieldView(
        title: "Price per board foot ($)",
        placeholder: "0.00",
        keyboard: .decimalPad
    )
    private var thicknessMM: Double
    private var widthMM: Double
    private var lengthMM: Double
    private var thicknessEdited = false
    private var widthEdited = false
    private var lengthEdited = false

    init(project: BenchProject, stock: StockBoard, isNew: Bool) {
        self.stock = stock
        self.isNew = isNew
        self.unit = project.unit
        self.thicknessMM = stock.thicknessMM
        self.widthMM = stock.widthMM
        self.lengthMM = stock.lengthMM
        unitControl = BenchUI.segmented(items: ["mm", "in"], selected: project.unit == .metric ? 0 : 1)
        thicknessField = MeasureFieldView(title: "Thickness", unit: project.unit)
        widthField = MeasureFieldView(title: "Width", unit: project.unit)
        lengthField = MeasureFieldView(title: "Length", unit: project.unit)
        quantityRow = BenchStepperRow(
            title: "Boards on hand",
            subtitle: "How many boards of this size you already have.",
            value: Double(max(1, stock.quantity)),
            minimum: 1,
            maximum: 99
        )
        materialControl = BenchUI.segmented(
            items: ["Solid", "Plywood"],
            selected: stock.material == .solid ? 0 : 1
        )
        super.init(
            eyebrow: isNew ? "New stock" : "Stock",
            title: isNew ? "Add a board." : "Edit the stock.",
            subtitle: "Enter the sizes you can actually buy. The cut plan rips strips across the width, then cross-cuts along the length.",
            saveTitle: "Save stock"
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildFields() {
        labelField.textField.text = stock.label
        contentStack.addArrangedSubview(labelField)

        unitControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)
        contentStack.addArrangedSubview(BenchUI.labeled("Units", unitControl))

        thicknessField.setValueMM(thicknessMM)
        widthField.setValueMM(widthMM)
        lengthField.setValueMM(lengthMM)
        thicknessField.onChange = { [weak self] in
            guard let self, let value = self.thicknessField.valueMM else { return }
            self.thicknessMM = value
            self.thicknessEdited = true
        }
        widthField.onChange = { [weak self] in
            guard let self, let value = self.widthField.valueMM else { return }
            self.widthMM = value
            self.widthEdited = true
        }
        lengthField.onChange = { [weak self] in
            guard let self, let value = self.lengthField.valueMM else { return }
            self.lengthMM = value
            self.lengthEdited = true
        }
        contentStack.addArrangedSubview(BenchUI.twoColumns(thicknessField, widthField))
        contentStack.addArrangedSubview(lengthField)

        contentStack.addArrangedSubview(quantityRow)

        materialControl.addTarget(self, action: #selector(materialChanged), for: .valueChanged)
        contentStack.addArrangedSubview(BenchUI.labeled("Material", materialControl))

        if stock.pricePerBoardFoot > 0 {
            priceField.textField.text = String(format: "%.2f", stock.pricePerBoardFoot)
        }
        contentStack.addArrangedSubview(priceField)

        let priceNote = UILabel()
        priceNote.text = "Price per board foot is optional. Leave it blank to plan board feet without a cost estimate. For sheet goods, a board-foot price is unusual — leave it blank if you prefer."
        priceNote.font = Typeface.body(10.5)
        priceNote.textColor = Palette.inkFaint
        priceNote.numberOfLines = 0
        priceNote.setLineHeight(3)
        contentStack.addArrangedSubview(priceNote)

        contentStack.addArrangedSubview(
            ToolNoteView(
                text: "The planner uses the thinnest, narrowest board that can still yield each part. Add wide and thick stock only when the parts need it."
            )
        )

        if !isNew {
            let delete = PillButton(title: "Delete stock", style: .destructive, height: 46)
            delete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
            contentStack.addArrangedSubview(delete)
        }
    }

    @objc private func materialChanged() {}

    @objc private func unitChanged() {
        let newUnit: BenchUnit = unitControl.selectedSegmentIndex == 0 ? .metric : .imperial
        guard newUnit != unit else { return }

        unit = newUnit
        [thicknessField, widthField, lengthField].forEach { $0.setUnit(newUnit) }
        thicknessField.setValueMM(thicknessMM)
        widthField.setValueMM(widthMM)
        lengthField.setValueMM(lengthMM)
        thicknessEdited = false
        widthEdited = false
        lengthEdited = false
    }

    override func saveTapped() {
        let thicknessValue = thicknessEdited ? thicknessField.valueMM : thicknessMM
        let widthValue = widthEdited ? widthField.valueMM : widthMM
        let lengthValue = lengthEdited ? lengthField.valueMM : lengthMM
        guard
            let thickness = thicknessValue, thickness > 0,
            let width = widthValue, width > 0,
            let length = lengthValue, length > 0
        else {
            Haptics.warn()
            showToast("Enter a thickness, width and length.", icon: "exclamationmark")
            return
        }

        var updated = stock
        let name = labelField.text.trimmed
        updated.label = name.isEmpty ? "Stock" : name
        updated.thicknessMM = thickness
        updated.widthMM = width
        updated.lengthMM = length
        updated.quantity = max(1, Int(quantityRow.value))
        updated.material = materialControl.selectedSegmentIndex == 0 ? .solid : .plywood
        let priceText = priceField.text.replacingOccurrences(of: ",", with: ".")
        updated.pricePerBoardFoot = max(0, Double(priceText) ?? 0)

        Haptics.success()
        onSaved?(updated)
        dismiss(animated: true)
    }

    @objc private func deleteTapped() {
        Haptics.tap()
        ConfirmSheetViewController.present(
            from: self,
            title: "Delete this stock?",
            message: "The cut plan will be rebuilt using the remaining boards.",
            confirmTitle: "Delete stock",
            destructive: true
        ) { [weak self] in
            self?.onDeleted?()
            self?.dismiss(animated: true)
        }
    }
}
