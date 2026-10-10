import Foundation
import CoreLocation
import UserNotifications
import UIKit
import Observation

enum PermissionState { case notAsked, granted, denied }

enum SystemSettings {
    /// Opens this app's page in the iOS Settings app.
    @MainActor static func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

/// Asks for location + notification permission during onboarding and reports the real result.
@Observable
@MainActor
final class PermissionManager: NSObject, CLLocationManagerDelegate {
    private(set) var location: PermissionState = .notAsked
    private(set) var notifications: PermissionState = .notAsked
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        refresh()
    }

    /// Re-reads both permissions (also call when returning from Settings).
    func refresh() {
        location = Self.locationState(manager.authorizationStatus)
        Task {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            notifications = Self.notificationState(status)
        }
    }

    func requestLocation() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            refresh()
        }
    }

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in self.notifications = granted ? .granted : .denied }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let state = Self.locationState(manager.authorizationStatus)
        Task { @MainActor in self.location = state }
    }

    nonisolated private static func locationState(_ status: CLAuthorizationStatus) -> PermissionState {
        switch status {
        case .notDetermined: .notAsked
        case .authorizedWhenInUse, .authorizedAlways: .granted
        default: .denied
        }
    }

    nonisolated private static func notificationState(_ status: UNAuthorizationStatus) -> PermissionState {
        switch status {
        case .notDetermined: .notAsked
        case .denied: .denied
        default: .granted
        }
    }
}
