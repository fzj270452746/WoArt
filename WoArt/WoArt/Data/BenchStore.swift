import Foundation

extension Notification.Name {
    static let benchDidChange = Notification.Name("woart.benchDidChange")
}

final class BenchStore {
    static let shared = BenchStore()

    private(set) var projects: [BenchProject] = []
    private(set) var activeProjectID: String?
    private(set) var defaultUnit: BenchUnit = .metric

    private let fileURL: URL

    private struct Archive: Codable {
        var projects: [BenchProject]
        var activeProjectID: String?
        var defaultUnit: BenchUnit
    }

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("WoArt", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("bench.json")

        if
            let data = try? Data(contentsOf: fileURL),
            let archive = try? JSONDecoder().decode(Archive.self, from: data)
        {
            projects = archive.projects
            activeProjectID = archive.activeProjectID
            defaultUnit = archive.defaultUnit
        }

        if let activeProjectID, !projects.contains(where: { $0.id == activeProjectID }) {
            self.activeProjectID = nil
        }
        if self.activeProjectID == nil {
            self.activeProjectID = sortedProjects.first?.id
        }
    }

    // MARK: - Reads

    var sortedProjects: [BenchProject] {
        projects.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// The active project leads the list, then the most recently touched.
    var orderedProjects: [BenchProject] {
        sortedProjects.sorted { lhs, rhs in
            if lhs.id == activeProjectID { return true }
            if rhs.id == activeProjectID { return false }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    var activeProject: BenchProject? {
        guard let activeProjectID else { return nil }
        return project(id: activeProjectID)
    }

    func project(id: String) -> BenchProject? {
        projects.first { $0.id == id }
    }

    func index(of id: String) -> Int? {
        projects.firstIndex { $0.id == id }
    }

    // MARK: - Writes

    @discardableResult
    func createProject(
        title: String,
        speciesID: String,
        template: BenchTemplate?,
        unit: BenchUnit
    ) -> BenchProject {
        var project = template?.makeProject(unit: unit)
            ?? BenchProject(title: title, speciesID: speciesID, unit: unit)
        let trimmed = title.trimmed
        project.title = trimmed.isEmpty
            ? (template?.defaultTitle ?? "Untitled project")
            : trimmed
        project.speciesID = speciesID
        project.unit = unit
        project.createdAt = Date()
        project.updatedAt = Date()
        projects.insert(project, at: 0)
        activeProjectID = project.id
        defaultUnit = unit
        commit()
        return project
    }

    func update(_ project: BenchProject, touch: Bool = true, notify: Bool = true) {
        guard let index = index(of: project.id) else { return }
        var copy = project
        if touch { copy.updatedAt = Date() }
        projects[index] = copy
        if notify {
            commit()
        } else {
            persist()
        }
    }

    func setActive(id: String) {
        guard projects.contains(where: { $0.id == id }) else { return }
        guard activeProjectID != id else { return }
        activeProjectID = id
        commit()
    }

    func setDefaultUnit(_ unit: BenchUnit) {
        guard defaultUnit != unit else { return }
        defaultUnit = unit
        commit()
    }

    @discardableResult
    func duplicateProject(id: String) -> BenchProject? {
        guard var copy = project(id: id) else { return nil }
        copy.id = UUID().uuidString
        copy.title = "\(copy.title) copy"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.parts = copy.parts.map { part in
            var part = part
            part.id = UUID().uuidString
            return part
        }
        copy.steps = copy.steps.map { step in
            var step = step
            step.id = UUID().uuidString
            step.isDone = false
            return step
        }
        copy.stock = copy.stock.map { stock in
            var stock = stock
            stock.id = UUID().uuidString
            return stock
        }
        projects.insert(copy, at: 0)
        commit()
        return copy
    }

    func deleteProject(id: String) {
        projects.removeAll { $0.id == id }
        if activeProjectID == id {
            activeProjectID = sortedProjects.first?.id
        }
        commit()
    }

    // MARK: - Persistence

    private func commit() {
        persist()
        NotificationCenter.default.post(name: .benchDidChange, object: nil)
    }

    private func persist() {
        let archive = Archive(
            projects: projects,
            activeProjectID: activeProjectID,
            defaultUnit: defaultUnit
        )
        guard let data = try? JSONEncoder().encode(archive) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
