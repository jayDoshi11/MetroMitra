import SwiftUI

struct RootTabView: View {
    let viewModel: IncidentListViewModel

    var body: some View {
        TabView {
            IncidentListView(viewModel: viewModel)
                .tabItem { Label(tr("Control"), systemImage: "gauge.with.dots.needle.67percent") }
            StationStatusView(viewModel: viewModel)
                .tabItem { Label(tr("Stations"), systemImage: "tram.fill") }
            PassengerReportView(viewModel: viewModel)
                .tabItem { Label(tr("Report"), systemImage: "exclamationmark.bubble.fill") }
            AssistantView(listViewModel: viewModel)
                .tabItem { Label(tr("Assistant"), systemImage: "sparkles") }
        }
    }
}
