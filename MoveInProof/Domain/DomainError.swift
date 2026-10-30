import Foundation

/// Every way a business operation can fail, in words a tenant understands.
/// Use cases throw only these; storage and file errors are mapped before they reach the UI.
enum MoveInError: LocalizedError, Equatable {
    case missingAddress
    case leaseEndsBeforeStart
    case reportDueBeforeLeaseStart
    case noRoomsSelected
    case missingRoomName
    case duplicateRoomName(String)
    case roomHasNoPhotos
    case missingIssueTitle
    case photoNotSaved
    case nothingToExport
    case reportNotCreated
    case storageFailed

    var errorDescription: String? {
        switch self {
        case .missingAddress: "Enter the street address of the property."
        case .leaseEndsBeforeStart: "The lease end date must be after the start date."
        case .reportDueBeforeLeaseStart: "The condition report can't be due before the lease starts."
        case .noRoomsSelected: "Choose at least one room to photograph."
        case .missingRoomName: "Enter a name for the room."
        case .duplicateRoomName(let name): "There's already a room called \u{201C}\(name)\u{201D}."
        case .roomHasNoPhotos: "Take at least one photo before marking this room as done."
        case .missingIssueTitle: "Say where the damage is, for example \u{201C}Oven door\u{201D}."
        case .photoNotSaved: "The photo couldn't be saved. Check your iPhone has free storage and try again."
        case .nothingToExport: "There's nothing to export yet. Photograph a room first."
        case .reportNotCreated: "The report couldn't be created. Try again."
        case .storageFailed: "Your changes couldn't be saved. Try again."
        }
    }
}

/// Runs a storage call and maps any failure to `MoveInError.storageFailed`,
/// so raw SwiftData errors never leak past the domain layer.
func withStorage<T>(_ operation: () throws -> T) throws(MoveInError) -> T {
    do {
        return try operation()
    } catch let error as MoveInError {
        throw error
    } catch {
        throw .storageFailed
    }
}
