import Foundation

enum IncidentCategory: String, Codable, CaseIterable, Identifiable {
    case escalator = "Escalator fault"
    case ticketGate = "Ticket gate"
    case lighting = "Lighting"
    case crowding = "Crowding"
    case cleanliness = "Cleanliness"
    case safety = "Safety"

    var id: String { rawValue }
    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .escalator: "arrow.up.right.circle"
        case .ticketGate: "ticket"
        case .lighting: "lightbulb"
        case .crowding: "person.3"
        case .cleanliness: "sparkles"
        case .safety: "exclamationmark.shield"
        }
    }
}
