import Foundation

/// SLA rules: how long an unresolved incident may stay open before it is escalated.
struct EscalationPolicy {
    /// Demo mode shrinks the SLAs to 1 / 2 / 5 minutes so escalation is visible live.
    var demoMode = false

    func slaMinutes(for severity: Severity) -> Double {
        switch (severity, demoMode) {
        case (.high, false): 10
        case (.medium, false): 30
        case (.low, false): 120
        case (.high, true): 1
        case (.medium, true): 2
        case (.low, true): 5
        }
    }

    func deadline(for incident: Incident) -> Date {
        incident.createdAt.addingTimeInterval(slaMinutes(for: incident.severity) * 60)
    }

    func isOverdue(_ incident: Incident, now: Date) -> Bool {
        incident.status != .resolved && now > deadline(for: incident)
    }

    /// Positive = time left, negative = overdue by that much.
    func secondsRemaining(_ incident: Incident, now: Date) -> TimeInterval {
        deadline(for: incident).timeIntervalSince(now)
    }
}
