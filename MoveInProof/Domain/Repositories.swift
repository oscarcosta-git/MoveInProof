import Foundation
import UIKit

/// The details needed to start or update a tenancy, before they're validated.
struct TenancyDraft: Equatable {
    var streetAddress: String
    var suburb: String
    var leaseStart: Date
    var leaseEnd: Date
    var reportDue: Date
    var roomNames: [String] = []
}

extension Notification.Name {
    /// Posted by repositories after they save, so ViewModels can refresh.
    static let moveInStoreDidChange = Notification.Name("MoveInStoreDidChange")
}

/// Tenancy and room storage. Use cases depend on this protocol, never on SwiftData directly.
protocol TenancyRepository {
    func currentTenancy() throws -> Tenancy?
    func createTenancy(_ draft: TenancyDraft) throws -> Tenancy
    func addRoom(named name: String, order: Int, to tenancy: Tenancy) throws -> Room
    func deleteRoom(_ room: Room) throws
    func deleteTenancy(_ tenancy: Tenancy) throws
    func saveChanges() throws
}

/// Photo and issue records within a room.
protocol InspectionRepository {
    func addPhoto(fileName: String, capturedAt: Date, location: String, to room: Room) throws -> Photo
    func addIssue(title: String, kind: String, createdAt: Date, in room: Room, photos: [Photo]) throws -> Issue
    func deletePhoto(_ photo: Photo) throws
    func deleteIssue(_ issue: Issue) throws
    func saveChanges() throws
}

/// Where photo image files live.
protocol PhotoFileStorage {
    /// Writes the image and returns its file name.
    func save(_ image: UIImage) throws -> String
    func deleteFile(named fileName: String)
    func deleteAllFiles()
}

/// What goes into an exported condition report.
struct ReportOptions: Equatable {
    var includePhotos = true
    var flaggedOnly = false
}

/// Turns a tenancy into a shareable report file.
protocol ReportRenderer {
    func render(_ tenancy: Tenancy, rooms: [Room], options: ReportOptions) throws -> URL
}
