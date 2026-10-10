import SwiftUI

/// Passenger-facing station status, built from the control room's live data.
struct StationStatusView: View {
    let viewModel: IncidentListViewModel
    @State private var onlyAffected = false

    var body: some View {
        let status = StationStatusViewModel(incidents: viewModel.incidents)

        NavigationStack {
            List {
                Section {
                    if status.affectedCount == 0 {
                        Label(tr("All stations running normally"), systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.headline)
                    } else {
                        Label(
                            trf(status.affectedCount == 1 ? "%d station affected" : "%d stations affected", status.affectedCount),
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                        .font(.headline)
                    }
                    Toggle(tr("Show only affected stations"), isOn: $onlyAffected)
                }

                ForEach(status.sections) { section in
                    let rows = onlyAffected ? section.stations.filter { $0.health != .normal } : section.stations
                    if !rows.isEmpty {
                        Section(tr(section.line)) {
                            ForEach(rows) { station in
                                NavigationLink {
                                    StationDetailView(stationName: station.name, viewModel: viewModel)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(tr(station.name))
                                            if !station.interchanges.isEmpty {
                                                Label(trf("Interchange: %@", station.interchanges.map { tr($0) }.joined(separator: ", ")),
                                                      systemImage: "arrow.triangle.swap")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Label(station.health.title, systemImage: station.health.systemImage)
                                            .font(.caption)
                                            .foregroundStyle(station.health.color)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(tr("Station status"))
            .toolbar { ToolbarItem(placement: .topBarTrailing) { LanguageMenu() } }
            .task { viewModel.load() }
        }
    }
}
