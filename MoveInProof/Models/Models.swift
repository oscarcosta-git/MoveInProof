import Foundation

struct Tenancy {
    var streetAddress: String
    var suburb: String
    var term: String
    var reportDue: String
    var reportDaysLeft: Int
    var leaseEnds: String
    var leaseDaysLeft: Int
    var moveOutInspection: Date?
}

enum RoomStatus: Hashable {
    case done, upNext, notStarted
}

struct Room: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var photoCount: Int
    var status: RoomStatus
    var issues: [Issue] = []
}

enum Severity: String, CaseIterable, Identifiable {
    case minor = "Minor"
    case moderate = "Moderate"
    case major = "Major"

    var id: Self { self }
}

struct Issue: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var roomName: String
    var photoCount: Int
    var suggestion: String
    var severity: Severity
    var notes: String
    var capturedAt: String
}

enum CompareStatus: String {
    case existing = "Existing"
    case new = "New"
    case noChange = "No change"
}

struct CompareItem: Identifiable {
    let id = UUID()
    var title: String
    var detail: String
    var status: CompareStatus
}

struct RoomComparison {
    var roomName: String
    var moveInDate: String
    var moveOutDate: String
    var unchangedCount: Int
    var items: [CompareItem]

    func count(_ status: CompareStatus) -> Int {
        items.filter { $0.status == status }.count
    }
}
