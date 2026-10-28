import Foundation

// MARK: - Units

enum BenchUnit: String, Codable {
    case metric
    case imperial

    var symbol: String { self == .metric ? "mm" : "in" }
    var longName: String { self == .metric ? "Millimetres" : "Inches" }
}

enum PartMaterial: String, Codable, CaseIterable {
    case solid = "Solid"
    case plywood = "Plywood"

    var isStable: Bool { self == .plywood }
    var caption: String {
        self == .solid ? "Moves with the seasons" : "Dimensionally stable"
    }
}

/// The grain relative to the part's finished dimension.
enum GrainDirection: String, Codable, CaseIterable {
    case alongLength = "Along length"
    case acrossWidth = "Across width"
    case none = "No grain"

    var shortName: String {
        switch self {
        case .alongLength: return "Length"
        case .acrossWidth: return "Width"
        case .none: return "None"
        }
    }

    var caption: String {
        switch self {
        case .alongLength: return "Grain runs the long way"
        case .acrossWidth: return "Grain runs across the width"
        case .none: return "No meaningful movement"
        }
    }
}

// MARK: - Formatting

enum BenchFormat {
    static let mmPerInch = 25.4

    static func inches(fromMillimetres mm: Double) -> Double { mm / mmPerInch }
    static func millimetres(fromInches inches: Double) -> Double { inches * mmPerInch }

    static func boardFeet(mm3: Double) -> Double {
        let cubicInches = mm3 / (mmPerInch * mmPerInch * mmPerInch)
        return max(0, cubicInches / 144)
    }

    static func boardFeetText(_ value: Double) -> String {
        String(format: "%.1f bf", max(0, value))
    }

    static func money(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "$%.2f", value)
    }

    static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", max(0, min(1, value)) * 100)
    }

    static func count(_ number: Int, _ singular: String, plural: String? = nil) -> String {
        "\(number) \(number == 1 ? singular : (plural ?? singular + "s"))"
    }

    /// A shop-friendly length. Metric values are whole millimetres; imperial
    /// values are reduced fractions to the nearest 1/16 inch.
    static func length(
        _ mm: Double,
        unit: BenchUnit,
        withUnit: Bool = true,
        fractionDenominator: Int = 16
    ) -> String {
        guard mm.isFinite else { return "—" }
        switch unit {
        case .metric:
            let rounded = (mm * 10).rounded() / 10
            let digits = abs(rounded - rounded.rounded()) < 0.05 ? 0 : 1
            let text = String(format: "%.\(digits)f", rounded)
            return withUnit ? "\(text) mm" : text
        case .imperial:
            let text = fraction(inches: inches(fromMillimetres: mm), denominator: fractionDenominator)
            return withUnit ? "\(text)″" : text
        }
    }

    /// A finer measurement for movement allowances, where a 1/16 inch is
    /// too coarse to be useful.
    static func movement(_ mm: Double, unit: BenchUnit) -> String {
        switch unit {
        case .metric:
            return String(format: "%.1f mm", abs(mm))
        case .imperial:
            return String(format: "%.3f″", abs(inches(fromMillimetres: mm)))
        }
    }

    static func fraction(inches value: Double, denominator: Int = 16) -> String {
        guard value.isFinite else { return "—" }
        let sign = value < 0 ? "−" : ""
        let absolute = abs(value)
        let scaled = Int((absolute * Double(denominator)).rounded())
        let whole = scaled / denominator
        var numerator = scaled % denominator
        if numerator == 0 { return sign + "\(whole)" }

        var divisor = denominator
        while numerator % 2 == 0 && divisor % 2 == 0 {
            numerator /= 2
            divisor /= 2
        }
        if whole == 0 { return "\(sign)\(numerator)/\(divisor)" }
        return "\(sign)\(whole) \(numerator)/\(divisor)"
    }

    /// Parses millimetres, centimetres, inches, feet, decimals and shop
    /// fractions such as "1 3/8" or "3/4".
    static func parse(_ raw: String, unit: BenchUnit) -> Double? {
        var text = raw.lowercased().trimmed
        guard !text.isEmpty else { return nil }

        text = text.replacingOccurrences(of: ",", with: ".")
        text = text.replacingOccurrences(of: "″", with: "in")
        text = text.replacingOccurrences(of: "\"", with: "in")
        text = text.replacingOccurrences(of: "”", with: "in")
        text = text.replacingOccurrences(of: "′", with: "ft")
        text = text.replacingOccurrences(of: "'", with: "ft")
        text = text.replacingOccurrences(of: "millimetres", with: "mm")
        text = text.replacingOccurrences(of: "millimeters", with: "mm")
        text = text.replacingOccurrences(of: "centimetres", with: "cm")
        text = text.replacingOccurrences(of: "centimeters", with: "cm")
        text = text.replacingOccurrences(of: "inches", with: "in")
        text = text.replacingOccurrences(of: "inch", with: "in")
        text = text.replacingOccurrences(of: "feet", with: "ft")

        var multiplier: Double?
        if text.contains("mm") {
            multiplier = 1
            text = text.replacingOccurrences(of: "mm", with: "")
        } else if text.contains("cm") {
            multiplier = 10
            text = text.replacingOccurrences(of: "cm", with: "")
        } else if text.contains("ft") {
            multiplier = mmPerInch * 12
            text = text.replacingOccurrences(of: "ft", with: "")
        } else if text.contains("in") {
            multiplier = mmPerInch
            text = text.replacingOccurrences(of: "in", with: "")
        }

        text = text.replacingOccurrences(of: "−", with: "-")
        text = text.replacingOccurrences(of: "-", with: " ")
        let tokens = text.split(whereSeparator: { $0 == " " }).map(String.init)
        guard !tokens.isEmpty else { return nil }

        var total = 0.0
        var sawValue = false
        for token in tokens {
            if token.contains("/") {
                let parts = token.split(separator: "/")
                guard
                    parts.count == 2,
                    let numerator = Double(parts[0]),
                    let denominator = Double(parts[1]),
                    denominator != 0
                else { return nil }
                total += numerator / denominator
                sawValue = true
            } else if let value = Double(token) {
                total += value
                sawValue = true
            } else {
                return nil
            }
        }
        guard sawValue else { return nil }

        let scale = multiplier ?? (unit == .metric ? 1 : mmPerInch)
        return total * scale
    }

    /// Detects the unit from the text; bare numbers are read as inches,
    /// which is how most shop notes are written.
    static func parseAny(_ raw: String) -> (mm: Double, unit: BenchUnit)? {
        let lowered = raw.lowercased()
        let metric = lowered.contains("mm")
            || lowered.contains("cm")
            || lowered.contains("millimet")
            || lowered.contains("centimet")
        let unit: BenchUnit = metric ? .metric : .imperial
        guard let mm = parse(raw, unit: unit) else { return nil }
        return (mm, unit)
    }

    static func dimensions(
        lengthMM: Double,
        widthMM: Double,
        thicknessMM: Double,
        unit: BenchUnit
    ) -> String {
        let suffix = unit == .metric ? " mm" : "″"
        return [
            length(lengthMM, unit: unit, withUnit: false),
            length(widthMM, unit: unit, withUnit: false),
            length(thicknessMM, unit: unit, withUnit: false)
        ].joined(separator: " × ") + suffix
    }

    static func stockDimensions(
        thicknessMM: Double,
        widthMM: Double,
        lengthMM: Double,
        unit: BenchUnit
    ) -> String {
        let suffix = unit == .metric ? " mm" : "″"
        return [
            length(thicknessMM, unit: unit, withUnit: false),
            length(widthMM, unit: unit, withUnit: false),
            length(lengthMM, unit: unit, withUnit: false)
        ].joined(separator: " × ") + suffix
    }
}

// MARK: - Project data

struct ProjectPart: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var lengthMM: Double
    var widthMM: Double
    var thicknessMM: Double
    var quantity: Int
    var material: PartMaterial
    var grain: GrainDirection

    var volumeMM3: Double {
        max(0, lengthMM) * max(0, widthMM) * max(0, thicknessMM) * Double(max(1, quantity))
    }

    var boardFeet: Double { BenchFormat.boardFeet(mm3: volumeMM3) }

    /// The footprint on the board. A part whose grain runs across its
    /// width is turned 90° in the cut plan so the grain stays on the
    /// board's length.
    var boardLengthMM: Double {
        grain == .acrossWidth ? widthMM : lengthMM
    }

    var boardWidthMM: Double {
        grain == .acrossWidth ? lengthMM : widthMM
    }
}

struct ProjectStep: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var detail: String = ""
    var isDone: Bool = false
}

struct StockBoard: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var label: String
    var material: PartMaterial
    var thicknessMM: Double
    var widthMM: Double
    var lengthMM: Double
    var quantity: Int
    var pricePerBoardFoot: Double

    var boardFeetPerBoard: Double {
        BenchFormat.boardFeet(mm3: max(0, thicknessMM) * max(0, widthMM) * max(0, lengthMM))
    }
}

struct BenchProject: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var speciesID: String
    var notes: String = ""
    var unit: BenchUnit = .metric
    var parts: [ProjectPart] = []
    var steps: [ProjectStep] = []
    var stock: [StockBoard] = []
    var kerfMM: Double = 3
    var trimMM: Double = 10
    var shopRH: Double = 45
    var homeRH: Double = 40
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var species: WoodSpecies {
        ToolData.species(withID: speciesID) ?? ToolData.species[0]
    }

    var partCount: Int {
        parts.reduce(0) { $0 + max(1, $1.quantity) }
    }

    var partTypeCount: Int { parts.count }

    var doneSteps: Int { steps.filter(\.isDone).count }

    var progress: Double {
        steps.isEmpty ? 0 : Double(doneSteps) / Double(steps.count)
    }

    var nextStep: ProjectStep? { steps.first { !$0.isDone } }

    var netBoardFeet: Double {
        parts.reduce(0) { $0 + $1.boardFeet }
    }

    func partSummary(_ part: ProjectPart) -> String {
        let suffix = unit == .metric ? " mm" : "″"
        let dims = [
            BenchFormat.length(part.lengthMM, unit: unit, withUnit: false),
            BenchFormat.length(part.widthMM, unit: unit, withUnit: false),
            BenchFormat.length(part.thicknessMM, unit: unit, withUnit: false)
        ].joined(separator: " × ")
        let grain = part.grain == .acrossWidth ? "  ·  Across grain" : ""
        return "\(dims)\(suffix)  ·  ×\(max(1, part.quantity))\(grain)"
    }
}

// MARK: - Templates

struct BenchTemplate: Identifiable {
    struct PartSpec {
        let name: String
        let lengthMM: Double
        let widthMM: Double
        let thicknessMM: Double
        let quantity: Int
        let material: PartMaterial
        let grain: GrainDirection
    }

    struct StockSpec {
        let label: String
        let material: PartMaterial
        let thicknessMM: Double
        let widthMM: Double
        let lengthMM: Double
        let quantity: Int
        let pricePerBoardFoot: Double
    }

    struct StepSpec {
        let title: String
        let detail: String
    }

    let id: String
    let name: String
    let blurb: String
    let symbol: String
    let defaultTitle: String
    let speciesID: String
    let parts: [PartSpec]
    let steps: [StepSpec]
    let stock: [StockSpec]

    func makeProject(unit: BenchUnit) -> BenchProject {
        BenchProject(
            title: defaultTitle,
            speciesID: speciesID,
            unit: unit,
            parts: parts.map {
                ProjectPart(
                    name: $0.name,
                    lengthMM: $0.lengthMM,
                    widthMM: $0.widthMM,
                    thicknessMM: $0.thicknessMM,
                    quantity: $0.quantity,
                    material: $0.material,
                    grain: $0.grain
                )
            },
            steps: steps.map { ProjectStep(title: $0.title, detail: $0.detail) },
            stock: stock.map {
                StockBoard(
                    label: $0.label,
                    material: $0.material,
                    thicknessMM: $0.thicknessMM,
                    widthMM: $0.widthMM,
                    lengthMM: $0.lengthMM,
                    quantity: $0.quantity,
                    pricePerBoardFoot: $0.pricePerBoardFoot
                )
            }
        )
    }
}

enum BenchTemplates {
    static let all: [BenchTemplate] = [sideTable, stool, cuttingBoard, wallShelf, blank]

    static func template(id: String) -> BenchTemplate? {
        all.first { $0.id == id }
    }

    static let sideTable = BenchTemplate(
        id: "side_table",
        name: "Side table",
        blurb: "Four legs, aprons and a three-board top.",
        symbol: "table.furniture",
        defaultTitle: "Walnut side table",
        speciesID: "walnut",
        parts: [
            .init(name: "Legs", lengthMM: 720, widthMM: 42, thicknessMM: 42, quantity: 4, material: .solid, grain: .alongLength),
            .init(name: "Long aprons", lengthMM: 610, widthMM: 90, thicknessMM: 22, quantity: 2, material: .solid, grain: .alongLength),
            .init(name: "Short aprons", lengthMM: 350, widthMM: 90, thicknessMM: 22, quantity: 2, material: .solid, grain: .alongLength),
            .init(name: "Top boards", lengthMM: 760, widthMM: 140, thicknessMM: 25, quantity: 3, material: .solid, grain: .alongLength)
        ],
        steps: [
            .init(title: "Mill and square the stock", detail: "Face and edge every board. Leave the legs 1 mm heavy until the joints are cut."),
            .init(title: "Cut the legs to length", detail: "Four legs at 720 mm. Mark the pairs so the grain reads consistently."),
            .init(title: "Cut the aprons and top", detail: "Two long rails, two short rails, three top boards. Keep the top parts in order."),
            .init(title: "Cut the mortise and tenon joints", detail: "Use the one-third rule for tenon thickness. Test the setup on an offcut."),
            .init(title: "Dry fit the frame", detail: "Clamp the frame square, measure both diagonals, then label every joint."),
            .init(title: "Glue up in two stages", detail: "Frame first, top second. Clean squeeze-out while the glue is still soft."),
            .init(title: "Sand, oil and let it settle", detail: "Raise the grain, sand to 220, then two thin coats of oil.")
        ],
        stock: [
            .init(label: "Leg stock", material: .solid, thicknessMM: 45, widthMM: 100, lengthMM: 2400, quantity: 1, pricePerBoardFoot: 0),
            .init(label: "Board stock", material: .solid, thicknessMM: 25, widthMM: 200, lengthMM: 2400, quantity: 2, pricePerBoardFoot: 0)
        ]
    )

    static let stool = BenchTemplate(
        id: "stool",
        name: "Stool",
        blurb: "A glued seat, four legs, four stretchers.",
        symbol: "chair",
        defaultTitle: "Ash workshop stool",
        speciesID: "ash",
        parts: [
            .init(name: "Seat slats", lengthMM: 360, widthMM: 115, thicknessMM: 32, quantity: 3, material: .solid, grain: .alongLength),
            .init(name: "Legs", lengthMM: 430, widthMM: 42, thicknessMM: 42, quantity: 4, material: .solid, grain: .alongLength),
            .init(name: "Stretchers", lengthMM: 300, widthMM: 20, thicknessMM: 32, quantity: 4, material: .solid, grain: .alongLength)
        ],
        steps: [
            .init(title: "Mill the seat slats", detail: "Three slats at 360 × 115 × 32 mm. Joint one edge of each."),
            .init(title: "Glue the seat", detail: "Alternate the grain, clamp flat, and check the diagonals."),
            .init(title: "Cut the legs and stretchers", detail: "Four legs at 430 mm, four stretchers at 300 mm."),
            .init(title: "Cut the joinery", detail: "Angled mortises for the legs, straight stretcher joints. Test on scrap."),
            .init(title: "Dry fit and mark", detail: "Assemble without glue, check for rock, then number the joints."),
            .init(title: "Glue up", detail: "Seat, legs, then stretchers. Keep the frame square while it cures."),
            .init(title: "Flatten and finish", detail: "Flush the seat, ease the edges, sand and oil.")
        ],
        stock: [
            .init(label: "Seat stock", material: .solid, thicknessMM: 35, widthMM: 380, lengthMM: 900, quantity: 1, pricePerBoardFoot: 0),
            .init(label: "Leg stock", material: .solid, thicknessMM: 45, widthMM: 100, lengthMM: 1200, quantity: 1, pricePerBoardFoot: 0),
            .init(label: "Stretcher stock", material: .solid, thicknessMM: 32, widthMM: 100, lengthMM: 900, quantity: 1, pricePerBoardFoot: 0)
        ]
    )

    static let cuttingBoard = BenchTemplate(
        id: "cutting_board",
        name: "Cutting board",
        blurb: "Twelve strips, one careful glue-up.",
        symbol: "square.grid.3x3",
        defaultTitle: "Maple cutting board",
        speciesID: "maple",
        parts: [
            .init(name: "Maple strips", lengthMM: 450, widthMM: 40, thicknessMM: 28, quantity: 12, material: .solid, grain: .alongLength)
        ],
        steps: [
            .init(title: "Mill the maple", detail: "Dress both faces and one edge. Let the stock rest overnight."),
            .init(title: "Rip the strips", detail: "Twelve strips at 40 × 28 mm. Keep them in order."),
            .init(title: "Arrange the grain", detail: "Flip every other strip so the board stays flat."),
            .init(title: "Glue up in two halves", detail: "Glue and clamp each half flat, then join the two halves."),
            .init(title: "Flatten and square", detail: "Plane or drum-sand both faces, then square the ends."),
            .init(title: "Ease the edges", detail: "A 6 mm roundover or a chamfer. Break every sharp corner."),
            .init(title: "Oil and cure", detail: "Food-safe oil, three coats, 24 hours apart.")
        ],
        stock: [
            .init(label: "Maple boards", material: .solid, thicknessMM: 30, widthMM: 160, lengthMM: 1200, quantity: 2, pricePerBoardFoot: 0)
        ]
    )

    static let wallShelf = BenchTemplate(
        id: "wall_shelf",
        name: "Wall shelf",
        blurb: "One shelf, two shaped brackets.",
        symbol: "rectangle.split.3x1",
        defaultTitle: "Oak wall shelf",
        speciesID: "white_oak",
        parts: [
            .init(name: "Shelf", lengthMM: 700, widthMM: 220, thicknessMM: 25, quantity: 1, material: .solid, grain: .alongLength),
            .init(name: "Brackets", lengthMM: 180, widthMM: 140, thicknessMM: 18, quantity: 2, material: .solid, grain: .alongLength)
        ],
        steps: [
            .init(title: "Mill the shelf and brackets", detail: "Shelf at 700 × 220 × 25 mm, brackets at 180 × 140 × 18 mm."),
            .init(title: "Cut the bracket shape", detail: "Draw the curve, cut close to the line, then fair it with a spokeshave."),
            .init(title: "Cut the joinery", detail: "A housed dado or a stopped mortise. Fit each bracket to its own place."),
            .init(title: "Dry fit and drill", detail: "Mark the fixing holes before glue-up. Countersink the screw heads."),
            .init(title: "Glue up", detail: "Shelf and brackets square, then clean the inside corners."),
            .init(title: "Sand and finish", detail: "Sand to 220, ease the edges, oil or hard wax.")
        ],
        stock: [
            .init(label: "Shelf stock", material: .solid, thicknessMM: 25, widthMM: 250, lengthMM: 900, quantity: 1, pricePerBoardFoot: 0),
            .init(label: "Bracket stock", material: .solid, thicknessMM: 18, widthMM: 160, lengthMM: 600, quantity: 1, pricePerBoardFoot: 0)
        ]
    )

    static let blank = BenchTemplate(
        id: "blank",
        name: "Start blank",
        blurb: "Bring your own parts and steps.",
        symbol: "hammer",
        defaultTitle: "Untitled project",
        speciesID: "white_oak",
        parts: [],
        steps: [
            .init(title: "Mill and square the stock", detail: "Face, edge and thickness everything before the first cut."),
            .init(title: "Cut the parts", detail: "Work from the longest part to the shortest."),
            .init(title: "Dry fit", detail: "Assemble without glue and check the diagonals."),
            .init(title: "Glue up", detail: "Work in stages, keep the clamps square, clean the squeeze-out."),
            .init(title: "Sand and finish", detail: "Raise the grain, sand through the grits, then finish.")
        ],
        stock: [
            .init(label: "Board stock", material: .solid, thicknessMM: 25, widthMM: 200, lengthMM: 2400, quantity: 1, pricePerBoardFoot: 0)
        ]
    )
}
