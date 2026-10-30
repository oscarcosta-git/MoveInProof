import Foundation
import Observation

@Observable
final class HomeViewModel {
    let tenancy: Tenancy
    var errorMessage: String?

    @ObservationIgnored private let updateTenancy: UpdateTenancyUseCase

    init(tenancy: Tenancy, updateTenancy: UpdateTenancyUseCase) {
        self.tenancy = tenancy
        self.updateTenancy = updateTenancy
    }

    var nextRoom: Room? { tenancy.nextRoom }
    var reportDueInDays: Int { tenancy.reportDue.daysFromToday }
    var leaseDaysLeft: Int { max(tenancy.leaseEnd.daysFromToday, 0) }

    func setMoveOutInspection(_ date: Date?) {
        do {
            try updateTenancy.scheduleMoveOutInspection(date, for: tenancy)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
