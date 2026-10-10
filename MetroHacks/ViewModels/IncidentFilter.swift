import Foundation

enum IncidentFilter: String, CaseIterable, Identifiable {
    case active = "Active"
    case overdue = "Overdue"
    case resolved = "Resolved"
    case all = "All"

    var id: String { rawValue }
}
