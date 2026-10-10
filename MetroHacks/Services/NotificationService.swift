import Foundation
import UserNotifications

/// Local notifications for SLA breaches. Scheduled on device, so they fire with no network.
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Re-creates one notification per open incident, firing at its SLA deadline.
    @MainActor
    func reschedule(incidents: [Incident], policy: EscalationPolicy) {
        center.removeAllPendingNotificationRequests()
        let now = Date()
        for incident in incidents where incident.status != .resolved {
            let wait = policy.deadline(for: incident).timeIntervalSince(now)
            guard wait > 1 else { continue }

            let content = UNMutableNotificationContent()
            content.title = "SLA breached · \(incident.severity.title) priority"
            content.body = "\(incident.category.title) at \(incident.station) is past its \(Int(policy.slaMinutes(for: incident.severity))) min target."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: wait, repeats: false)
            center.add(UNNotificationRequest(identifier: incident.id.uuidString, content: content, trigger: trigger))
        }
    }

    // Show the banner even while the app is open (needed for the live demo).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
