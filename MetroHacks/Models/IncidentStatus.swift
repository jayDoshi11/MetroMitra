import Foundation

enum IncidentStatus: String, Codable, CaseIterable, Identifiable {
    case open = "Open"
    case assigned = "Assigned"
    case resolved = "Resolved"

    var id: String { rawValue }
    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .open: "circle"
        case .assigned: "person.fill.checkmark"
        case .resolved: "checkmark.circle.fill"
        }
    }
}
