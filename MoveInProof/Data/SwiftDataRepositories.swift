import SwiftData
import UIKit

/// SwiftData-backed tenancy and room storage.
final class SwiftDataTenancyRepository: TenancyRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func currentTenancy() throws -> Tenancy? {
        var descriptor = FetchDescriptor<Tenancy>(sortBy: [SortDescriptor(\.leaseStart, order: .reverse)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func createTenancy(_ draft: TenancyDraft) throws -> Tenancy {
        let tenancy = Tenancy(
            streetAddress: draft.streetAddress,
            suburb: draft.suburb,
            leaseStart: draft.leaseStart,
            leaseEnd: draft.leaseEnd,
            reportDue: draft.reportDue
        )
        context.insert(tenancy)
        for (index, name) in draft.roomNames.enumerated() {
            let room = Room(name: name, order: index)
            context.insert(room)
            room.tenancy = tenancy
        }
        try saveChanges()
        return tenancy
    }

    func addRoom(named name: String, order: Int, to tenancy: Tenancy) throws -> Room {
        let room = Room(name: name, order: order)
        context.insert(room)
        room.tenancy = tenancy
        return room
    }

    func deleteRoom(_ room: Room) throws {
        context.delete(room)
    }

    func deleteTenancy(_ tenancy: Tenancy) throws {
        context.delete(tenancy)
    }

    func saveChanges() throws {
        try context.save()
        NotificationCenter.default.post(name: .moveInStoreDidChange, object: nil)
    }
}

/// SwiftData-backed photo and issue storage.
final class SwiftDataInspectionRepository: InspectionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addPhoto(fileName: String, capturedAt: Date, location: String, to room: Room) throws -> Photo {
        let photo = Photo(fileName: fileName, capturedAt: capturedAt, location: location)
        context.insert(photo)
        photo.room = room
        return photo
    }

    func addIssue(title: String, kind: String, createdAt: Date, in room: Room, photos: [Photo]) throws -> Issue {
        let issue = Issue(title: title, suggestion: kind, createdAt: createdAt)
        context.insert(issue)
        issue.room = room
        for photo in photos {
            photo.issue = issue
        }
        return issue
    }

    func deletePhoto(_ photo: Photo) throws {
        context.delete(photo)
    }

    func deleteIssue(_ issue: Issue) throws {
        context.delete(issue)
    }

    func saveChanges() throws {
        try context.save()
        NotificationCenter.default.post(name: .moveInStoreDidChange, object: nil)
    }
}

/// Photo files in Application Support, via `PhotoStore`.
struct LocalPhotoFileStorage: PhotoFileStorage {
    func save(_ image: UIImage) throws -> String { try PhotoStore.save(image) }
    func deleteFile(named fileName: String) { PhotoStore.deleteFile(named: fileName) }
    func deleteAllFiles() { PhotoStore.deleteAllFiles() }
}

/// Renders the report as an A4 PDF in the temporary directory.
struct PDFReportRenderer: ReportRenderer {
    func render(_ tenancy: Tenancy, rooms: [Room], options: ReportOptions) throws -> URL {
        try ConditionReportPDF(tenancy: tenancy, rooms: rooms, includePhotos: options.includePhotos, flaggedOnly: options.flaggedOnly).write()
    }
}
