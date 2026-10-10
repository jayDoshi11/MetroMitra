import SwiftUI
import Charts

struct DashboardView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.total == 0 {
                    ContentUnavailableView(
                        tr("No data yet"),
                        systemImage: "chart.bar",
                        description: Text(tr("Log incidents or load sample data to see charts."))
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 10) {
                                StatTile(title: tr("Open"), value: "\(viewModel.open)", color: .blue)
                                StatTile(title: tr("Overdue"), value: "\(viewModel.overdue)", color: .red)
                                StatTile(title: tr("Resolved"), value: "\(viewModel.resolved)", color: .green)
                                StatTile(
                                    title: tr("Avg fix"),
                                    value: viewModel.averageFixMinutes.map { "\($0)m" } ?? "–",
                                    color: .purple
                                )
                            }

                            card(tr("By status")) {
                                Chart(viewModel.statusCounts) { item in
                                    BarMark(
                                        x: .value("Count", item.count),
                                        y: .value("Status", item.status.localizedTitle)
                                    )
                                    .foregroundStyle(by: .value("Status", item.status.localizedTitle))
                                    .annotation(position: .trailing) {
                                        Text("\(item.count)").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                .chartForegroundStyleScale([
                                    IncidentStatus.open.localizedTitle: Color.blue,
                                    IncidentStatus.assigned.localizedTitle: Color.orange,
                                    IncidentStatus.resolved.localizedTitle: Color.green
                                ])
                                .chartLegend(.hidden)
                                .frame(height: CGFloat(viewModel.statusCounts.count) * 40 + 20)
                            }

                            card(tr("By category")) {
                                Chart(viewModel.categoryCounts) { item in
                                    BarMark(
                                        x: .value("Count", item.count),
                                        y: .value("Category", item.category.localizedTitle)
                                    )
                                    .foregroundStyle(.blue.gradient)
                                    .annotation(position: .trailing) {
                                        Text("\(item.count)").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                .frame(height: CGFloat(viewModel.categoryCounts.count) * 40 + 20)
                            }

                            card(tr("By severity")) {
                                Chart(viewModel.severityCounts) { item in
                                    SectorMark(
                                        angle: .value("Count", item.count),
                                        innerRadius: .ratio(0.55),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(by: .value("Severity", item.severity.localizedTitle))
                                }
                                .chartForegroundStyleScale([
                                    Severity.low.localizedTitle: Color.green,
                                    Severity.medium.localizedTitle: Color.orange,
                                    Severity.high.localizedTitle: Color.red
                                ])
                                .frame(height: 220)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(tr("Control room"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(tr("Done")) { dismiss() }
            }
        }
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }
}
