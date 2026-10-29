import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case home, report, compare, export
}

/// Shows setup until a tenancy exists, then the main tabs.
struct RootView: View {
    @Query private var tenancies: [Tenancy]

    var body: some View {
        if let tenancy = tenancies.first {
            RootTabView(tenancy: tenancy)
        } else {
            SetupView()
        }
    }
}

struct RootTabView: View {
    var tenancy: Tenancy

    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack { HomeView(tenancy: tenancy, selectedTab: $selection) }
            }
            Tab("Report", systemImage: "doc", value: .report) {
                NavigationStack { ReportView(tenancy: tenancy) }
            }
            Tab("Compare", systemImage: "rectangle.split.2x1", value: .compare) {
                NavigationStack { CompareView(tenancy: tenancy) }
            }
            Tab("Export", systemImage: "square.and.arrow.up", value: .export) {
                NavigationStack { ExportView(tenancy: tenancy) }
            }
        }
        .tint(Theme.brand)
    }
}

#Preview {
    RootTabView(tenancy: AppStore.previewTenancy)
        .modelContainer(AppStore.preview)
}
