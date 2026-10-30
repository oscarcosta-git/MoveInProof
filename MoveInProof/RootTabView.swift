import SwiftUI

enum AppTab: Hashable {
    case home, report, compare, export
}

/// Shows setup until a tenancy exists, then the main tabs.
struct RootView: View {
    @State private var viewModel: RootViewModel
    @Environment(AppDependencies.self) private var dependencies

    init(viewModel: RootViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let tenancy = viewModel.tenancy {
                RootTabView(tenancy: tenancy)
                    .id(tenancy.id)
            } else {
                SetupView(viewModel: dependencies.setupViewModel())
            }
        }
        .task { viewModel.start() }
    }
}

struct RootTabView: View {
    var tenancy: Tenancy

    @Environment(AppDependencies.self) private var dependencies
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack { HomeView(viewModel: dependencies.homeViewModel(for: tenancy), selectedTab: $selection) }
            }
            Tab("Report", systemImage: "doc", value: .report) {
                NavigationStack { ReportView(tenancy: tenancy) }
            }
            Tab("Compare", systemImage: "rectangle.split.2x1", value: .compare) {
                NavigationStack { CompareView(tenancy: tenancy) }
            }
            Tab("Export", systemImage: "square.and.arrow.up", value: .export) {
                NavigationStack { ExportView(viewModel: dependencies.exportViewModel(for: tenancy)) }
            }
        }
        .tint(Theme.brand)
    }
}

#Preview {
    RootTabView(tenancy: AppStore.previewTenancy)
        .environment(AppDependencies.preview)
}
