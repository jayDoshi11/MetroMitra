import Foundation

/// Pushes a single incident to the backend.
/// Demo implementation: simulates latency. Replace the body with a real URLSession POST.
@MainActor
struct SyncService {
    func push(_ incident: Incident) async throws {
        try await Task.sleep(for: .milliseconds(400))
    }
}
