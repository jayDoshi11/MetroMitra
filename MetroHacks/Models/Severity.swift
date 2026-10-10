import Foundation

enum Severity: String, Codable, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    /// Higher number = more urgent. Used for sorting.
    var rank: Int {
        switch self {
        case .low: 0
        case .medium: 1
        case .high: 2
        }
    }
}
