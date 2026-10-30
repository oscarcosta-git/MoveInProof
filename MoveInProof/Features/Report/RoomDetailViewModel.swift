import Foundation
import Observation

@Observable
final class RoomDetailViewModel {
    let room: Room
    var errorMessage: String?

    @ObservationIgnored private let flagIssue: FlagIssueUseCase
    @ObservationIgnored private let deletePhoto: DeletePhotoUseCase
    @ObservationIgnored private let completeRoom: CompleteRoomUseCase

    init(room: Room, flagIssue: FlagIssueUseCase, deletePhoto: DeletePhotoUseCase, completeRoom: CompleteRoomUseCase) {
        self.room = room
        self.flagIssue = flagIssue
        self.deletePhoto = deletePhoto
        self.completeRoom = completeRoom
    }

    var subtitle: String {
        if room.photos.isEmpty { return "Not started" }
        let summary = "\(room.photos.count.counted("photo")) · \(room.issues.count.counted("issue"))"
        return room.isComplete ? summary : "In progress · \(summary)"
    }

    var canToggleComplete: Bool { room.isComplete || !room.photos.isEmpty }

    func flag(_ photo: Photo) {
        perform { try flagIssue.execute(photo: photo, in: room) }
    }

    func delete(_ photo: Photo) {
        perform { try deletePhoto.execute(photo) }
    }

    func toggleComplete() {
        perform { try completeRoom.execute(room, isComplete: !room.isComplete) }
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
