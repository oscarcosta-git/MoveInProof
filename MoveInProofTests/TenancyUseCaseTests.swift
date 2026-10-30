import Foundation
import Testing
@testable import MoveInProof

@Suite("Tenancy use cases")
struct TenancyUseCaseTests {
    let fixtures: ModelFixtures
    let repository: MockTenancyRepository
    let files = MockPhotoFileStorage()

    init() throws {
        fixtures = try ModelFixtures()
        repository = MockTenancyRepository(fixtures: fixtures)
    }

    private func draft(
        address: String = "12 Test Street",
        start: Date = Date(timeIntervalSince1970: 1_800_000_000),
        lengthInDays: Double = 365,
        reportDueAfterDays: Double = 7,
        rooms: [String] = ["Kitchen", "Bathroom"]
    ) -> TenancyDraft {
        TenancyDraft(
            streetAddress: address,
            suburb: " Glebe NSW 2037 ",
            leaseStart: start,
            leaseEnd: start.addingTimeInterval(86_400 * lengthInDays),
            reportDue: start.addingTimeInterval(86_400 * reportDueAfterDays),
            roomNames: rooms
        )
    }

    @Test("Setup needs a street address")
    func rejectsBlankAddress() {
        let useCase = CreateTenancyUseCase(repository: repository)
        #expect(throws: MoveInError.missingAddress) {
            try useCase.execute(draft(address: "   "))
        }
        #expect(repository.createdDrafts.isEmpty)
    }

    @Test("The lease must end after it starts")
    func rejectsLeaseEndingBeforeStart() {
        let useCase = CreateTenancyUseCase(repository: repository)
        #expect(throws: MoveInError.leaseEndsBeforeStart) {
            try useCase.execute(draft(lengthInDays: -1))
        }
    }

    @Test("The condition report can't be due before the lease starts")
    func rejectsReportDueBeforeLease() {
        let useCase = CreateTenancyUseCase(repository: repository)
        #expect(throws: MoveInError.reportDueBeforeLeaseStart) {
            try useCase.execute(draft(reportDueAfterDays: -3))
        }
    }

    @Test("Setup needs at least one room, and blank names don't count")
    func rejectsNoRooms() {
        let useCase = CreateTenancyUseCase(repository: repository)
        #expect(throws: MoveInError.noRoomsSelected) {
            try useCase.execute(draft(rooms: ["", "  "]))
        }
    }

    @Test("Room names must be unique, ignoring case")
    func rejectsDuplicateRoomsAtSetup() {
        let useCase = CreateTenancyUseCase(repository: repository)
        #expect(throws: MoveInError.duplicateRoomName("kitchen")) {
            try useCase.execute(draft(rooms: ["Kitchen", "kitchen"]))
        }
    }

    @Test("A valid draft is trimmed and stored with its rooms in order")
    func createsTrimmedTenancy() throws {
        let useCase = CreateTenancyUseCase(repository: repository)
        try useCase.execute(draft(address: "  5 Widget Lane ", rooms: ["Kitchen", " ", "Laundry"]))

        let stored = try #require(repository.createdDrafts.first)
        #expect(stored.streetAddress == "5 Widget Lane")
        #expect(stored.suburb == "Glebe NSW 2037")
        #expect(stored.roomNames == ["Kitchen", "Laundry"])
    }

    @Test("Storage failures are mapped to a domain error")
    func mapsRepositoryFailure() {
        repository.shouldFail = true
        let useCase = CreateTenancyUseCase(repository: repository)
        #expect(throws: MoveInError.storageFailed) {
            try useCase.execute(draft())
        }
    }

    @Test("Adding a room that already exists is rejected")
    func rejectsDuplicateRoom() {
        let tenancy = fixtures.tenancy(rooms: ["Kitchen"])
        let useCase = ManageRoomsUseCase(repository: repository, files: files)
        #expect(throws: MoveInError.duplicateRoomName("KITCHEN")) {
            try useCase.addRoom(named: " KITCHEN ", to: tenancy)
        }
        #expect(repository.saveCount == 0)
    }

    @Test("New rooms go to the end of the list")
    func addsRoomAtEnd() throws {
        let tenancy = fixtures.tenancy(rooms: ["Kitchen", "Bathroom"])
        let room = try ManageRoomsUseCase(repository: repository, files: files).addRoom(named: "Balcony", to: tenancy)
        #expect(room.order == 2)
        #expect(repository.saveCount == 1)
    }

    @Test("Deleting a room also deletes its photo files")
    func deletingRoomRemovesFiles() throws {
        let tenancy = fixtures.tenancy(rooms: ["Kitchen"])
        let room = try #require(tenancy.rooms.first)
        fixtures.photo(in: room, fileName: "a.jpg")
        fixtures.photo(in: room, fileName: "b.jpg")

        try ManageRoomsUseCase(repository: repository, files: files).deleteRoom(room)

        #expect(repository.deletedRooms.count == 1)
        #expect(Set(files.deletedFileNames) == ["a.jpg", "b.jpg"])
    }

    @Test("Deleting all data removes every photo file")
    func deleteAllRemovesFiles() throws {
        let tenancy = fixtures.tenancy()
        repository.tenancy = tenancy
        try DeleteAllDataUseCase(repository: repository, files: files).execute(tenancy)
        #expect(repository.tenancy == nil)
        #expect(files.didDeleteAll)
    }
}
