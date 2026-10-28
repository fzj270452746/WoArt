import Foundation

struct WoodSpecies: Identifiable, Equatable {
    let id: String
    let name: String
    let botanical: String
    let character: String
    let janka: Int
    let density: Int
    let tangential: Double
    let radial: Double
    let workability: Int
    let stability: Int
    let uses: [String]
    let swatch: UInt32
}

enum BenchMath {
    static func boardFeet(
        thicknessInches: Double,
        widthInches: Double,
        lengthFeet: Double,
        quantity: Int,
        waste: Double
    ) -> Double {
        guard thicknessInches > 0, widthInches > 0, lengthFeet > 0, quantity > 0 else { return 0 }
        let perPiece = thicknessInches * widthInches * (lengthFeet * 12) / 144
        return perPiece * Double(quantity) * (1 + max(0, waste))
    }

    /// Positive result means the board shrinks; negative means it expands.
    static func movement(
        width: Double,
        currentMC: Double,
        targetMC: Double,
        species: WoodSpecies,
        quarterSawn: Bool
    ) -> Double {
        let shrinkage = quarterSawn ? species.radial : species.tangential
        let percentPerMC = shrinkage / 28.0
        let deltaPercent = percentPerMC * (currentMC - targetMC)
        return width * deltaPercent / 100
    }

    static func equilibriumMC(relativeHumidity: Double, temperatureC: Double) -> Double {
        // Fitted to the familiar 20°C equilibrium curve: about 6.2% at 30% RH,
        // 9.2% at 50% and 13.5% at 70%. The old compact approximation sat far
        // too low and made every movement allowance vanish.
        let rh = max(5, min(98, relativeHumidity))
        let base = 0.001625 * rh * rh + 0.02 * rh + 4.1375
        let temperatureAdjustment = (20 - temperatureC) * 0.06
        return max(2, base + temperatureAdjustment)
    }

    static func cutList(
        stockLength: Double,
        pieces: [(length: Double, quantity: Int)],
        kerf: Double,
        trim: Double
    ) -> (boards: [[Double]], oversize: [Double], yield: Double) {
        let usable = stockLength - 2 * trim
        guard usable > 0, stockLength > 0 else { return ([], [], 0) }
        var demand: [Double] = []
        for piece in pieces where piece.length > 0 && piece.quantity > 0 {
            demand.append(contentsOf: Array(repeating: piece.length, count: piece.quantity))
        }
        demand.sort(by: >)

        var boards: [[Double]] = []
        var oversize: [Double] = []

        for item in demand {
            if item > usable {
                oversize.append(item)
                continue
            }
            var placed = false
            for index in boards.indices {
                let used = boards[index].reduce(0, +) + Double(boards[index].count) * kerf
                if used + item <= usable {
                    boards[index].append(item)
                    placed = true
                    break
                }
            }
            if !placed {
                boards.append([item])
            }
        }

        let totalUsed = boards.flatMap { $0 }.reduce(0, +)
        let totalStock = Double(boards.count) * stockLength
        let yield = totalStock > 0 ? totalUsed / totalStock : 0
        return (boards, oversize, yield)
    }
}

enum ToolData {
    static let species: [WoodSpecies] = [
        WoodSpecies(
            id: "white_oak",
            name: "White Oak",
            botanical: "Quercus alba",
            character: "Open grain, tannin-rich and quietly stubborn. Steam-bends well and takes a sharp edge kindly.",
            janka: 1360,
            density: 770,
            tangential: 10.5,
            radial: 5.6,
            workability: 4,
            stability: 4,
            uses: ["Furniture", "Flooring", "Boats"],
            swatch: 0xB98A5E
        ),
        WoodSpecies(
            id: "red_oak",
            name: "Red Oak",
            botanical: "Quercus rubra",
            character: "Strong and open-grained. Finishes warm, but the pores want filling if you want a glass-smooth surface.",
            janka: 1290,
            density: 750,
            tangential: 9.8,
            radial: 4.8,
            workability: 4,
            stability: 3,
            uses: ["Furniture", "Cabinets", "Trim"],
            swatch: 0xB97A57
        ),
        WoodSpecies(
            id: "walnut",
            name: "Black Walnut",
            botanical: "Juglans nigra",
            character: "Chocolate heartwood that calms under a sharp plane. A generous wood that rewards restraint.",
            janka: 1010,
            density: 660,
            tangential: 8.2,
            radial: 5.6,
            workability: 5,
            stability: 4,
            uses: ["Furniture", "Turning", "Inlay"],
            swatch: 0x6A4630
        ),
        WoodSpecies(
            id: "maple",
            name: "Hard Maple",
            botanical: "Acer saccharum",
            character: "Dense, pale and exacting. Dull edges show immediately; sharp ones leave a glassy surface.",
            janka: 1450,
            density: 740,
            tangential: 11.9,
            radial: 5.4,
            workability: 3,
            stability: 4,
            uses: ["Benches", "Cutting boards", "Turning"],
            swatch: 0xD7BE94
        ),
        WoodSpecies(
            id: "cherry",
            name: "Cherry",
            botanical: "Prunus serotina",
            character: "Works beautifully and darkens to copper with light. Quiet grain, few surprises.",
            janka: 950,
            density: 580,
            tangential: 8.4,
            radial: 4.2,
            workability: 5,
            stability: 4,
            uses: ["Furniture", "Cabinets", "Carving"],
            swatch: 0xA8643F
        ),
        WoodSpecies(
            id: "ash",
            name: "Ash",
            botanical: "Fraxinus americana",
            character: "Elastic and straight-grained. The classic chair wood, and the best teacher for green-wood bending.",
            janka: 1320,
            density: 690,
            tangential: 10.8,
            radial: 5.9,
            workability: 4,
            stability: 3,
            uses: ["Chairs", "Bending", "Tool handles"],
            swatch: 0xC9A477
        ),
        WoodSpecies(
            id: "hickory",
            name: "Hickory",
            botanical: "Carya ovata",
            character: "The hardest common domestic. Brutal on edges, magnificent for handles and anything that takes a hit.",
            janka: 1830,
            density: 830,
            tangential: 11.0,
            radial: 7.0,
            workability: 2,
            stability: 3,
            uses: ["Handles", "Sledges", "Flooring"],
            swatch: 0xA77B52
        ),
        WoodSpecies(
            id: "douglas_fir",
            name: "Douglas Fir",
            botanical: "Pseudotsuga menziesii",
            character: "Structural, resinous and crisp under hand tools. Old-growth stock is a different wood entirely.",
            janka: 660,
            density: 530,
            tangential: 7.9,
            radial: 4.2,
            workability: 4,
            stability: 3,
            uses: ["Framing", "Workbenches", "Siding"],
            swatch: 0xC28D5C
        ),
        WoodSpecies(
            id: "white_pine",
            name: "White Pine",
            botanical: "Pinus strobus",
            character: "Soft, honest and easy to learn on. Dents are part of the conversation.",
            janka: 420,
            density: 420,
            tangential: 7.4,
            radial: 4.1,
            workability: 5,
            stability: 4,
            uses: ["Trim", "Carving", "Practice"],
            swatch: 0xE2C9A0
        ),
        WoodSpecies(
            id: "poplar",
            name: "Poplar",
            botanical: "Liriodendron tulipifera",
            character: "Paint-grade and forgiving, but it moves more than you expect. Fine for a carcass, poor for a show surface.",
            janka: 540,
            density: 460,
            tangential: 9.2,
            radial: 4.6,
            workability: 5,
            stability: 2,
            uses: ["Paint-grade", "Drawers", "Jigs"],
            swatch: 0xB7B58C
        ),
        WoodSpecies(
            id: "mahogany",
            name: "Mahogany",
            botanical: "Swietenia macrophylla",
            character: "Stable, warm and a dream under a smoothing plane. The grain almost guides the tool.",
            janka: 800,
            density: 590,
            tangential: 7.6,
            radial: 3.9,
            workability: 5,
            stability: 5,
            uses: ["Furniture", "Veneer", "Inlay"],
            swatch: 0x91553A
        ),
        WoodSpecies(
            id: "teak",
            name: "Teak",
            botanical: "Tectona grandis",
            character: "Oily and weatherproof. Blunts edges quietly and resists almost everything the outdoors can offer.",
            janka: 1150,
            density: 630,
            tangential: 5.6,
            radial: 2.8,
            workability: 4,
            stability: 5,
            uses: ["Outdoor", "Boats", "Furniture"],
            swatch: 0xBE9A5E
        ),
        WoodSpecies(
            id: "ebony",
            name: "Ebony",
            botanical: "Diospyros ebenum",
            character: "Dense, dark and slow. Cut slowly, sand lightly, and treat every offcut as precious.",
            janka: 3220,
            density: 1200,
            tangential: 10.5,
            radial: 7.6,
            workability: 2,
            stability: 4,
            uses: ["Inlay", "Details", "Turning"],
            swatch: 0x3A2C26
        ),
        WoodSpecies(
            id: "cedar",
            name: "Aromatic Cedar",
            botanical: "Juniperus virginiana",
            character: "Light, fragrant and kind to tools. A pleasure to carve, though soft edges demand care.",
            janka: 560,
            density: 380,
            tangential: 7.8,
            radial: 4.2,
            workability: 4,
            stability: 4,
            uses: ["Boxes", "Linings", "Carving"],
            swatch: 0xB97C58
        )
    ]

    static func species(withID id: String) -> WoodSpecies? {
        species.first { $0.id == id }
    }
}

enum ProjectType: String, CaseIterable {
    case table = "Tabletop"
    case frame = "Frame"
    case drawer = "Drawer"
    case chair = "Chair"
    case door = "Cabinet door"
}

enum ToolSet: String, CaseIterable {
    case hand = "Hand tools"
    case power = "Power tools"
    case both = "Both"
}

enum DesignPriority: String, CaseIterable {
    case strength = "Strength"
    case appearance = "Appearance"
    case speed = "Speed"
}

enum JointTool: String {
    case hand = "Hand tools"
    case power = "Power tools"
    case either = "Hand or power"
}

struct JointType: Identifiable, Equatable {
    let id: String
    let name: String
    let summary: String
    let projectScores: [ProjectType: Int]
    let strength: Int
    let appearance: Int
    let speed: Int
    let tool: JointTool
    let disassembly: Int
    let difficulty: Int

    func isAvailable(for toolSet: ToolSet) -> Bool {
        switch (toolSet, tool) {
        case (.hand, .power): return false
        case (.power, .hand): return false
        default: return true
        }
    }

    func score(project: ProjectType, priority: DesignPriority, needsDisassembly: Bool) -> Int {
        let base = Double(projectScores[project] ?? 1) * 12
        let priorityValue: Double
        switch priority {
        case .strength: priorityValue = Double(strength) * 6
        case .appearance: priorityValue = Double(appearance) * 6
        case .speed: priorityValue = Double(speed) * 6
        }
        let disassemblyValue = needsDisassembly ? Double(disassembly) * 6 - 8 : 0
        let raw = base + priorityValue + 14 + disassemblyValue
        return min(98, max(15, Int((raw / 132 * 100).rounded())))
    }
}

enum ToolDataJoints {
    static let joints: [JointType] = [
        JointType(
            id: "dovetail",
            name: "Through dovetail",
            summary: "Interlocking pins and tails that resist pull-out in one direction and look honest doing it.",
            projectScores: [.drawer: 5, .door: 4, .table: 2, .frame: 2, .chair: 2],
            strength: 5,
            appearance: 5,
            speed: 2,
            tool: .hand,
            disassembly: 1,
            difficulty: 4
        ),
        JointType(
            id: "mortise_tenon",
            name: "Mortise & tenon",
            summary: "The structural backbone of furniture. A wedged version can be taken apart and re-tightened.",
            projectScores: [.table: 5, .frame: 5, .chair: 5, .door: 5, .drawer: 2],
            strength: 5,
            appearance: 4,
            speed: 2,
            tool: .either,
            disassembly: 3,
            difficulty: 3
        ),
        JointType(
            id: "drawbored",
            name: "Drawbored tenon",
            summary: "An offset peg pulls the joint tight and holds it without glue. Traditional, repairable, very strong.",
            projectScores: [.chair: 5, .frame: 5, .table: 4, .door: 3],
            strength: 5,
            appearance: 4,
            speed: 2,
            tool: .hand,
            disassembly: 3,
            difficulty: 4
        ),
        JointType(
            id: "bridle",
            name: "Bridle joint",
            summary: "A strong, simple frame joint. It shows its construction, which is either the point or not.",
            projectScores: [.frame: 4, .table: 3, .chair: 3, .door: 2],
            strength: 3,
            appearance: 3,
            speed: 3,
            tool: .either,
            disassembly: 3,
            difficulty: 2
        ),
        JointType(
            id: "half_lap",
            name: "Half-lap",
            summary: "Fast, forgiving and excellent for frames. Glue face is large, alignment is built in.",
            projectScores: [.frame: 4, .table: 3, .door: 3, .chair: 2],
            strength: 3,
            appearance: 2,
            speed: 4,
            tool: .either,
            disassembly: 2,
            difficulty: 1
        ),
        JointType(
            id: "box_joint",
            name: "Box joint",
            summary: "Square interlocking fingers. Visually bolder than a dovetail and much faster to cut with a jig.",
            projectScores: [.drawer: 5, .door: 4, .table: 2, .frame: 2],
            strength: 4,
            appearance: 4,
            speed: 3,
            tool: .either,
            disassembly: 1,
            difficulty: 3
        ),
        JointType(
            id: "domino",
            name: "Loose tenon",
            summary: "A floating tenon in a routed slot. Fast, accurate and strong enough for most furniture.",
            projectScores: [.table: 5, .frame: 4, .door: 4, .chair: 3, .drawer: 2],
            strength: 4,
            appearance: 4,
            speed: 5,
            tool: .power,
            disassembly: 2,
            difficulty: 2
        ),
        JointType(
            id: "biscuit",
            name: "Biscuit",
            summary: "A compressed beech wafer for alignment. Great for panels, not a substitute for structure.",
            projectScores: [.table: 4, .door: 4, .frame: 3, .drawer: 2],
            strength: 2,
            appearance: 4,
            speed: 5,
            tool: .power,
            disassembly: 1,
            difficulty: 1
        ),
        JointType(
            id: "pocket_screw",
            name: "Pocket screw",
            summary: "Fast and hidden, but the screws carry the load. Good for shop cabinets, rarely for heirlooms.",
            projectScores: [.drawer: 4, .table: 3, .door: 2, .frame: 2, .chair: 1],
            strength: 2,
            appearance: 2,
            speed: 5,
            tool: .power,
            disassembly: 4,
            difficulty: 1
        ),
        JointType(
            id: "dowel",
            name: "Dowel joint",
            summary: "A quiet old standard. Alignment is the whole challenge; get it right and it disappears.",
            projectScores: [.table: 3, .chair: 3, .frame: 3, .drawer: 3, .door: 3],
            strength: 3,
            appearance: 3,
            speed: 3,
            tool: .either,
            disassembly: 2,
            difficulty: 2
        ),
        JointType(
            id: "dado",
            name: "Dado / housing",
            summary: "A housed shelf or panel. Strong in shear and simple to size accurately with a router or plane.",
            projectScores: [.door: 5, .drawer: 4, .table: 2, .frame: 2, .chair: 1],
            strength: 3,
            appearance: 3,
            speed: 4,
            tool: .either,
            disassembly: 1,
            difficulty: 1
        ),
        JointType(
            id: "mitre_spline",
            name: "Mitre with spline",
            summary: "A clean wrapped corner with hidden reinforcement. The spline does the structural work.",
            projectScores: [.frame: 4, .door: 3, .table: 3, .drawer: 2],
            strength: 2,
            appearance: 5,
            speed: 3,
            tool: .either,
            disassembly: 1,
            difficulty: 3
        )
    ]

    static func recommendations(
        project: ProjectType,
        toolSet: ToolSet,
        priority: DesignPriority,
        needsDisassembly: Bool
    ) -> [(joint: JointType, score: Int)] {
        joints
            .filter { $0.isAvailable(for: toolSet) }
            .map { ($0, $0.score(project: project, priority: priority, needsDisassembly: needsDisassembly)) }
            .sorted { $0.1 > $1.1 }
    }
}
