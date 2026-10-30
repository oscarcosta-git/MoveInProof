import SwiftData
import WidgetKit

/// Keeps the widgets' copy of the tenancy dates in step with the store.
enum WidgetSync {
    /// Writes the current snapshot now, then again after every save.
    static func start(with container: ModelContainer) -> NSObjectProtocol {
        update(from: container.mainContext)
        return NotificationCenter.default.addObserver(forName: ModelContext.didSave, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { update(from: container.mainContext) }
        }
    }

    static func update(from context: ModelContext) {
        let tenancy = try? context.fetch(FetchDescriptor<Tenancy>()).first
        let snapshot = tenancy.map {
            TenancySnapshot(
                streetAddress: $0.streetAddress,
                reportDue: $0.reportDue,
                leaseEnd: $0.leaseEnd,
                moveOutInspection: $0.moveOutInspection,
                issuesFlagged: $0.issueCount
            )
        }
        if TenancySnapshot.store(snapshot) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
