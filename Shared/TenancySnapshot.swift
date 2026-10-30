import Foundation

/// The few tenancy details the widgets show. The app writes it to the shared App Group
/// whenever it saves, and the widget extension reads it. Compiled into both targets.
nonisolated struct TenancySnapshot: Codable, Equatable, Sendable {
    var streetAddress: String
    var reportDue: Date
    var leaseEnd: Date
    var moveOutInspection: Date?
    var issuesFlagged: Int

    static let appGroupID = "group.com.oscarcosta.MoveInProof"
    private static let key = "tenancySnapshot"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// The last snapshot the app saved, or nil if there's no tenancy set up yet.
    static func load() -> TenancySnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(TenancySnapshot.self, from: data)
    }

    /// Stores the snapshot, or clears it when nil. Returns whether anything changed.
    @discardableResult
    static func store(_ snapshot: TenancySnapshot?) -> Bool {
        guard snapshot != load() else { return false }
        if let snapshot, let data = try? JSONEncoder().encode(snapshot) {
            defaults?.set(data, forKey: key)
        } else {
            defaults?.removeObject(forKey: key)
        }
        return true
    }
}
