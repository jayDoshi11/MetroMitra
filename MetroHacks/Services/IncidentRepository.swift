import Foundation
import SwiftData

/// Single place that talks to SwiftData. ViewModels never touch ModelContext directly.
@MainActor
final class IncidentRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() -> [Incident] {
        let descriptor = FetchDescriptor<Incident>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func add(_ incident: Incident) {
        context.insert(incident)
        update()
    }

    func addAll(_ incidents: [Incident]) {
        incidents.forEach(context.insert)
        update()
    }

    func markSynced(_ incident: Incident) {
        incident.isSynced = true
        update()
    }

    func delete(_ incident: Incident) {
        context.delete(incident)
        update()
    }

    func deleteAll() {
        fetchAll().forEach(context.delete)
        update()
    }

    /// Persists any in-place changes made to models.
    func update() {
        try? context.save()
    }
}
