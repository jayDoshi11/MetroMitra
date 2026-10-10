import SwiftUI

extension Severity {
    var color: Color {
        switch self {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}
