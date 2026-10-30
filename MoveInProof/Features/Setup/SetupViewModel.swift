import Foundation
import Observation

@Observable
final class SetupViewModel {
    struct RoomChoice: Identifiable {
        let id = UUID()
        var name: String
        var isIncluded = true
    }

    var streetAddress = ""
    var suburb = ""
    var leaseStart = Calendar.current.startOfDay(for: .now) {
        didSet { suggestDates(from: leaseStart) }
    }
    var leaseEnd = Date.now
    var reportDue = Date.now
    var rooms = SampleData.defaultRoomNames.map { RoomChoice(name: $0) }
    var newRoomName = ""
    var errorMessage: String?

    @ObservationIgnored private let createTenancy: CreateTenancyUseCase

    init(createTenancy: CreateTenancyUseCase) {
        self.createTenancy = createTenancy
        suggestDates(from: leaseStart)
    }

    var canStart: Bool {
        !streetAddress.trimmingCharacters(in: .whitespaces).isEmpty && rooms.contains(where: \.isIncluded)
    }

    var canAddRoom: Bool {
        !newRoomName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func addRoom() {
        let name = newRoomName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        rooms.append(RoomChoice(name: name))
        newRoomName = ""
    }

    /// Creates the tenancy. The root ViewModel then switches to the main tabs.
    func start() {
        let draft = TenancyDraft(
            streetAddress: streetAddress,
            suburb: suburb,
            leaseStart: leaseStart,
            leaseEnd: leaseEnd,
            reportDue: reportDue,
            roomNames: rooms.filter(\.isIncluded).map(\.name)
        )
        do {
            try createTenancy.execute(draft)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Typical lease: a year long, with the condition report due a week after moving in.
    private func suggestDates(from start: Date) {
        let calendar = Calendar.current
        leaseEnd = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: start) ?? start
        reportDue = calendar.date(byAdding: .day, value: 7, to: start) ?? start
    }
}
