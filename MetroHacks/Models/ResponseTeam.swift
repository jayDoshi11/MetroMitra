import Foundation

enum ResponseTeam: String, Codable, CaseIterable, Identifiable {
    case mechanical = "Mechanical"
    case electrical = "Electrical"
    case housekeeping = "Housekeeping"
    case security = "Security"
    case stationController = "Station Controller"

    var id: String { rawValue }

    /// Default team that handles each kind of incident.
    static func suggested(for category: IncidentCategory) -> ResponseTeam {
        switch category {
        case .escalator: .mechanical
        case .ticketGate: .stationController
        case .lighting: .electrical
        case .crowding: .security
        case .cleanliness: .housekeeping
        case .safety: .security
        }
    }
}
