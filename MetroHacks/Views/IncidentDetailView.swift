import SwiftUI
import UIKit

struct IncidentDetailView: View {
    let incident: Incident
    let viewModel: IncidentListViewModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 10)) { context in
            let now = context.date
            let overdue = viewModel.policy.isOverdue(incident, now: now)

            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tr(incident.station)).font(.title2.bold())
                        HStack(spacing: 6) {
                            Image(systemName: incident.category.systemImage)
                            Text(incident.category.localizedTitle)
                            Text("·")
                            Text(incident.severity.localizedTitle)
                                .foregroundStyle(incident.severity.color)
                                .fontWeight(.semibold)
                        }
                        if overdue {
                            Label(tr("Escalated: past SLA"), systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.subheadline.weight(.bold))
                        }
                        if !incident.note.isEmpty {
                            Text(incident.note).foregroundStyle(.secondary)
                        }
                    }
                    if let data = incident.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                Section(tr("Workflow")) {
                    LabeledContent(tr("Status")) {
                        Label(incident.status.localizedTitle, systemImage: incident.status.systemImage)
                    }

                    Menu {
                        ForEach(ResponseTeam.allCases) { team in
                            Button(team.localizedName) { viewModel.assign(incident, to: team) }
                        }
                    } label: {
                        LabeledContent(tr("Assigned to"), value: ResponseTeam.display(incident.assignedTo))
                    }

                    if incident.status == .resolved {
                        Button(tr("Reopen"), systemImage: "arrow.uturn.backward") {
                            viewModel.reopen(incident)
                        }
                    } else {
                        Button(tr("Mark resolved"), systemImage: "checkmark.circle.fill") {
                            viewModel.resolve(incident)
                        }
                        .tint(.green)
                    }
                }

                Section(tr("Details")) {
                    if incident.reportCount > 1 {
                        Label(trf("%d passengers reported this", incident.reportCount), systemImage: "person.3.fill")
                            .foregroundStyle(.red)
                    }
                    LabeledContent(tr("Reported")) {
                        Text(incident.createdAt, format: .dateTime.day().month().hour().minute())
                    }
                    if let done = incident.resolvedAt {
                        LabeledContent(tr("Resolved")) {
                            Text(done, format: .dateTime.day().month().hour().minute())
                        }
                    }
                    LabeledContent(tr("Sync"), value: incident.isSynced ? tr("Synced") : tr("Pending"))
                    if incident.autoTriaged {
                        Label(tr("Triaged automatically on device"), systemImage: "sparkles")
                            .foregroundStyle(.purple)
                    }
                    if let lat = incident.latitude, let lon = incident.longitude {
                        LabeledContent("GPS", value: String(format: "%.4f, %.4f", lat, lon))
                    }
                }
            }
        }
        .navigationTitle(tr("Incident"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
