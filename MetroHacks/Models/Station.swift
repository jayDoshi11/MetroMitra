import Foundation

struct Station: Identifiable, Codable {
    let name: String
    let line: String
    let latitude: Double
    let longitude: Double
    /// Other lines you can change to at this station (interchange / cross-platform).
    var interchanges: [String]? = nil

    var id: String { "\(line)|\(name)" }
}
