import Foundation

/// Loads realistic sample incidents from Resources/SeedIncidents.json.
/// Edit that JSON to match the problem statement you pick.
struct SeedDataService {
    private struct Record: Decodable {
        let station: String
        let category: IncidentCategory
        let severity: Severity
        let note: String
        let minutesAgo: Int
        let synced: Bool
        let status: IncidentStatus?
        let assignedTo: String?
        let resolvedAfterMinutes: Int?
        let source: IncidentSource?
        let latitude: Double?
        let longitude: Double?
    }

    @MainActor
    func insertSamples(into repository: IncidentRepository) {
        guard
            let url = Bundle.main.url(forResource: "SeedIncidents", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let records = try? JSONDecoder().decode([Record].self, from: data)
        else { return }

        let incidents = records.map { r -> Incident in
            let created = Date().addingTimeInterval(TimeInterval(-r.minutesAgo * 60))
            let resolvedAt = r.resolvedAfterMinutes.map { created.addingTimeInterval(TimeInterval($0 * 60)) }
            return Incident(
                station: r.station,
                category: r.category,
                severity: r.severity,
                note: r.note,
                createdAt: created,
                isSynced: r.synced,
                latitude: r.latitude,
                longitude: r.longitude,
                status: r.status ?? .open,
                assignedTo: r.assignedTo,
                resolvedAt: resolvedAt,
                source: r.source ?? .staff
            )
        }
        repository.addAll(incidents)
    }
}
