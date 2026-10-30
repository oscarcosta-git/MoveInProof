import Foundation
import Observation

@Observable
final class TenancySettingsViewModel {
    let tenancy: Tenancy
    var streetAddress: String
    var suburb: String
    var leaseStart: Date
    var leaseEnd: Date
    var reportDue: Date
    var newRoomName = ""
    var errorMessage: String?

    @ObservationIgnored private let updateTenancy: UpdateTenancyUseCase
    @ObservationIgnored private let manageRooms: ManageRoomsUseCase
    @ObservationIgnored private let deleteAllData: DeleteAllDataUseCase

    init(tenancy: Tenancy, updateTenancy: UpdateTenancyUseCase, manageRooms: ManageRoomsUseCase, deleteAll: DeleteAllDataUseCase) {
        self.tenancy = tenancy
        streetAddress = tenancy.streetAddress
        suburb = tenancy.suburb
        leaseStart = tenancy.leaseStart
        leaseEnd = tenancy.leaseEnd
        reportDue = tenancy.reportDue
        self.updateTenancy = updateTenancy
        self.manageRooms = manageRooms
        self.deleteAllData = deleteAll
    }

    var rooms: [Room] { tenancy.sortedRooms }

    var canAddRoom: Bool {
        !newRoomName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func addRoom() {
        perform { try manageRooms.addRoom(named: newRoomName, to: tenancy) }
        if errorMessage == nil { newRoomName = "" }
    }

    func deleteRooms(at offsets: IndexSet) {
        let rooms = rooms
        for index in offsets {
            perform { try manageRooms.deleteRoom(rooms[index]) }
        }
    }

    func moveRooms(from source: IndexSet, to destination: Int) {
        perform { try manageRooms.moveRooms(in: tenancy, from: source, to: destination) }
    }

    /// Saves the property and lease details. Returns false if they're invalid.
    func save() -> Bool {
        let draft = TenancyDraft(streetAddress: streetAddress, suburb: suburb, leaseStart: leaseStart, leaseEnd: leaseEnd, reportDue: reportDue)
        perform { try updateTenancy.execute(tenancy, with: draft) }
        return errorMessage == nil
    }

    func deleteAll() -> Bool {
        perform { try deleteAllData.execute(tenancy) }
        return errorMessage == nil
    }

    private func perform(_ operation: () throws -> Void) {
        do {
            try operation()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
