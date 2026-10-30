import SwiftData
import SwiftUI

@main
struct MoveInProofApp: App {
    private let container: ModelContainer
    private let dependencies: AppDependencies
    private let widgetSync: NSObjectProtocol

    init() {
        container = AppStore.makeContainer()
        dependencies = AppDependencies(container: container)
        widgetSync = WidgetSync.start(with: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: dependencies.rootViewModel())
                .environment(dependencies)
        }
    }
}
