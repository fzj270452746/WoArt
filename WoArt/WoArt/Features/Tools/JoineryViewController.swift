import UIKit

final class JoineryViewController: ToolPageViewController {
    private let projectControl = UISegmentedControl(items: ["Table", "Frame", "Drawer", "Chair", "Door"])
    private let toolsControl = UISegmentedControl(items: ["Hand", "Power", "Both"])
    private let priorityControl = UISegmentedControl(items: ["Strength", "Look", "Speed"])
    private let disassemblySwitch = UISwitch()
    private let resultsStack = UIStackView()
    private let introLabel = UILabel()

    init() {
        super.init(
            eyebrow: "Workshop tool 05",
            title: "Match the joint\nto the job.",
            intro: "Tell the advisor how the piece will be used and what is in your tool roll. It ranks the joints that make sense.",
            formula: "match = use case + priority + available tools + repairability"
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        let inputCard = ToolSectionCard(
            title: "The brief",
            subtitle: "Be honest about the tools you actually own."
        )
        configureSegment(projectControl, selected: 0)
        configureSegment(toolsControl, selected: 2)
        configureSegment(priorityControl, selected: 0)

        inputCard.add(makeLabeledControl("What are you building?", control: projectControl))
        inputCard.add(makeLabeledControl("Tools on hand", control: toolsControl))
        inputCard.add(makeLabeledControl("What matters most?", control: priorityControl))
        inputCard.add(makeDisassemblyRow(), spacing: 18)

        projectControl.addTarget(self, action: #selector(recompute), for: .valueChanged)
        toolsControl.addTarget(self, action: #selector(recompute), for: .valueChanged)
        priorityControl.addTarget(self, action: #selector(recompute), for: .valueChanged)

        addSection(inputCard)

        let heading = UILabel()
        heading.text = "Recommended joints"
        heading.font = Typeface.display(25, weight: .bold)
        heading.textColor = Palette.ink
        addSection(heading, spacing: 6)

        introLabel.font = Typeface.body(12.5)
        introLabel.textColor = Palette.inkSoft
        introLabel.numberOfLines = 0
        addSection(introLabel, spacing: 10)

        resultsStack.axis = .vertical
        resultsStack.spacing = 12
        addSection(resultsStack)

        addSection(
            ToolNoteView(
                text: "This is a starting point, not a rule. Grain direction, fastener choice and the way a piece will be moved all matter more than a score."
            )
        )

        recompute()
    }

    private func configureSegment(_ control: UISegmentedControl, selected: Int) {
        control.selectedSegmentIndex = selected
        control.selectedSegmentTintColor = Palette.ink
        control.backgroundColor = Palette.cream
        control.setTitleTextAttributes(
            [.font: Typeface.chip(11, weight: .semibold), .foregroundColor: Palette.inkSoft],
            for: .normal
        )
        control.setTitleTextAttributes(
            [.font: Typeface.chip(11, weight: .semibold), .foregroundColor: Palette.paper],
            for: .selected
        )
        control.translatesAutoresizingMaskIntoConstraints = false
        control.heightAnchor.constraint(equalToConstant: 34).isActive = true
    }

    private func makeLabeledControl(_ title: String, control: UISegmentedControl) -> UIView {
        let label = EyebrowLabel(title, color: Palette.inkFaint, size: 9)
        let stack = UIStackView(axis: .vertical, spacing: 8, views: [label, control])
        return stack
    }

    private func makeDisassemblyRow() -> UIView {
        disassemblySwitch.isOn = false
        disassemblySwitch.onTintColor = Palette.terracotta
        disassemblySwitch.addTarget(self, action: #selector(recompute), for: .valueChanged)

        let title = UILabel()
        title.text = "Needs to come apart"
        title.font = Typeface.chip(13, weight: .semibold)
        title.textColor = Palette.ink

        let subtitle = UILabel()
        subtitle.text = "Knockdown furniture, travel, seasonal storage."
        subtitle.font = Typeface.body(10.5)
        subtitle.textColor = Palette.inkFaint

        let text = UIStackView(axis: .vertical, spacing: 2, views: [title, subtitle])
        let row = UIStackView(axis: .horizontal, spacing: 12, alignment: .center, views: [text])
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(disassemblySwitch)
        return row
    }

    @objc private func recompute() {
        let projects: [ProjectType] = [.table, .frame, .drawer, .chair, .door]
        let toolSets: [ToolSet] = [.hand, .power, .both]
        let priorities: [DesignPriority] = [.strength, .appearance, .speed]

        let project = projects[max(0, min(projectControl.selectedSegmentIndex, projects.count - 1))]
        let toolSet = toolSets[max(0, min(toolsControl.selectedSegmentIndex, toolSets.count - 1))]
        let priority = priorities[max(0, min(priorityControl.selectedSegmentIndex, priorities.count - 1))]
        let disassembly = disassemblySwitch.isOn

        let ranked = ToolDataJoints.recommendations(
            project: project,
            toolSet: toolSet,
            priority: priority,
            needsDisassembly: disassembly
        )

        introLabel.text = "For a \(project.rawValue.lowercased()) with \(toolSet.rawValue.lowercased()), prioritising \(priority.rawValue.lowercased())."
        resultsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, item) in ranked.prefix(3).enumerated() {
            let card = JointResultCard(joint: item.joint, score: item.score, rank: index + 1)
            resultsStack.addArrangedSubview(card)
        }

        if ranked.count > 3 {
            let also = UIStackView(axis: .horizontal, spacing: 6, alignment: .center, views: [])
            let label = UILabel()
            label.text = "Also considered"
            label.font = Typeface.eyebrow(8.5)
            label.textColor = Palette.inkFaint
            let names = UILabel()
            names.text = ranked.dropFirst(3).prefix(2).map(\.joint.name).joined(separator: ", ")
            names.font = Typeface.body(11)
            names.textColor = Palette.inkSoft
            names.numberOfLines = 0
            also.addArrangedSubview(label)
            also.addArrangedSubview(names)
            resultsStack.addArrangedSubview(also)
        }
    }
}

private final class JointResultCard: UIView {
    init(joint: JointType, score: Int, rank: Int) {
        super.init(frame: .zero)
        backgroundColor = rank == 1 ? Palette.walnut : Palette.card
        layer.cornerRadius = 26
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = (rank == 1 ? UIColor.white.withAlphaComponent(0.06) : Palette.ink.withAlphaComponent(0.06)).cgColor
        applySoftShadow(opacity: rank == 1 ? 0.18 : 0.06, radius: 18, y: 10)

        let primaryText = rank == 1 ? Palette.paper : Palette.ink
        let secondaryText = rank == 1 ? Palette.paper.withAlphaComponent(0.6) : Palette.inkSoft

        let rankLabel = UILabel()
        rankLabel.text = String(format: "%02d", rank)
        rankLabel.font = Typeface.eyebrow(9)
        rankLabel.textColor = rank == 1 ? Palette.brassLight : Palette.inkFaint

        let scorePill = UILabel()
        scorePill.text = "\(score)% match"
        scorePill.font = Typeface.chip(9.5, weight: .bold)
        scorePill.textColor = rank == 1 ? Palette.walnut : .white
        scorePill.backgroundColor = rank == 1 ? Palette.brassLight : Palette.terracotta
        scorePill.textAlignment = .center
        scorePill.layer.cornerRadius = 10
        scorePill.clipsToBounds = true
        scorePill.translatesAutoresizingMaskIntoConstraints = false
        scorePill.heightAnchor.constraint(equalToConstant: 22).isActive = true
        scorePill.widthAnchor.constraint(greaterThanOrEqualToConstant: 74).isActive = true

        let top = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [rankLabel])
        top.addArrangedSubview(UIView())
        top.addArrangedSubview(scorePill)

        let name = UILabel()
        name.text = joint.name
        name.font = Typeface.display(23, weight: .bold)
        name.textColor = primaryText
        name.numberOfLines = 0

        let summary = UILabel()
        summary.text = joint.summary
        summary.font = Typeface.body(12.5)
        summary.textColor = secondaryText
        summary.numberOfLines = 0
        summary.setLineHeight(3)

        let toolLabel = UILabel()
        toolLabel.text = joint.tool.rawValue
        toolLabel.font = Typeface.chip(10, weight: .semibold)
        toolLabel.textColor = secondaryText

        let difficulty = UILabel()
        difficulty.text = String(repeating: "●", count: joint.difficulty) + String(repeating: "○", count: max(0, 5 - joint.difficulty))
        difficulty.font = .systemFont(ofSize: 8, weight: .semibold)
        difficulty.textColor = rank == 1 ? Palette.brassLight : Palette.terracotta

        let meta = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [toolLabel, UIView(), difficulty])

        let bars = UIStackView(axis: .vertical, spacing: 7, views: [])
        for metric in [
            ("Strength", joint.strength),
            ("Appearance", joint.appearance),
            ("Speed", joint.speed)
        ] {
            bars.addArrangedSubview(
                MetricBarView(
                    title: metric.0,
                    value: "\(metric.1) / 5",
                    fraction: Double(metric.1) / 5,
                    tint: rank == 1 ? Palette.brassLight : Palette.terracotta,
                    dark: rank == 1
                )
            )
        }

        let stack = UIStackView(
            axis: .vertical,
            spacing: 12,
            views: [top, name, summary, meta, bars]
        )
        stack.setCustomSpacing(8, after: top)
        stack.setCustomSpacing(6, after: name)
        stack.setCustomSpacing(14, after: summary)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
