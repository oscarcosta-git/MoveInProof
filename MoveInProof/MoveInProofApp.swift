import SwiftData
import SwiftUI

@main
struct MoveInProofApp: App {
    private let container = AppStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
