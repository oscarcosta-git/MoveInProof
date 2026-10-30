import Foundation
import UIKit

/// Saves a captured photo to a room. A damage tag turns the shot into a new issue.
struct CapturePhotoUseCase {
    let repository: InspectionRepository
    let files: PhotoFileStorage

    @discardableResult
    func execute(image: UIImage, capturedAt: Date, location: String, damageTag: String?, in room: Room) throws(MoveInError) -> Photo {
        let fileName: String
        do {
            fileName = try files.save(image)
        } catch {
            throw .photoNotSaved
        }

        do {
            let photo = try repository.addPhoto(fileName: fileName, capturedAt: capturedAt, location: location, to: room)
            if let damageTag {
                let kind = damageTag.lowercased()
                let title = "\(kind.prefix(1).uppercased() + kind.dropFirst()) on \(location.lowercased())"
                _ = try repository.addIssue(title: title, kind: kind, createdAt: capturedAt, in: room, photos: [photo])
            }
            try repository.saveChanges()
            return photo
        } catch {
            // Don't leave an orphaned image file behind if the record couldn't be saved.
            files.deleteFile(named: fileName)
            throw .storageFailed
        }
    }
}

/// Marks a room done once it has photos, or reopens it.
struct CompleteRoomUseCase {
    let repository: InspectionRepository

    func execute(_ room: Room, isComplete: Bool) throws(MoveInError) {
        if isComplete, room.photos.isEmpty { throw .roomHasNoPhotos }
        room.isComplete = isComplete
        try withStorage { try repository.saveChanges() }
    }
}

/// Flags an existing photo as showing damage.
struct FlagIssueUseCase {
    let repository: InspectionRepository

    @discardableResult
    func execute(photo: Photo, in room: Room) throws(MoveInError) -> Issue {
        try withStorage {
            let issue = try repository.addIssue(
                title: "Issue on \(photo.location.lowercased())",
                kind: "damage",
                createdAt: photo.capturedAt,
                in: room,
                photos: [photo]
            )
            try repository.saveChanges()
            return issue
        }
    }
}

/// The editable parts of an issue.
struct IssueDraft: Equatable {
    var title: String
    var kind: String
    var severity: Severity
    var notes: String
}

/// Saves edits to an issue, or deletes it (its photos stay in the room).
struct UpdateIssueUseCase {
    let repository: InspectionRepository

    func execute(_ issue: Issue, with draft: IssueDraft) throws(MoveInError) {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw .missingIssueTitle }
        issue.title = title
        issue.suggestion = draft.kind
        issue.severity = draft.severity
        issue.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        try withStorage { try repository.saveChanges() }
    }

    func delete(_ issue: Issue) throws(MoveInError) {
        try withStorage {
            try repository.deleteIssue(issue)
            try repository.saveChanges()
        }
    }
}

/// Removes a photo record and its image file.
struct DeletePhotoUseCase {
    let repository: InspectionRepository
    let files: PhotoFileStorage

    func execute(_ photo: Photo) throws(MoveInError) {
        let fileName = photo.fileName
        try withStorage {
            try repository.deletePhoto(photo)
            try repository.saveChanges()
        }
        files.deleteFile(named: fileName)
    }
}

/// Builds the condition report for sharing or saving.
struct ExportReportUseCase {
    let renderer: ReportRenderer

    /// The rooms a report with these options would include.
    func rooms(in tenancy: Tenancy, options: ReportOptions) -> [Room] {
        tenancy.sortedRooms.filter { options.flaggedOnly ? !$0.issues.isEmpty : !$0.photos.isEmpty }
    }

    func execute(_ tenancy: Tenancy, options: ReportOptions) throws(MoveInError) -> URL {
        let rooms = rooms(in: tenancy, options: options)
        guard !rooms.isEmpty else { throw .nothingToExport }
        do {
            return try renderer.render(tenancy, rooms: rooms, options: options)
        } catch {
            throw .reportNotCreated
        }
    }
}
