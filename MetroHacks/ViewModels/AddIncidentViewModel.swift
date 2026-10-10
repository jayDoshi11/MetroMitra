import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

@Observable
@MainActor
final class AddIncidentViewModel {
    struct Submission {
        let station: String
        let category: IncidentCategory
        let severity: Severity
        let team: ResponseTeam?
        let queuedOffline: Bool
        var mergedCount: Int? = nil
    }

    let source: IncidentSource

    var note = ""
    var category: IncidentCategory = .escalator {
        didSet { categoryTouched = true }
    }
    var severity: Severity = .medium
    var team: ResponseTeam?

    private(set) var categoryTouched = false
    private(set) var autoTriaged = false
    private(set) var submitted: Submission?
    private(set) var detectedStation: ResolvedStation?
    private(set) var farStation: ResolvedStation?

    func selectFarStation() {
        if let far = farStation { manualStation = far.name }
    }
    private(set) var isResolvingStation = false

    var photoItem: PhotosPickerItem? {
        didSet { loadPhoto() }
    }
    private(set) var photoData: Data?

    private var manualStation: String?
    private var online = true
    private let location = LocationService()
    private let resolver = StationResolver()
    private let repository: IncidentRepository
    private let onSaved: () -> Void

    /// Station is auto-detected from GPS until the user picks one manually.
    var station: String {
        get { manualStation ?? detectedStation?.name ?? "" }
        set { manualStation = newValue.isEmpty ? nil : newValue }
    }

    var canSave: Bool { !station.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var canSubmit: Bool { canSave && (categoryTouched || suggestion?.category != nil) }
    var suggestion: TriageSuggestion? { TriageService.suggest(from: note) }
    var photoImage: UIImage? { photoData.flatMap(UIImage.init(data:)) }

    var latitude: Double? { location.latitude }
    var locationDenied: Bool { location.isDeniedNow }
    var isLocating: Bool { location.isLocating }
    var hasLocation: Bool { location.latitude != nil && location.longitude != nil }

    var locationMessage: String? {
        if location.denied { return tr("Location is off for this app. Enable it in Settings, or pick a station below.") }
        if location.failed { return tr("Couldn't get a GPS fix. Pick your station below.") }
        if hasLocation, detectedStation == nil, farStation == nil, !isResolvingStation {
            return tr("No metro station nearby. Pick one below.")
        }
        return nil
    }

    init(
        repository: IncidentRepository,
        source: IncidentSource = .staff,
        initialStation: String? = nil,
        onSaved: @escaping () -> Void
    ) {
        self.repository = repository
        self.source = source
        self.manualStation = initialStation
        self.onSaved = onSaved
    }

    // MARK: - Location → station

    func useMyLocation(isOnline: Bool) {
        online = isOnline
        manualStation = nil
        farStation = nil
        location.requestLocation()
        if hasLocation { Task { await resolveStation() } }
    }

    /// Nearest station from the bundled list. Auto-fills within 2 km, otherwise only suggests it.
    func resolveStation() async {
        guard let lat = location.latitude, let lon = location.longitude else { return }
        isResolvingStation = false
        guard let result = resolver.nearest(latitude: lat, longitude: lon) else { return }
        if result.isNearby {
            detectedStation = result
            farStation = nil
        } else {
            detectedStation = nil
            farStation = result
        }
    }

    // MARK: - Triage

    func applySuggestion() {
        guard let suggestion else { return }
        if let category = suggestion.category { self.category = category }
        severity = suggestion.severity
        team = suggestion.team
        autoTriaged = true
    }

    // MARK: - Photo

    func removePhoto() {
        photoItem = nil
    }

    private func loadPhoto() {
        guard let item = photoItem else {
            photoData = nil
            return
        }
        Task {
            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else { return }
            photoData = image.resized(maxDimension: 1024).jpegData(compressionQuality: 0.6)
        }
    }

    // MARK: - Save

    /// An unresolved incident for the same station + category reported in the last 10 minutes.
    private func duplicate(station: String, category: IncidentCategory) -> Incident? {
        let key = StationDirectory.key(station)
        let cutoff = Date().addingTimeInterval(-10 * 60)
        return repository.fetchAll().first {
            $0.status != .resolved && $0.category == category
                && StationDirectory.key($0.station) == key && $0.createdAt > cutoff
        }
    }

    func save() {
        guard canSave else { return }

        if source == .passenger {
            // Passengers don't pick severity or team: triage does it for them.
            if !categoryTouched, let guess = suggestion?.category { category = guess }
            severity = suggestion?.severity ?? .medium
            team = ResponseTeam.suggested(for: category)
            autoTriaged = true
        }

        let name = station.trimmingCharacters(in: .whitespacesAndNewlines)

        // Same problem already reported by someone else? Merge instead of creating a duplicate ticket.
        if source == .passenger, let existing = duplicate(station: name, category: category) {
            existing.reportCount += 1
            let boosted: Severity = existing.reportCount >= 3 ? .high : .medium
            let best = [existing.severity, severity, boosted].max { $0.rank < $1.rank } ?? severity
            existing.severity = best
            if existing.photoData == nil { existing.photoData = photoData }
            if existing.note.isEmpty { existing.note = note.trimmingCharacters(in: .whitespacesAndNewlines) }
            existing.isSynced = false
            repository.update()
            submitted = Submission(
                station: name, category: category, severity: best,
                team: existing.assignedTo.flatMap(ResponseTeam.init(rawValue:)),
                queuedOffline: !online, mergedCount: existing.reportCount
            )
            onSaved()
            return
        }

        let incident = Incident(
            station: name,
            category: category,
            severity: severity,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            photoData: photoData,
            latitude: location.latitude,
            longitude: location.longitude,
            status: team == nil ? .open : .assigned,
            assignedTo: team?.rawValue,
            autoTriaged: autoTriaged,
            source: source
        )
        repository.add(incident)
        submitted = Submission(
            station: name,
            category: category,
            severity: severity,
            team: team,
            queuedOffline: !online
        )
        onSaved()
    }
}
