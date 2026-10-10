import SwiftUI

struct StationDetailView: View {
    let stationName: String
    let viewModel: IncidentListViewModel

    private var matching: [Incident] {
        let key = StationDirectory.key(stationName)
        return viewModel.incidents.filter { StationDirectory.key($0.station) == key }
    }

    private var active: [Incident] {
        matching
            .filter { $0.status != .resolved }
            .sorted { $0.severity.rank > $1.severity.rank }
    }

    private var recentlyFixed: [Incident] {
        Array(
            matching
                .filter { $0.status == .resolved }
                .sorted { ($0.resolvedAt ?? .distantPast) > ($1.resolvedAt ?? .distantPast) }
                .prefix(3)
        )
    }

    var body: some View {
        List {
            if let lines = StationDirectory.match(name: stationName)?.interchanges, !lines.isEmpty {
                Section(tr("Interchange")) {
                    ForEach(lines, id: \.self) { line in
                        Label(trf("Change here for the %@", tr(line)), systemImage: "arrow.triangle.swap")
                    }
                }
            }
            Section(tr("Right now")) {
                if active.isEmpty {
                    Label(tr("No known issues"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    ForEach(active) { incident in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: incident.category.systemImage)
                                .foregroundStyle(incident.severity.color)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(incident.category.passengerMessage).font(.headline)
                                if !incident.note.isEmpty {
                                    Text(incident.note).font(.subheadline).foregroundStyle(.secondary)
                                }
                                HStack(spacing: 4) {
                                    Text(tr("Reported"))
                                    Text(incident.createdAt, style: .relative)
                                    Text(tr("ago"))
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                if incident.reportCount > 1 {
                                    Label(trf("%d passengers reported this", incident.reportCount), systemImage: "person.3.fill")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                                if let team = incident.assignedTo {
                                    Label(trf("Team assigned: %@", team), systemImage: "person.fill.checkmark")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if !recentlyFixed.isEmpty {
                Section(tr("Recently fixed")) {
                    ForEach(recentlyFixed) { incident in
                        Label(incident.category.passengerMessage, systemImage: "checkmark.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                NavigationLink {
                    PassengerReportForm(listViewModel: viewModel, initialStation: stationName)
                } label: {
                    Label(tr("Report a problem at this station"), systemImage: "exclamationmark.bubble")
                }
            }
        }
        .navigationTitle(tr(stationName))
        .navigationBarTitleDisplayMode(.inline)
    }
}
