import Foundation
import Testing
import UIKit
@testable import MoveInProof

@Suite("Inspection use cases")
struct InspectionUseCaseTests {
    let fixtures: ModelFixtures
    let repository: MockInspectionRepository
    let files = MockPhotoFileStorage()
    let room: Room

    init() throws {
        fixtures = try ModelFixtures()
        repository = MockInspectionRepository(fixtures: fixtures)
        room = try #require(fixtures.tenancy(rooms: ["Kitchen"]).rooms.first)
    }

    private var capture: CapturePhotoUseCase {
        CapturePhotoUseCase(repository: repository, files: files)
    }

    @Test("A damage tag turns the photo into an issue")
    func taggedPhotoCreatesIssue() throws {
        let photo = try capture.execute(image: .testImage, capturedAt: .now, location: "North wall", damageTag: "Scuff", in: room)

        let issue = try #require(repository.addedIssues.first)
        #expect(issue.title == "Scuff on north wall")
        #expect(issue.suggestion == "scuff")
        #expect(photo.issue === issue)
        #expect(repository.saveCount == 1)
    }

    @Test("An untagged photo doesn't create an issue")
    func plainPhotoHasNoIssue() throws {
        try capture.execute(image: .testImage, capturedAt: .now, location: "Floor", damageTag: nil, in: room)
        #expect(repository.addedPhotos.count == 1)
        #expect(repository.addedIssues.isEmpty)
    }

    @Test("If the image can't be written, nothing is recorded")
    func fileFailureIsReported() {
        files.shouldFail = true
        #expect(throws: MoveInError.photoNotSaved) {
            try capture.execute(image: .testImage, capturedAt: .now, location: "Floor", damageTag: nil, in: room)
        }
        #expect(repository.addedPhotos.isEmpty)
    }

    @Test("If the record can't be saved, the image file is cleaned up")
    func storageFailureRemovesOrphanedFile() {
        repository.shouldFail = true
        #expect(throws: MoveInError.storageFailed) {
            try capture.execute(image: .testImage, capturedAt: .now, location: "Floor", damageTag: nil, in: room)
        }
        #expect(files.savedFileNames == ["file-0.jpg"])
        #expect(files.deletedFileNames == ["file-0.jpg"])
    }

    @Test("A room can't be marked done without photos")
    func emptyRoomCannotBeCompleted() {
        #expect(throws: MoveInError.roomHasNoPhotos) {
            try CompleteRoomUseCase(repository: repository).execute(room, isComplete: true)
        }
        #expect(!room.isComplete)
    }

    @Test("An issue needs a title, and a rejected edit changes nothing")
    func issueTitleIsRequired() throws {
        let issue = try FlagIssueUseCase(repository: repository).execute(photo: fixtures.photo(in: room), in: room)
        let originalTitle = issue.title
        let draft = IssueDraft(title: "  ", kind: "crack", isKindConfirmed: true, severity: .major, notes: "")

        #expect(throws: MoveInError.missingIssueTitle) {
            try UpdateIssueUseCase(repository: repository).execute(issue, with: draft)
        }
        #expect(issue.title == originalTitle)
        #expect(issue.severity == .minor)
    }

    @Test("Exporting with nothing photographed is rejected")
    func exportNeedsContent() throws {
        let tenancy = fixtures.tenancy(rooms: ["Kitchen", "Bathroom"])
        #expect(throws: MoveInError.nothingToExport) {
            try ExportReportUseCase(renderer: MockReportRenderer()).execute(tenancy, options: ReportOptions())
        }
    }

    @Test("\"Flagged issues only\" exports just the rooms with issues")
    func exportFiltersFlaggedRooms() throws {
        let tenancy = fixtures.tenancy(rooms: ["Kitchen", "Bathroom"])
        let kitchen = try #require(tenancy.sortedRooms.first)
        let bathroom = try #require(tenancy.sortedRooms.last)
        fixtures.photo(in: bathroom)
        try FlagIssueUseCase(repository: repository).execute(photo: fixtures.photo(in: kitchen), in: kitchen)
        let renderer = MockReportRenderer()

        _ = try ExportReportUseCase(renderer: renderer).execute(tenancy, options: ReportOptions(includePhotos: true, flaggedOnly: true))

        #expect(renderer.renderedRooms.map(\.name) == ["Kitchen"])
    }

    @Test("Renderer failures are mapped to a domain error")
    func exportMapsRendererFailure() throws {
        let tenancy = fixtures.tenancy(rooms: ["Kitchen"])
        fixtures.photo(in: try #require(tenancy.rooms.first))
        let renderer = MockReportRenderer()
        renderer.shouldFail = true

        #expect(throws: MoveInError.reportNotCreated) {
            try ExportReportUseCase(renderer: renderer).execute(tenancy, options: ReportOptions())
        }
    }
}
