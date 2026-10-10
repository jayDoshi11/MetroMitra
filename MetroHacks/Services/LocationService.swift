import Foundation
import CoreLocation
import Observation

/// One-shot GPS fix. GPS works without mobile data, so this is safe offline.
@Observable
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    private(set) var latitude: Double?
    private(set) var longitude: Double?
    private(set) var isLocating = false
    private(set) var failed = false
    private(set) var denied = false
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// True when the user has refused (or the device restricts) location for this app.
    var isDeniedNow: Bool {
        manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted
    }

    func requestLocation() {
        isLocating = true
        failed = false
        denied = false
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            isLocating = false
            denied = true
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        Task { @MainActor in
            self.latitude = lat
            self.longitude = lon
            self.isLocating = false
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLocating = false
            self.failed = true
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard self.isLocating else { return }
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            } else if status != .notDetermined {
                self.isLocating = false
                self.denied = true
            }
        }
    }
}
