import Foundation

/// The lease rules both creating and editing a tenancy enforce.
enum TenancyRules {
    static func validated(_ draft: TenancyDraft) throws(MoveInError) -> TenancyDraft {
        var draft = draft
        draft.streetAddress = draft.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.suburb = draft.suburb.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.roomNames = draft.roomNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !draft.streetAddress.isEmpty else { throw .missingAddress }
        guard draft.leaseEnd > draft.leaseStart else { throw .leaseEndsBeforeStart }
        let calendar = Calendar.current
        guard calendar.startOfDay(for: draft.reportDue) >= calendar.startOfDay(for: draft.leaseStart) else {
            throw .reportDueBeforeLeaseStart
        }
        return draft
    }
}

/// Finds the tenancy being tracked, if one has been set up.
struct LoadTenancyUseCase {
    let repository: TenancyRepository

    func execute() throws(MoveInError) -> Tenancy? {
        try withStorage { try repository.currentTenancy() }
    }
}

/// First-run setup: validates the lease and creates the tenancy with its rooms in order.
struct CreateTenancyUseCase {
    let repository: TenancyRepository

    @discardableResult
    func execute(_ draft: TenancyDraft) throws(MoveInError) -> Tenancy {
        let draft = try TenancyRules.validated(draft)
        guard !draft.roomNames.isEmpty else { throw .noRoomsSelected }
        let lowercased = draft.roomNames.map { $0.lowercased() }
        if let duplicate = draft.roomNames.enumerated().first(where: { lowercased.firstIndex(of: $1.lowercased()) != $0 }) {
            throw .duplicateRoomName(duplicate.element)
        }
        return try withStorage { try repository.createTenancy(draft) }
    }
}

/// Edits the property, lease dates and move-out inspection.
struct UpdateTenancyUseCase {
    let repository: TenancyRepository

    func execute(_ tenancy: Tenancy, with draft: TenancyDraft) throws(MoveInError) {
        let draft = try TenancyRules.validated(draft)
        tenancy.streetAddress = draft.streetAddress
        tenancy.suburb = draft.suburb
        tenancy.leaseStart = draft.leaseStart
        tenancy.leaseEnd = draft.leaseEnd
        tenancy.reportDue = draft.reportDue
        try withStorage { try repository.saveChanges() }
    }

    func scheduleMoveOutInspection(_ date: Date?, for tenancy: Tenancy) throws(MoveInError) {
        tenancy.moveOutInspection = date
        try withStorage { try repository.saveChanges() }
    }
}

/// Adds, removes and reorders the rooms to photograph.
struct ManageRoomsUseCase {
    let repository: TenancyRepository
    let files: PhotoFileStorage

    @discardableResult
    func addRoom(named name: String, to tenancy: Tenancy) throws(MoveInError) -> Room {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw .missingRoomName }
        if tenancy.rooms.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            throw .duplicateRoomName(name)
        }
        let order = (tenancy.rooms.map(\.order).max() ?? -1) + 1
        return try withStorage {
            let room = try repository.addRoom(named: name, order: order, to: tenancy)
            try repository.saveChanges()
            return room
        }
    }

    /// Deletes the room along with its photos' image files.
    func deleteRoom(_ room: Room) throws(MoveInError) {
        let fileNames = room.photos.map(\.fileName)
        try withStorage {
            try repository.deleteRoom(room)
            try repository.saveChanges()
        }
        fileNames.forEach(files.deleteFile(named:))
    }

    func moveRooms(in tenancy: Tenancy, from source: IndexSet, to destination: Int) throws(MoveInError) {
        var rooms = tenancy.sortedRooms
        rooms.move(fromOffsets: source, toOffset: destination)
        for (index, room) in rooms.enumerated() {
            room.order = index
        }
        try withStorage { try repository.saveChanges() }
    }
}

/// Wipes the tenancy, every record and every photo file.
struct DeleteAllDataUseCase {
    let repository: TenancyRepository
    let files: PhotoFileStorage

    func execute(_ tenancy: Tenancy) throws(MoveInError) {
        try withStorage {
            try repository.deleteTenancy(tenancy)
            try repository.saveChanges()
        }
        files.deleteAllFiles()
    }
}
