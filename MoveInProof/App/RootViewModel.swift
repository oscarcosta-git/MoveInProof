import Foundation
import Observation

/// Decides between first-run setup and the main tabs, and refreshes whenever the store changes.
@Observable
final class RootViewModel {
    private(set) var tenancy: Tenancy?
    private(set) var errorMessage: String?

    @ObservationIgnored private let load: LoadTenancyUseCase
    @ObservationIgnored private var observer: NSObjectProtocol?

    init(load: LoadTenancyUseCase) {
        self.load = load
    }

    func start() {
        reload()
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(forName: .moveInStoreDidChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        }
    }

    func reload() {
        do {
            tenancy = try load.execute()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
