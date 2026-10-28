import Foundation

struct BenchPlan {
    struct PlacedPart: Identifiable {
        let id: String
        let partID: String
        let name: String
        let lengthMM: Double
        let widthMM: Double
        let thicknessMM: Double
        let colorIndex: Int

        var volumeMM3: Double {
            max(0, lengthMM) * max(0, widthMM) * max(0, thicknessMM)
        }
    }

    struct Strip: Identifiable {
        let id: String
        let widthMM: Double
        var parts: [PlacedPart] = []
        var usedLengthMM: Double = 0
    }

    struct Board: Identifiable {
        let id: String
        let stockID: String
        let stockLabel: String
        let material: PartMaterial
        let thicknessMM: Double
        let widthMM: Double
        let lengthMM: Double
        let pricePerBoardFoot: Double
        var strips: [Strip] = []
        var usedWidthMM: Double = 0
        var usedLengthMM: Double = 0

        var boardFeet: Double {
            BenchFormat.boardFeet(mm3: thicknessMM * widthMM * lengthMM)
        }

        var partCount: Int {
            strips.reduce(0) { $0 + $1.parts.count }
        }
    }

    struct StockSummary: Identifiable {
        let id: String
        let label: String
        let dimensionText: String
        let available: Int
        let needed: Int
        let boardFeetPerBoard: Double
        let pricePerBoardFoot: Double
        let stockValue: Double?

        var extra: Int { max(0, needed - available) }
        var costToBuy: Double? {
            guard pricePerBoardFoot > 0, extra > 0 else { return nil }
            return Double(extra) * boardFeetPerBoard * pricePerBoardFoot
        }
    }

    struct Unplaced: Identifiable {
        let id: String
        let name: String
        let quantity: Int
        let dimensionText: String
        let reason: String
    }

    var boards: [Board] = []
    var summaries: [StockSummary] = []
    var unplaced: [Unplaced] = []
    var netBoardFeet: Double = 0
    var placedBoardFeet: Double = 0
    var plannedBoardFeet: Double = 0
    var yield: Double = 0
    var costToBuy: Double?
    var stockValue: Double?

    var boardCount: Int { boards.count }
    var waste: Double { max(0, 1 - yield) }
    var unplacedCount: Int { unplaced.reduce(0) { $0 + $1.quantity } }
}

struct BenchMetrics {
    let partCount: Int
    let partTypeCount: Int
    let netBoardFeet: Double
    let plannedBoardFeet: Double
    let boardCount: Int
    let yield: Double
    let costToBuy: Double?
    let stockValue: Double?
    let unplacedCount: Int
    let doneSteps: Int
    let stepCount: Int
    let progress: Double
}

struct BenchMovement {
    struct Row: Identifiable {
        let id: String
        let name: String
        let material: PartMaterial
        let grain: GrainDirection
        let dimensionMM: Double
        let axis: String
        let movementMM: Double
        let cutToMM: Double
        let exceeds: Bool

        var isStable: Bool { material == .plywood || grain == .none }
    }

    let rows: [Row]
    let shopMC: Double
    let homeMC: Double
    let maxMovementMM: Double
    let maxPartName: String?
    let exceedsCount: Int
    let stableCount: Int

    var isShrinking: Bool { shopMC >= homeMC }
}

enum BenchEngine {
    private struct Item {
        let part: ProjectPart
        let colorIndex: Int
    }

    private struct UnplacedGroup {
        let part: ProjectPart
        var quantity: Int
        let reason: String
    }

    // MARK: - Cut plan

    static func plan(project: BenchProject) -> BenchPlan {
        var plan = BenchPlan()
        let parts = project.parts.filter {
            $0.lengthMM > 0 && $0.widthMM > 0 && $0.thicknessMM > 0 && $0.quantity > 0
        }
        plan.netBoardFeet = parts.reduce(0) { $0 + $1.boardFeet }

        guard !parts.isEmpty else { return plan }

        let stocks = project.stock.filter {
            $0.lengthMM > 0 && $0.widthMM > 0 && $0.thicknessMM > 0 && $0.quantity > 0
        }
        guard !stocks.isEmpty else {
            plan.unplaced = parts.map {
                BenchPlan.Unplaced(
                    id: $0.id,
                    name: $0.name,
                    quantity: max(1, $0.quantity),
                    dimensionText: project.partSummary($0),
                    reason: "Add the stock you plan to buy."
                )
            }
            return plan
        }

        var itemsByStock: [String: [Item]] = [:]
        var unplacedGroups: [String: UnplacedGroup] = [:]

        for (index, part) in parts.enumerated() {
            let count = max(1, part.quantity)
            for _ in 0..<count {
                let item = Item(part: part, colorIndex: index)
                if let stock = bestStock(for: part, in: stocks, trim: project.trimMM) {
                    itemsByStock[stock.id, default: []].append(item)
                } else {
                    let reason = failureReason(for: part, stocks: stocks, trim: project.trimMM)
                    let key = "\(part.id)|\(reason)"
                    unplacedGroups[key, default: UnplacedGroup(part: part, quantity: 0, reason: reason)].quantity += 1
                }
            }
        }

        for stock in stocks {
            guard let items = itemsByStock[stock.id], !items.isEmpty else { continue }
            let boards = pack(items: items, stock: stock, trim: project.trimMM, kerf: project.kerfMM)
            plan.boards.append(contentsOf: boards)
        }

        let placedVolume = plan.boards
            .flatMap { $0.strips }
            .flatMap { $0.parts }
            .reduce(0.0) { $0 + $1.volumeMM3 }
        plan.placedBoardFeet = BenchFormat.boardFeet(mm3: placedVolume)
        plan.plannedBoardFeet = plan.boards.reduce(0) { $0 + $1.boardFeet }

        for stock in stocks {
            let boards = plan.boards.filter { $0.stockID == stock.id }
            guard !boards.isEmpty else { continue }
            let needed = boards.count
            let bf = stock.boardFeetPerBoard
            let value = stock.pricePerBoardFoot > 0
                ? Double(needed) * bf * stock.pricePerBoardFoot
                : nil
            plan.summaries.append(
                BenchPlan.StockSummary(
                    id: stock.id,
                    label: stock.label,
                    dimensionText: BenchFormat.stockDimensions(
                        thicknessMM: stock.thicknessMM,
                        widthMM: stock.widthMM,
                        lengthMM: stock.lengthMM,
                        unit: project.unit
                    ),
                    available: stock.quantity,
                    needed: needed,
                    boardFeetPerBoard: bf,
                    pricePerBoardFoot: stock.pricePerBoardFoot,
                    stockValue: value
                )
            )
        }

        plan.unplaced = unplacedGroups.values
            .map {
                BenchPlan.Unplaced(
                    id: "\($0.part.id)-\($0.reason)",
                    name: $0.part.name,
                    quantity: $0.quantity,
                    dimensionText: project.partSummary($0.part),
                    reason: $0.reason
                )
            }
            .sorted { $0.name < $1.name }

        plan.yield = plan.plannedBoardFeet > 0
            ? min(1, plan.placedBoardFeet / plan.plannedBoardFeet)
            : 0

        let buy = plan.summaries.compactMap { $0.costToBuy }
        plan.costToBuy = buy.isEmpty ? nil : buy.reduce(0, +)
        let value = plan.summaries.compactMap { $0.stockValue }
        plan.stockValue = value.isEmpty ? nil : value.reduce(0, +)

        return plan
    }

    static func metrics(project: BenchProject) -> BenchMetrics {
        let plan = plan(project: project)
        return BenchMetrics(
            partCount: project.partCount,
            partTypeCount: project.partTypeCount,
            netBoardFeet: plan.netBoardFeet,
            plannedBoardFeet: plan.plannedBoardFeet,
            boardCount: plan.boardCount,
            yield: plan.yield,
            costToBuy: plan.costToBuy,
            stockValue: plan.stockValue,
            unplacedCount: plan.unplacedCount,
            doneSteps: project.doneSteps,
            stepCount: project.steps.count,
            progress: project.progress
        )
    }

    // MARK: - Movement

    static func movement(project: BenchProject) -> BenchMovement {
        let shopMC = BenchMath.equilibriumMC(relativeHumidity: project.shopRH, temperatureC: 20)
        let homeMC = BenchMath.equilibriumMC(relativeHumidity: project.homeRH, temperatureC: 20)
        let deltaMC = shopMC - homeMC
        let shrinkage = project.species.tangential

        var rows: [BenchMovement.Row] = []
        for part in project.parts {
            let dimension: Double
            let axis: String
            if part.material == .plywood || part.grain == .none {
                dimension = 0
                axis = "Stable"
            } else if part.grain == .alongLength {
                dimension = part.widthMM
                axis = "Width"
            } else {
                dimension = part.lengthMM
                axis = "Length"
            }

            let movement = dimension * (shrinkage / 28.0) * deltaMC / 100
            rows.append(
                BenchMovement.Row(
                    id: part.id,
                    name: part.name,
                    material: part.material,
                    grain: part.grain,
                    dimensionMM: dimension,
                    axis: axis,
                    movementMM: movement,
                    cutToMM: dimension + movement,
                    exceeds: abs(movement) >= 1.5
                )
            )
        }

        let maxRow = rows.max { abs($0.movementMM) < abs($1.movementMM) }
        return BenchMovement(
            rows: rows,
            shopMC: shopMC,
            homeMC: homeMC,
            maxMovementMM: maxRow.map { abs($0.movementMM) } ?? 0,
            maxPartName: abs(maxRow?.movementMM ?? 0) > 0.05 ? maxRow?.name : nil,
            exceedsCount: rows.filter(\.exceeds).count,
            stableCount: rows.filter(\.isStable).count
        )
    }

    // MARK: - Stock matching

    private static func bestStock(
        for part: ProjectPart,
        in stocks: [StockBoard],
        trim: Double
    ) -> StockBoard? {
        stocks
            .filter { stock in
                stock.material == part.material
                    && stock.thicknessMM + 0.01 >= part.thicknessMM
                    && stock.widthMM + 0.01 >= part.boardWidthMM
                    && (stock.lengthMM - 2 * trim) + 0.01 >= part.boardLengthMM
            }
            .min { lhs, rhs in
                // Thickness first: planing a 45 mm board down to 22 mm wastes
                // more time and material than ripping a slightly wider board.
                if abs(lhs.thicknessMM - rhs.thicknessMM) > 0.01 {
                    return lhs.thicknessMM < rhs.thicknessMM
                }
                let leftArea = lhs.thicknessMM * lhs.widthMM
                let rightArea = rhs.thicknessMM * rhs.widthMM
                if abs(leftArea - rightArea) > 0.01 { return leftArea < rightArea }
                return lhs.widthMM < rhs.widthMM
            }
    }

    private static func failureReason(
        for part: ProjectPart,
        stocks: [StockBoard],
        trim: Double
    ) -> String {
        let sameMaterial = stocks.filter { $0.material == part.material }
        guard !sameMaterial.isEmpty else {
            return part.material == .plywood
                ? "No plywood stock added."
                : "No solid stock added."
        }
        if sameMaterial.allSatisfy({ $0.lengthMM - 2 * trim < part.boardLengthMM }) {
            return "Every board is too short."
        }
        if sameMaterial.allSatisfy({ $0.widthMM < part.boardWidthMM }) {
            return "No board is wide enough."
        }
        if sameMaterial.allSatisfy({ $0.thicknessMM < part.thicknessMM }) {
            return "No board is thick enough."
        }
        return "No single board matches all three dimensions."
    }

    // MARK: - Packing

    private static func pack(
        items: [Item],
        stock: StockBoard,
        trim: Double,
        kerf: Double
    ) -> [BenchPlan.Board] {
        let usableLength = stock.lengthMM - 2 * trim
        guard usableLength > 0, stock.widthMM > 0 else { return [] }

        var groups: [Double: [Item]] = [:]
        for item in items {
            groups[item.part.boardWidthMM, default: []].append(item)
        }
        for key in Array(groups.keys) {
            groups[key]?.sort { $0.part.boardLengthMM > $1.part.boardLengthMM }
        }
        let widths = groups.keys.sorted(by: >)

        var boards: [BenchPlan.Board] = []
        var boardGuard = 0

        while groups.values.contains(where: { !$0.isEmpty }) {
            boardGuard += 1
            if boardGuard > 400 { break }

            var strips: [BenchPlan.Strip] = []
            var remainingWidth = stock.widthMM
            var stripGuard = 0

            while true {
                stripGuard += 1
                if stripGuard > 60 { break }

                let width = widths.first { width in
                    width <= remainingWidth + 0.01 && !(groups[width]?.isEmpty ?? true)
                }
                guard let width else { break }

                let stripCapacity = Int(floor((remainingWidth + kerf) / (width + kerf)))
                guard stripCapacity > 0 else { break }

                var newStrips: [BenchPlan.Strip] = []
                var leftovers: [Item] = []

                for item in groups[width] ?? [] {
                    var placed = false
                    for index in newStrips.indices {
                        let gap = newStrips[index].parts.isEmpty ? 0 : kerf
                        if newStrips[index].usedLengthMM + gap + item.part.boardLengthMM <= usableLength + 0.01 {
                            newStrips[index].parts.append(placedPart(item))
                            newStrips[index].usedLengthMM += gap + item.part.boardLengthMM
                            placed = true
                            break
                        }
                    }
                    if !placed {
                        if newStrips.count < stripCapacity {
                            var newStrip = BenchPlan.Strip(
                                id: UUID().uuidString,
                                widthMM: width
                            )
                            newStrip.parts.append(placedPart(item))
                            newStrip.usedLengthMM = item.part.boardLengthMM
                            newStrips.append(newStrip)
                        } else {
                            leftovers.append(item)
                        }
                    }
                }

                groups[width] = leftovers
                guard !newStrips.isEmpty else { break }

                let usedStripCount = newStrips.count
                let gapBefore = strips.isEmpty ? 0 : kerf
                let consumed = Double(usedStripCount) * width
                    + Double(max(0, usedStripCount - 1)) * kerf
                    + gapBefore
                remainingWidth -= consumed
                strips.append(contentsOf: newStrips)
            }

            guard !strips.isEmpty else { break }

            let usedWidth = strips.reduce(0.0) { $0 + $1.widthMM }
                + Double(max(0, strips.count - 1)) * kerf
            let usedLength = strips.map(\.usedLengthMM).max() ?? 0
            boards.append(
                BenchPlan.Board(
                    id: UUID().uuidString,
                    stockID: stock.id,
                    stockLabel: stock.label,
                    material: stock.material,
                    thicknessMM: stock.thicknessMM,
                    widthMM: stock.widthMM,
                    lengthMM: stock.lengthMM,
                    pricePerBoardFoot: stock.pricePerBoardFoot,
                    strips: strips,
                    usedWidthMM: usedWidth,
                    usedLengthMM: usedLength
                )
            )
        }

        return boards
    }

    private static func placedPart(_ item: Item) -> BenchPlan.PlacedPart {
        BenchPlan.PlacedPart(
            id: UUID().uuidString,
            partID: item.part.id,
            name: item.part.name,
            lengthMM: item.part.boardLengthMM,
            widthMM: item.part.boardWidthMM,
            thicknessMM: item.part.thicknessMM,
            colorIndex: item.colorIndex
        )
    }
}
