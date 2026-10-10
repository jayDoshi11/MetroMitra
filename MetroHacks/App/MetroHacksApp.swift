import SwiftUI
import SwiftData

@main
struct MetroHacksApp: App {
    private let container: ModelContainer
    @State private var viewModel: IncidentListViewModel

    init() {
        do {
            let container = try ModelContainer(for: Incident.self)
            self.container = container
            let repository = IncidentRepository(context: container.mainContext)
            _viewModel = State(initialValue: IncidentListViewModel(repository: repository))
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRoot(viewModel: viewModel)
        }
        .modelContainer(container)
    }
}
