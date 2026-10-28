import UIKit

final class PartFormViewController: BenchFormViewController {
    var onSaved: ((ProjectPart) -> Void)?
    var onDeleted: (() -> Void)?

    private let isNew: Bool
    private var part: ProjectPart
    private var unit: BenchUnit

    private let nameField = InputFieldView(title: "Part name", placeholder: "e.g. Front leg")
    private let unitControl: UISegmentedControl
    private let lengthField: MeasureFieldView
    private let widthField: MeasureFieldView
    private let thicknessField: MeasureFieldView
    private let quantityRow: BenchStepperRow
    private let materialControl: UISegmentedControl
    private let grainControl: UISegmentedControl
    private var lengthMM: Double
    private var widthMM: Double
    private var thicknessMM: Double
    private var lengthEdited = false
    private var widthEdited = false
    private var thicknessEdited = false

    init(project: BenchProject, part: ProjectPart, isNew: Bool) {
        self.part = part
        self.isNew = isNew
        self.unit = project.unit
        self.lengthMM = part.lengthMM
        self.widthMM = part.widthMM
        self.thicknessMM = part.thicknessMM
        let startUnit = project.unit
        unitControl = BenchUI.segmented(
            items: ["mm", "in"],
            selected: startUnit == .metric ? 0 : 1
        )
        lengthField = MeasureFieldView(title: "Length", unit: startUnit)
        widthField = MeasureFieldView(title: "Width", unit: startUnit)
        thicknessField = MeasureFieldView(title: "Thickness", unit: startUnit)
        quantityRow = BenchStepperRow(
            title: "Quantity",
            subtitle: "Pieces of this exact size.",
            value: Double(max(1, part.quantity)),
            minimum: 1,
            maximum: 99
        )
        materialControl = BenchUI.segmented(
            items: ["Solid", "Plywood"],
            selected: part.material == .solid ? 0 : 1
        )
        let grainIndex: Int
        switch part.grain {
        case .alongLength: grainIndex = 0
        case .acrossWidth: grainIndex = 1
        case .none: grainIndex = 2
        }
        grainControl = BenchUI.segmented(
            items: ["Length", "Width", "None"],
            selected: grainIndex
        )
        super.init(
            eyebrow: isNew ? "New part" : "Part",
            title: isNew ? "Cut a part." : "Edit the part.",
            subtitle: "Length, width and thickness are the finished sizes. The cut plan allows for the saw kerf and the ends separately.",
            saveTitle: "Save part"
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildFields() {
        nameField.textField.text = part.name
        contentStack.addArrangedSubview(nameField)

        unitControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)
        contentStack.addArrangedSubview(BenchUI.labeled("Units", unitControl))

        lengthField.setValueMM(lengthMM)
        widthField.setValueMM(widthMM)
        thicknessField.setValueMM(thicknessMM)
        lengthField.onChange = { [weak self] in
            guard let self, let value = self.lengthField.valueMM else { return }
            self.lengthMM = value
            self.lengthEdited = true
        }
        widthField.onChange = { [weak self] in
            guard let self, let value = self.widthField.valueMM else { return }
            self.widthMM = value
            self.widthEdited = true
        }
        thicknessField.onChange = { [weak self] in
            guard let self, let value = self.thicknessField.valueMM else { return }
            self.thicknessMM = value
            self.thicknessEdited = true
        }

        contentStack.addArrangedSubview(BenchUI.twoColumns(lengthField, widthField))
        contentStack.addArrangedSubview(thicknessField)

        contentStack.addArrangedSubview(quantityRow)

        materialControl.addTarget(self, action: #selector(materialChanged), for: .valueChanged)
        contentStack.addArrangedSubview(BenchUI.labeled("Material", materialControl))

        grainControl.addTarget(self, action: #selector(grainChanged), for: .valueChanged)
        contentStack.addArrangedSubview(BenchUI.labeled("Grain direction", grainControl))
        updateGrainAvailability()

        let grainNote = UILabel()
        grainNote.text = "Grain runs along the length on most rails, legs and boards. Set it to Width when the part is cut across the grain — the movement calculator uses this."
        grainNote.font = Typeface.body(11)
        grainNote.textColor = Palette.inkFaint
        grainNote.numberOfLines = 0
        grainNote.setLineHeight(3)
        contentStack.addArrangedSubview(grainNote)

        contentStack.addArrangedSubview(
            ToolNoteView(
                text: "The part list is the source for everything else: board feet, the cut plan and the seasonal movement allowance."
            )
        )

        if !isNew {
            let delete = PillButton(title: "Delete part", style: .destructive, height: 46)
            delete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
            contentStack.addArrangedSubview(delete)
            contentStack.setCustomSpacing(20, after: contentStack.arrangedSubviews[contentStack.arrangedSubviews.count - 2])
        }
    }

    private func updateGrainAvailability() {
        let solid = materialControl.selectedSegmentIndex == 0
        grainControl.isEnabled = solid
        grainControl.alpha = solid ? 1 : 0.45
        if !solid { grainControl.selectedSegmentIndex = 2 }
    }

    @objc private func materialChanged() {
        updateGrainAvailability()
    }

    @objc private func grainChanged() {}

    @objc private func unitChanged() {
        let newUnit: BenchUnit = unitControl.selectedSegmentIndex == 0 ? .metric : .imperial
        guard newUnit != unit else { return }

        unit = newUnit
        [lengthField, widthField, thicknessField].forEach { $0.setUnit(newUnit) }
        lengthField.setValueMM(lengthMM)
        widthField.setValueMM(widthMM)
        thicknessField.setValueMM(thicknessMM)
        // The displayed fraction is an approximation. Keep the exact
        // millimetre values unless the user edits a field again.
        lengthEdited = false
        widthEdited = false
        thicknessEdited = false
    }

    override func saveTapped() {
        let lengthValue = lengthEdited ? lengthField.valueMM : lengthMM
        let widthValue = widthEdited ? widthField.valueMM : widthMM
        let thicknessValue = thicknessEdited ? thicknessField.valueMM : thicknessMM
        guard
            let length = lengthValue, length > 0,
            let width = widthValue, width > 0,
            let thickness = thicknessValue, thickness > 0
        else {
            Haptics.warn()
            showToast("Enter a length, width and thickness.", icon: "exclamationmark")
            return
        }

        var updated = part
        let name = nameField.text.trimmed
        updated.name = name.isEmpty ? "Part" : name
        updated.lengthMM = length
        updated.widthMM = width
        updated.thicknessMM = thickness
        updated.quantity = max(1, Int(quantityRow.value))
        updated.material = materialControl.selectedSegmentIndex == 0 ? .solid : .plywood
        if updated.material == .plywood {
            updated.grain = .none
        } else {
            let grains: [GrainDirection] = [.alongLength, .acrossWidth, .none]
            updated.grain = grains[max(0, min(2, grainControl.selectedSegmentIndex))]
        }

        Haptics.success()
        onSaved?(updated)
        dismiss(animated: true)
    }

    @objc private func deleteTapped() {
        Haptics.tap()
        ConfirmSheetViewController.present(
            from: self,
            title: "Delete this part?",
            message: "The cut plan and board feet will be recalculated without it.",
            confirmTitle: "Delete part",
            destructive: true
        ) { [weak self] in
            self?.onDeleted?()
            self?.dismiss(animated: true)
        }
    }
}
