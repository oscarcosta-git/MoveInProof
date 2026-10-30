import Foundation
import SwiftData
import UIKit
@testable import MoveInProof

struct TestFailure: Error {}

/// An in-memory store used only to create model objects with working relationships.
/// The use cases under test never see it; they talk to the mock repositories below.
final class ModelFixtures {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: AppStore.schema,
            configurations: ModelConfiguration(schema: AppStore.schema, isStoredInMemoryOnly: true)
        )
    }

    func tenancy(rooms: [String] = ["Kitchen", "Bathroom"]) -> Tenancy {
        let tenancy = Tenancy(
            streetAddress: "12 Test Street",
            suburb: "Glebe NSW 2037",
            leaseStart: .now,
            leaseEnd: .now.addingTimeInterval(86_400 * 365),
            reportDue: .now.addingTimeInterval(86_400 * 7)
        )
        context.insert(tenancy)
        for (index, name) in rooms.enumerated() {
            let room = Room(name: name, order: index)
            context.insert(room)
            room.tenancy = tenancy
        }
        return tenancy
    }

    @discardableResult
    func photo(in room: Room, fileName: String = "photo.jpg") -> Photo {
        let photo = Photo(fileName: fileName, location: "North wall")
        context.insert(photo)
        photo.room = room
        return photo
    }
}

final class MockTenancyRepository: TenancyRepository {
    var tenancy: Tenancy?
    var createdDrafts: [TenancyDraft] = []
    var deletedRooms: [Room] = []
    var saveCount = 0
    var shouldFail = false
    private let fixtures: ModelFixtures

    init(fixtures: ModelFixtures) {
        self.fixtures = fixtures
    }

    func currentTenancy() throws -> Tenancy? {
        if shouldFail { throw TestFailure() }
        return tenancy
    }

    func createTenancy(_ draft: TenancyDraft) throws -> Tenancy {
        if shouldFail { throw TestFailure() }
        createdDrafts.append(draft)
        let tenancy = fixtures.tenancy(rooms: draft.roomNames)
        self.tenancy = tenancy
        return tenancy
    }

    func addRoom(named name: String, order: Int, to tenancy: Tenancy) throws -> Room {
        if shouldFail { throw TestFailure() }
        let room = Room(name: name, order: order)
        fixtures.context.insert(room)
        room.tenancy = tenancy
        return room
    }

    func deleteRoom(_ room: Room) throws {
        if shouldFail { throw TestFailure() }
        deletedRooms.append(room)
    }

    func deleteTenancy(_ tenancy: Tenancy) throws {
        if shouldFail { throw TestFailure() }
        self.tenancy = nil
    }

    func saveChanges() throws {
        if shouldFail { throw TestFailure() }
        saveCount += 1
    }
}

final class MockInspectionRepository: InspectionRepository {
    var addedPhotos: [Photo] = []
    var addedIssues: [Issue] = []
    var deletedIssues: [Issue] = []
    var saveCount = 0
    var shouldFail = false
    private let fixtures: ModelFixtures

    init(fixtures: ModelFixtures) {
        self.fixtures = fixtures
    }

    func addPhoto(fileName: String, capturedAt: Date, location: String, to room: Room) throws -> Photo {
        if shouldFail { throw TestFailure() }
        let photo = Photo(fileName: fileName, capturedAt: capturedAt, location: location)
        fixtures.context.insert(photo)
        photo.room = room
        addedPhotos.append(photo)
        return photo
    }

    func addIssue(title: String, kind: String, createdAt: Date, in room: Room, photos: [Photo]) throws -> Issue {
        if shouldFail { throw TestFailure() }
        let issue = Issue(title: title, suggestion: kind, createdAt: createdAt)
        fixtures.context.insert(issue)
        issue.room = room
        photos.forEach { $0.issue = issue }
        addedIssues.append(issue)
        return issue
    }

    func deletePhoto(_ photo: Photo) throws {
        if shouldFail { throw TestFailure() }
    }

    func deleteIssue(_ issue: Issue) throws {
        if shouldFail { throw TestFailure() }
        deletedIssues.append(issue)
    }

    func saveChanges() throws {
        if shouldFail { throw TestFailure() }
        saveCount += 1
    }
}

final class MockPhotoFileStorage: PhotoFileStorage {
    var savedFileNames: [String] = []
    var deletedFileNames: [String] = []
    var didDeleteAll = false
    var shouldFail = false

    func save(_ image: UIImage) throws -> String {
        if shouldFail { throw TestFailure() }
        let name = "file-\(savedFileNames.count).jpg"
        savedFileNames.append(name)
        return name
    }

    func deleteFile(named fileName: String) {
        deletedFileNames.append(fileName)
    }

    func deleteAllFiles() {
        didDeleteAll = true
    }
}

final class MockReportRenderer: ReportRenderer {
    var renderedRooms: [Room] = []
    var shouldFail = false

    func render(_ tenancy: Tenancy, rooms: [Room], options: ReportOptions) throws -> URL {
        if shouldFail { throw TestFailure() }
        renderedRooms = rooms
        return URL(fileURLWithPath: "/tmp/report.pdf")
    }
}

extension UIImage {
    static let testImage = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in }
}
