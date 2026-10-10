import Foundation
import CoreLocation
import MapKit

struct ResolvedStation: Equatable {
    enum Source { case maps, offline }

    let name: String
    let distanceMeters: Double
    let source: Source

    var isNearby: Bool { distanceMeters <= StationResolver.nearbyMeters }

    var distanceText: String {
        distanceMeters < 1000
            ? "\(Int(distanceMeters.rounded())) m"
            : String(format: "%.1f km", distanceMeters / 1000)
    }
}

/// Finds the nearest metro station to a GPS fix using the bundled station list
/// (real coordinates, works fully offline). Apple Maps search is NOT used: it returns
/// random places with "metro" in the name (e.g. public toilets).
struct StationResolver {
    /// Within this distance a station is auto-filled; further away we only suggest it.
    static let nearbyMeters: Double = 2000

    func nearest(latitude: Double, longitude: Double) -> ResolvedStation? {
        guard let n = StationDirectory.nearest(latitude: latitude, longitude: longitude) else { return nil }
        return ResolvedStation(name: n.station.name, distanceMeters: n.distanceMeters, source: .offline)
    }
}
