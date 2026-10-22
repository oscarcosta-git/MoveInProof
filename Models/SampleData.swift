import Foundation

/// Placeholder content matching the mockups, used until real storage exists.
enum SampleData {
    static let tenancy = Tenancy(
        streetAddress: "Unit 7, 42 Carlisle Street",
        suburb: "Newtown NSW 2042",
        term: "Fixed term · 19 Oct 2026 – 18 Oct 2027",
        reportDue: "Mon 26 Oct 2026",
        reportDaysLeft: 4,
        leaseEnds: "Mon 18 Oct 2027",
        leaseDaysLeft: 361,
        moveOutInspection: nil
    )

    static let benchtopChip = Issue(
        title: "Benchtop edge, left of sink",
        roomName: "Kitchen",
        photoCount: 3,
        suggestion: "chip or scratch",
        severity: .minor,
        notes: "Chip about 3 cm long on the front edge, left of the sink. Already there when I moved in.",
        capturedAt: "Move-in · Thu 22 Oct 2026, 3:48 pm"
    )

    static let ovenScuff = Issue(
        title: "Oven door",
        roomName: "Kitchen",
        photoCount: 2,
        suggestion: "scuff",
        severity: .minor,
        notes: "Light scuff across the bottom of the oven door glass.",
        capturedAt: "Move-in · Thu 22 Oct 2026, 3:52 pm"
    )

    static let bathroomCrack = Issue(
        title: "Tile beside vanity",
        roomName: "Bathroom",
        photoCount: 2,
        suggestion: "crack",
        severity: .moderate,
        notes: "Hairline crack in the floor tile to the right of the vanity.",
        capturedAt: "Move-in · Thu 22 Oct 2026, 4:10 pm"
    )

    static let rooms: [Room] = [
        Room(name: "Entry and hallway", photoCount: 6, status: .done),
        Room(name: "Living room", photoCount: 11, status: .done),
        Room(name: "Kitchen", photoCount: 14, status: .done, issues: [benchtopChip, ovenScuff]),
        Room(name: "Bedroom 1", photoCount: 10, status: .done),
        Room(name: "Bathroom", photoCount: 6, status: .done, issues: [bathroomCrack]),
        Room(name: "Bedroom 2", photoCount: 0, status: .upNext),
        Room(name: "Laundry", photoCount: 0, status: .notStarted),
        Room(name: "Balcony", photoCount: 0, status: .notStarted),
    ]

    static var completedRooms: Int { rooms.filter { $0.status == .done }.count }
    static var totalPhotos: Int { rooms.reduce(0) { $0 + $1.photoCount } }
    static var totalIssues: Int { rooms.reduce(0) { $0 + $1.issues.count } }
    static var nextRoom: Room? { rooms.first { $0.status == .upNext } }

    static let captureLocations = ["North wall", "East wall", "South wall", "West wall", "Floor", "Ceiling"]
    static let captureTags = ["Scuff", "Crack", "Stain", "More"]

    static func comparison(for roomName: String) -> RoomComparison {
        switch roomName {
        case "Kitchen":
            RoomComparison(
                roomName: roomName,
                moveInDate: "19 Oct 2026",
                moveOutDate: "12 Oct 2027",
                unchangedCount: 11,
                items: [
                    CompareItem(title: "Benchtop edge", detail: "Chip, flagged at move-in", status: .existing),
                    CompareItem(title: "Oven door", detail: "Scuff, flagged at move-in", status: .existing),
                    CompareItem(title: "Cupboard door under sink", detail: "Scratch, not in move-in photos", status: .new),
                    CompareItem(title: "Splashback", detail: "Matches move-in photos", status: .noChange),
                ]
            )
        case "Bathroom":
            RoomComparison(
                roomName: roomName,
                moveInDate: "19 Oct 2026",
                moveOutDate: "12 Oct 2027",
                unchangedCount: 5,
                items: [
                    CompareItem(title: "Tile beside vanity", detail: "Crack, flagged at move-in", status: .existing),
                    CompareItem(title: "Shower screen", detail: "Matches move-in photos", status: .noChange),
                ]
            )
        default:
            RoomComparison(
                roomName: roomName,
                moveInDate: "19 Oct 2026",
                moveOutDate: "12 Oct 2027",
                unchangedCount: 8,
                items: [
                    CompareItem(title: "Walls", detail: "Matches move-in photos", status: .noChange),
                    CompareItem(title: "Flooring", detail: "Matches move-in photos", status: .noChange),
                ]
            )
        }
    }
}
