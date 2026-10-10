import Foundation

enum StationHealth {
    case normal, minor, disrupted
}

struct StationStatus: Identifiable {
    let name: String
    let health: StationHealth
    let activeCount: Int
    var interchanges: [String] = []
    var id: String { name }
}

struct StationLineSection: Identifiable {
    let line: String
    let stations: [StationStatus]
    var id: String { line }
}

/// Passenger-facing view of the control room's data: a station is Disrupted when it has an
/// unresolved high-severity incident, and has Minor issues when it has any other unresolved one.
struct StationStatusViewModel {
    let sections: [StationLineSection]
    let affectedCount: Int

    init(incidents: [Incident]) {
        var activeByKey: [String: [Incident]] = [:]
        for incident in incidents where incident.status != .resolved {
            activeByKey[StationDirectory.key(incident.station), default: []].append(incident)
        }

        var used = Set<String>()
        var lineOrder: [String] = []
        var byLine: [String: [StationStatus]] = [:]

        for station in StationDirectory.all {
            let key = StationDirectory.key(station.name)
            used.insert(key)
            let items = activeByKey[key] ?? []
            if byLine[station.line] == nil { lineOrder.append(station.line) }
            byLine[station.line, default: []].append(
                StationStatus(name: station.name, health: Self.health(of: items), activeCount: items.count, interchanges: station.interchanges ?? [])
            )
        }

        var result = lineOrder.map { StationLineSection(line: $0, stations: byLine[$0] ?? []) }

        // Incidents logged against a station that isn't in the bundled list.
        let extras = activeByKey
            .filter { !used.contains($0.key) }
            .compactMap { entry -> StationStatus? in
                guard let first = entry.value.first else { return nil }
                return StationStatus(name: first.station, health: Self.health(of: entry.value), activeCount: entry.value.count)
            }
            .sorted { $0.name < $1.name }
        if !extras.isEmpty {
            result.append(StationLineSection(line: "Other stations", stations: extras))
        }

        sections = result
        affectedCount = Set(result.flatMap(\.stations).filter { $0.health != .normal }.map { StationDirectory.key($0.name) }).count
    }

    private static func health(of items: [Incident]) -> StationHealth {
        if items.isEmpty { return .normal }
        return items.contains { $0.severity == .high } ? .disrupted : .minor
    }
}
