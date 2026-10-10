import Foundation

struct CategoryCount: Identifiable {
    let category: IncidentCategory
    let count: Int
    var id: IncidentCategory { category }
}

struct SeverityCount: Identifiable {
    let severity: Severity
    let count: Int
    var id: Severity { severity }
}

struct StatusCount: Identifiable {
    let status: IncidentStatus
    let count: Int
    var id: IncidentStatus { status }
}

struct DashboardViewModel {
    let total: Int
    let open: Int
    let overdue: Int
    let resolved: Int
    let averageFixMinutes: Int?
    let categoryCounts: [CategoryCount]
    let severityCounts: [SeverityCount]
    let statusCounts: [StatusCount]

    init(incidents: [Incident], policy: EscalationPolicy, now: Date) {
        total = incidents.count
        open = incidents.filter { $0.status != .resolved }.count
        overdue = incidents.filter { policy.isOverdue($0, now: now) }.count
        resolved = incidents.filter { $0.status == .resolved }.count

        let durations = incidents.compactMap { incident -> TimeInterval? in
            guard incident.status == .resolved, let done = incident.resolvedAt else { return nil }
            return done.timeIntervalSince(incident.createdAt)
        }
        averageFixMinutes = durations.isEmpty ? nil : Int(durations.reduce(0, +) / Double(durations.count) / 60)

        categoryCounts = IncidentCategory.allCases
            .map { category in CategoryCount(category: category, count: incidents.filter { $0.category == category }.count) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
        severityCounts = Severity.allCases
            .map { severity in SeverityCount(severity: severity, count: incidents.filter { $0.severity == severity }.count) }
            .filter { $0.count > 0 }
        statusCounts = IncidentStatus.allCases
            .map { status in StatusCount(status: status, count: incidents.filter { $0.status == status }.count) }
            .filter { $0.count > 0 }
    }
}
