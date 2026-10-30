import Foundation
import Observation
import UIKit

@Observable
final class CaptureViewModel {
    let room: Room
    var location = SampleData.captureLocations[0]
    /// A damage tag for the next shot. It clears after each photo.
    var selectedTag: String?
    private(set) var isSaving = false
    var errorMessage: String?

    @ObservationIgnored private let capturePhoto: CapturePhotoUseCase
    @ObservationIgnored private let completeRoom: CompleteRoomUseCase

    init(room: Room, capturePhoto: CapturePhotoUseCase, completeRoom: CompleteRoomUseCase) {
        self.room = room
        self.capturePhoto = capturePhoto
        self.completeRoom = completeRoom
    }

    var title: String { "\(room.name) · \(location)" }
    var photoCount: Int { room.photos.count }
    var latestPhotoFileName: String? { room.sortedPhotos.last?.fileName }

    /// Takes a photo with the camera, or renders the placeholder scene where there's no camera,
    /// then stamps the time on it and saves it to the room.
    func takePhoto(with camera: CameraController) async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let capturedAt = Date.now
        let image: UIImage
        do {
            if camera.status == .ready {
                image = PhotoStore.stamped(try await camera.capturePhoto(), at: capturedAt)
            } else if let placeholder = PhotoStore.renderPlaceholderPhoto(at: capturedAt) {
                image = placeholder
            } else {
                throw MoveInError.photoNotSaved
            }
        } catch {
            errorMessage = MoveInError.photoNotSaved.localizedDescription
            return
        }

        do {
            try capturePhoto.execute(image: image, capturedAt: capturedAt, location: location, damageTag: selectedTag, in: room)
            selectedTag = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleTag(_ tag: String) {
        selectedTag = selectedTag == tag ? nil : tag
    }

    /// Marks the room done if it has photos.
    func finish() {
        guard !room.photos.isEmpty else { return }
        try? completeRoom.execute(room, isComplete: true)
    }
}
