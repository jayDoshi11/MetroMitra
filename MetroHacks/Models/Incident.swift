import Foundation
import SwiftData

@Model
final class Incident {
    var id: UUID
    var station: String
    var category: IncidentCategory
    var severity: Severity
    var note: String
    var createdAt: Date
    var isSynced: Bool
    @Attribute(.externalStorage) var photoData: Data?
    var latitude: Double?
    var longitude: Double?

    // Workflow (defaults keep existing stores migratable)
    var status: IncidentStatus = IncidentStatus.open
    var assignedTo: String?
    var resolvedAt: Date?
    var autoTriaged: Bool = false
    var source: IncidentSource = IncidentSource.staff
    var reportCount: Int = 1

    init(
        station: String,
        category: IncidentCategory,
        severity: Severity,
        note: String = "",
        createdAt: Date = .now,
        isSynced: Bool = false,
        photoData: Data? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        status: IncidentStatus = .open,
        assignedTo: String? = nil,
        resolvedAt: Date? = nil,
        autoTriaged: Bool = false,
        source: IncidentSource = .staff,
        reportCount: Int = 1
    ) {
        self.id = UUID()
        self.station = station
        self.category = category
        self.severity = severity
        self.note = note
        self.createdAt = createdAt
        self.isSynced = isSynced
        self.photoData = photoData
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.assignedTo = assignedTo
        self.resolvedAt = resolvedAt
        self.autoTriaged = autoTriaged
        self.source = source
        self.reportCount = reportCount
    }
}
