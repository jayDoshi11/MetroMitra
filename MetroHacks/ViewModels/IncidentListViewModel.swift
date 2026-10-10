import Foundation
import Observation

@Observable
@MainActor
final class IncidentListViewModel {
    private(set) var incidents: [Incident] = []
    private(set) var isSyncing = false

    var filter: IncidentFilter = .active
    var demoMode = false {
        didSet { NotificationService.shared.reschedule(incidents: incidents, policy: policy) }
    }

    let network: NetworkMonitor
    let repository: IncidentRepository
    private let syncService: SyncService

    var policy: EscalationPolicy { EscalationPolicy(demoMode: demoMode) }
    var pendingCount: Int { incidents.filter { !$0.isSynced }.count }
    var isOnline: Bool { network.isOnline }

    init(
        repository: IncidentRepository,
        syncService: SyncService? = nil,
        network: NetworkMonitor? = nil
    ) {
        self.repository = repository
        self.syncService = syncService ?? SyncService()
        self.network = network ?? NetworkMonitor()
    }

    // MARK: - Loading

    func load() {
        incidents = repository.fetchAll()
        NotificationService.shared.reschedule(incidents: incidents, policy: policy)
    }

    func loadSampleData() {
        SeedDataService().insertSamples(into: repository)
        load()
        Task { await syncPending() }
    }

    func deleteAll() {
        repository.deleteAll()
        load()
    }

    func delete(_ items: [Incident]) {
        items.forEach(repository.delete)
        load()
    }

    // MARK: - Queries

    func overdueCount(now: Date) -> Int {
        incidents.filter { policy.isOverdue($0, now: now) }.count
    }

    /// Filtered list, most urgent first: overdue, then severity, then newest.
    func visibleIncidents(now: Date) -> [Incident] {
        let policy = self.policy
        let filtered = incidents.filter { incident in
            switch filter {
            case .active: incident.status != .resolved
            case .overdue: policy.isOverdue(incident, now: now)
            case .resolved: incident.status == .resolved
            case .all: true
            }
        }
        return filtered.sorted { a, b in
            let aOver = policy.isOverdue(a, now: now)
            let bOver = policy.isOverdue(b, now: now)
            if aOver != bOver { return aOver }
            if a.severity.rank != b.severity.rank { return a.severity.rank > b.severity.rank }
            return a.createdAt > b.createdAt
        }
    }

    // MARK: - Workflow

    func assign(_ incident: Incident, to team: ResponseTeam) {
        incident.assignedTo = team.rawValue
        if incident.status == .open { incident.status = .assigned }
        touch(incident)
    }

    func resolve(_ incident: Incident) {
        incident.status = .resolved
        incident.resolvedAt = .now
        touch(incident)
    }

    func reopen(_ incident: Incident) {
        incident.status = incident.assignedTo == nil ? .open : .assigned
        incident.resolvedAt = nil
        touch(incident)
    }

    /// Any change must be pushed again, so mark it pending and let the queue sync it.
    private func touch(_ incident: Incident) {
        incident.isSynced = false
        repository.update()
        load()
        Task { await syncPending() }
    }

    // MARK: - Sync

    /// Pushes every unsynced incident, oldest first. Safe to call repeatedly.
    func syncPending() async {
        guard network.isOnline, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let queue = incidents.filter { !$0.isSynced }.reversed()
        for incident in queue {
            guard network.isOnline else { break }
            do {
                try await syncService.push(incident)
                repository.markSynced(incident)
            } catch {
                break // leave remaining items pending; retried on next sync
            }
        }
        load()
    }
}
