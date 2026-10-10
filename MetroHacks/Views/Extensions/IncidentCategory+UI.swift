import SwiftUI

extension IncidentCategory {
    /// Plain-language wording for passengers.
    @MainActor var passengerMessage: String {
        switch self {
        case .escalator: tr("Escalator or lift may be unavailable")
        case .ticketGate: tr("Some ticket gates are affected")
        case .lighting: tr("Lighting is being repaired")
        case .crowding: tr("Platform is crowded")
        case .cleanliness: tr("Cleaning in progress")
        case .safety: tr("Safety check in progress")
        }
    }
}

extension StationHealth {
    @MainActor var title: String {
        switch self {
        case .normal: tr("Normal")
        case .minor: tr("Minor issues")
        case .disrupted: tr("Disrupted")
        }
    }

    var systemImage: String {
        switch self {
        case .normal: "checkmark.circle.fill"
        case .minor: "exclamationmark.circle.fill"
        case .disrupted: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .normal: .green
        case .minor: .orange
        case .disrupted: .red
        }
    }
}
