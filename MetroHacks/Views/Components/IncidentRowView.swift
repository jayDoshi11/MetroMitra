import SwiftUI
import UIKit

struct IncidentRowView: View {
    let incident: Incident
    let now: Date
    let policy: EscalationPolicy

    private var overdue: Bool { policy.isOverdue(incident, now: now) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let data = incident.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(tr(incident.station)).font(.headline)
                    Spacer()
                    Label(
                        incident.isSynced ? tr("Synced") : tr("Pending"),
                        systemImage: incident.isSynced ? "checkmark.icloud" : "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(incident.isSynced ? .green : .orange)
                }

                HStack(spacing: 6) {
                    Image(systemName: incident.category.systemImage)
                    Text(incident.category.localizedTitle)
                    Text("·")
                    Text(incident.severity.localizedTitle)
                        .foregroundStyle(incident.severity.color)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)

                if !incident.note.isEmpty {
                    Text(incident.note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    Label(incident.status.localizedTitle, systemImage: incident.status.systemImage)
                        .foregroundStyle(incident.status == .resolved ? .green : .secondary)
                    if let team = incident.assignedTo {
                        Text("→ " + ResponseTeam.display(team))
                    }
                    if incident.source == .passenger {
                        Label(tr("Passenger"), systemImage: "person.wave.2")
                    }
                    if incident.reportCount > 1 {
                        Label(trf("%d reports", incident.reportCount), systemImage: "person.3.fill")
                            .foregroundStyle(.red)
                    }
                    if incident.autoTriaged {
                        Image(systemName: "sparkles").foregroundStyle(.purple)
                    }
                    if incident.latitude != nil {
                        Image(systemName: "location.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if incident.status != .resolved {
                    slaLabel
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var slaLabel: some View {
        let minutes = Int((abs(policy.secondsRemaining(incident, now: now)) / 60).rounded(.up))
        if overdue {
            Label(trf("Overdue by %d min", minutes), systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.red)
                .symbolEffect(.pulse)
        } else {
            Label(trf("SLA: %d min left", minutes), systemImage: "timer")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
