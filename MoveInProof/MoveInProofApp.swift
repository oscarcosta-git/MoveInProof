import SwiftData
import SwiftUI

@main
struct MoveInProofApp: App {
    private let container: ModelContainer
    private let widgetSync: NSObjectProtocol

    init() {
        container = AppStore.makeContainer()
        widgetSync = WidgetSync.start(with: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
