import Foundation
import SwiftData

/// Fixed lists the UI uses, plus sample content for previews and testing.
enum SampleData {
    static let defaultRoomNames = ["Entry and hallway", "Living room", "Kitchen", "Bedroom 1", "Bathroom", "Bedroom 2", "Laundry", "Balcony"]
    static let captureLocations = ["North wall", "East wall", "South wall", "West wall", "Floor", "Ceiling"]
    static let captureTags = ["Scuff", "Crack", "Stain", "More"]
    static let damageTypes = ["chip or scratch", "scuff", "crack", "stain", "dent", "wear and tear", "damage"]

    /// Fills the store with the tenancy from the mockups.
    /// `withPhotoFiles` renders a placeholder image for each photo; previews skip it to stay fast.
    @discardableResult
    static func seed(into context: ModelContext, withPhotoFiles: Bool = true) -> Tenancy {
        let calendar = Calendar.current
        func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? .now
        }

        let tenancy = Tenancy(
            streetAddress: "Unit 7, 42 Carlisle Street",
            suburb: "Newtown NSW 2042",
            leaseStart: date(2026, 10, 19),
            leaseEnd: date(2027, 10, 18),
            reportDue: date(2026, 10, 26)
        )
        context.insert(tenancy)

        let photoCounts = [6, 11, 14, 10, 6, 0, 0, 0]
        for (index, name) in defaultRoomNames.enumerated() {
            let room = Room(name: name, order: index)
            context.insert(room)
            room.isComplete = photoCounts[index] > 0
            room.tenancy = tenancy

            for n in 0..<photoCounts[index] {
                let capturedAt = date(2026, 10, 22, 15, 0).addingTimeInterval(Double(index * 600 + n * 40))
                let fileName = withPhotoFiles
                    ? (PhotoStore.renderPlaceholderPhoto(at: capturedAt, size: CGSize(width: 450, height: 600)).flatMap { try? PhotoStore.save($0) } ?? "")
                    : ""
                let photo = Photo(fileName: fileName, capturedAt: capturedAt, location: captureLocations[n % captureLocations.count])
                context.insert(photo)
                photo.room = room
            }
        }

        let rooms = tenancy.sortedRooms
        addIssue(to: rooms[2], in: context, title: "Benchtop edge, left of sink", suggestion: "chip or scratch", severity: .minor,
                 notes: "Chip about 3 cm long on the front edge, left of the sink. Already there when I moved in.", photos: 3)
        addIssue(to: rooms[2], in: context, title: "Oven door", suggestion: "scuff", severity: .minor,
                 notes: "Light scuff across the bottom of the oven door glass.", photos: 2)
        addIssue(to: rooms[4], in: context, title: "Tile beside vanity", suggestion: "crack", severity: .moderate,
                 notes: "Hairline crack in the floor tile to the right of the vanity.", photos: 2)

        return tenancy
    }

    private static func addIssue(to room: Room, in context: ModelContext, title: String, suggestion: String, severity: Severity, notes: String, photos: Int) {
        let issue = Issue(title: title, suggestion: suggestion, createdAt: room.sortedPhotos.first?.capturedAt ?? .now)
        context.insert(issue)
        issue.severity = severity
        issue.notes = notes
        issue.room = room
        let issuePhotos = room.sortedPhotos.filter { $0.issue == nil }.prefix(photos)
        for photo in issuePhotos {
            photo.issue = issue
        }
        // Date the issue by its own first photo so issues keep the order they were found in.
        issue.createdAt = issuePhotos.first?.capturedAt ?? issue.createdAt
    }
}
