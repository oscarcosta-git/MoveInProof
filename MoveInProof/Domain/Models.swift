import Foundation
import SwiftData

// MARK: - Stored models

@Model
final class Tenancy {
    var streetAddress: String
    var suburb: String
    var leaseStart: Date
    var leaseEnd: Date
    var reportDue: Date
    var moveOutInspection: Date?

    @Relationship(deleteRule: .cascade, inverse: \Room.tenancy)
    var rooms: [Room] = []

    init(streetAddress: String, suburb: String, leaseStart: Date, leaseEnd: Date, reportDue: Date) {
        self.streetAddress = streetAddress
        self.suburb = suburb
        self.leaseStart = leaseStart
        self.leaseEnd = leaseEnd
        self.reportDue = reportDue
    }

    var sortedRooms: [Room] { rooms.sorted { $0.order < $1.order } }
    var nextRoom: Room? { sortedRooms.first { !$0.isComplete } }
    var completedRoomCount: Int { rooms.filter(\.isComplete).count }
    var photoCount: Int { rooms.reduce(0) { $0 + $1.photos.count } }
    var issueCount: Int { rooms.reduce(0) { $0 + $1.issues.count } }

    func status(of room: Room) -> RoomStatus {
        if room.isComplete { return .done }
        if room == nextRoom { return .upNext }
        return room.photos.isEmpty ? .notStarted : .inProgress
    }
}

@Model
final class Room {
    var name: String
    var order: Int
    var isComplete: Bool = false
    var tenancy: Tenancy?

    @Relationship(deleteRule: .cascade, inverse: \Photo.room)
    var photos: [Photo] = []

    @Relationship(deleteRule: .cascade, inverse: \Issue.room)
    var issues: [Issue] = []

    init(name: String, order: Int) {
        self.name = name
        self.order = order
    }

    var sortedPhotos: [Photo] { photos.sorted { $0.capturedAt < $1.capturedAt } }
    var sortedIssues: [Issue] { issues.sorted { $0.createdAt < $1.createdAt } }
}

/// A photo's image lives on disk (see `PhotoStore`); the record holds its file name and metadata.
@Model
final class Photo {
    var fileName: String
    var capturedAt: Date
    var location: String
    var room: Room?
    var issue: Issue?

    init(fileName: String, capturedAt: Date = .now, location: String) {
        self.fileName = fileName
        self.capturedAt = capturedAt
        self.location = location
    }
}

@Model
final class Issue {
    var title: String
    /// The damage type the tenant tagged, e.g. "scuff". (Stored as `suggestion` for schema compatibility.)
    var suggestion: String
    /// Unused; kept so existing stores open without a migration.
    var isSuggestionConfirmed: Bool = false
    var severityRaw: String = Severity.minor.rawValue
    var notes: String = ""
    var createdAt: Date
    var room: Room?

    // Deleting an issue keeps its photos in the room.
    @Relationship(deleteRule: .nullify, inverse: \Photo.issue)
    var photos: [Photo] = []

    init(title: String, suggestion: String, createdAt: Date = .now) {
        self.title = title
        self.suggestion = suggestion
        self.createdAt = createdAt
    }

    var severity: Severity {
        get { Severity(rawValue: severityRaw) ?? .minor }
        set { severityRaw = newValue.rawValue }
    }

    var sortedPhotos: [Photo] { photos.sorted { $0.capturedAt < $1.capturedAt } }

    var typeName: String { Self.displayName(forType: suggestion) }

    /// "chip or scratch" → "Chip or scratch".
    static func displayName(forType type: String) -> String {
        type.prefix(1).uppercased() + type.dropFirst()
    }
}

// MARK: - Value types

enum RoomStatus: Hashable {
    case done, upNext, inProgress, notStarted
}

enum Severity: String, CaseIterable, Identifiable {
    case minor = "Minor"
    case moderate = "Moderate"
    case major = "Major"

    var id: Self { self }
}

enum CompareStatus: String {
    case existing = "Existing"
    case new = "New"
    case noChange = "No change"
}
