import Foundation
import CoreLocation

/// Bundled station list (Resources/Stations.json).
/// Coordinates are APPROXIMATE (interpolated along each line). When online, Apple Maps
/// results are used instead (see StationResolver). Edit the JSON to refine them.
enum StationDirectory {
    static let all: [Station] = {
        guard
            let url = Bundle.main.url(forResource: "Stations", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let stations = try? JSONDecoder().decode([Station].self, from: data)
        else { return [] }
        return stations
    }()

    /// Normalised key so "Mahatma Mandir Metro Station", "mahatma mandir" and "Sector-24" all match.
    static func key(_ name: String) -> String {
        var s = name.lowercased()
        for junk in ["metro station", "metro", "station", "(gandhinagar)"] {
            s = s.replacingOccurrences(of: junk, with: "")
        }
        s = s.replacingOccurrences(of: "-", with: " ")
        return s.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).joined(separator: " ")
    }

    static func match(name: String) -> Station? {
        let k = key(name)
        return all.first { key($0.name) == k }
    }

    static func contains(_ name: String) -> Bool {
        match(name: name) != nil
    }

    static func cleaned(_ name: String) -> String {
        name.replacingOccurrences(of: " Metro Station", with: "")
            .replacingOccurrences(of: " Metro", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func nearest(latitude: Double, longitude: Double) -> (station: Station, distanceMeters: Double)? {
        let here = CLLocation(latitude: latitude, longitude: longitude)
        return all
            .map { ($0, here.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))) }
            .min { $0.1 < $1.1 }
            .map { (station: $0.0, distanceMeters: $0.1) }
    }
}
