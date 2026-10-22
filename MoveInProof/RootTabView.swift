import SwiftUI

enum AppTab: Hashable {
    case home, report, compare, export
}

struct RootTabView: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack { HomeView() }
            }
            Tab("Report", systemImage: "doc", value: .report) {
                NavigationStack { ReportView() }
            }
            Tab("Compare", systemImage: "rectangle.split.2x1", value: .compare) {
                NavigationStack { CompareView() }
            }
            Tab("Export", systemImage: "square.and.arrow.up", value: .export) {
                NavigationStack { ExportView() }
            }
        }
        .tint(Theme.brand)
    }
}

#Preview {
    RootTabView()
}
