import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Binding var selectedTab: AppTab

    @Environment(AppDependencies.self) private var dependencies

    @State private var capturingRoom: Room?
    @State private var isPickingInspectionDate = false
    @State private var isShowingSettings = false

    init(viewModel: HomeViewModel, selectedTab: Binding<AppTab>) {
        _viewModel = State(initialValue: viewModel)
        _selectedTab = selectedTab
    }

    private var tenancy: Tenancy { viewModel.tenancy }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center) {
                    Text("My tenancy")
                        .font(.screenTitle)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    CircleIconButton(systemName: "slider.horizontal.3") {
                        isShowingSettings = true
                    }
                    .accessibilityLabel("Tenancy settings")
                }

                PropertyCard(tenancy: tenancy)

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Key dates")
                    keyDates
                }

                MoveInProgressCard(
                    completed: tenancy.completedRoomCount,
                    total: tenancy.rooms.count,
                    photos: tenancy.photoCount,
                    issues: tenancy.issueCount,
                    nextRoomName: viewModel.nextRoom?.name,
                    onContinue: { capturingRoom = viewModel.nextRoom },
                    onExport: { selectedTab = .export }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarBackground()
        .fullScreenCover(item: $capturingRoom) { room in
            CaptureView(viewModel: dependencies.captureViewModel(for: room))
        }
        .sheet(isPresented: $isPickingInspectionDate) {
            InspectionDateSheet(date: tenancy.moveOutInspection, onSave: viewModel.setMoveOutInspection)
        }
        .sheet(isPresented: $isShowingSettings) {
            TenancySettingsView(viewModel: dependencies.settingsViewModel(for: tenancy))
        }
        .errorAlert($viewModel.errorMessage)
    }

    private var keyDates: some View {
        DividedStack {
            KeyDateRow(title: "Condition report due", subtitle: tenancy.reportDue.longText) {
                reportDuePill
            }
            KeyDateRow(
                title: "Move-out inspection",
                subtitle: tenancy.moveOutInspection?.longText ?? "Not booked yet"
            ) {
                Button(tenancy.moveOutInspection == nil ? "Add date" : "Change") {
                    isPickingInspectionDate = true
                }
                .scaledFont(17, weight: .semibold)
                .foregroundStyle(Theme.brandStrong)
                .padding(.horizontal, 20)
                .frame(minHeight: 48)
                .background(Theme.brandTint, in: .capsule)
            }
            KeyDateRow(title: "Lease ends", subtitle: tenancy.leaseEnd.longText) {
                Pill(text: viewModel.leaseDaysLeft.counted("day"), tone: .neutral)
            }
        }
        .card()
    }

    @ViewBuilder
    private var reportDuePill: some View {
        let days = tenancy.reportDue.daysFromToday
        if tenancy.nextRoom == nil {
            Pill(text: "Ready", tone: .brand)
        } else if days < 0 {
            Pill(text: "Overdue", tone: .danger)
        } else if days == 0 {
            Pill(text: "Due today", tone: .warning)
        } else {
            Pill(text: "\(days.counted("day")) left", tone: .warning)
        }
    }
}

private struct PropertyCard: View {
    var tenancy: Tenancy

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: "house")
                .scaledFont(22, weight: .medium)
                .foregroundStyle(Theme.brand)
                .frame(width: 54, height: 54)
                .background(Theme.brandTint, in: .rect(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text(tenancy.streetAddress)
                    .scaledFont(20, weight: .semibold)
                    .foregroundStyle(Theme.textPrimary)
                if !tenancy.suburb.isEmpty {
                    Text(tenancy.suburb)
                        .scaledFont(18)
                        .foregroundStyle(Theme.textSecondary)
                }
                Text("Fixed term · \(tenancy.leaseStart.shortText) – \(tenancy.leaseEnd.shortText)")
                    .scaledFont(15)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .card(padding: 20)
    }
}

private struct KeyDateRow<Accessory: View>: View {
    var title: String
    var subtitle: String
    @ViewBuilder var accessory: Accessory

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // At accessibility text sizes, stack the button under the text so neither gets squeezed.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout())
        layout {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.rowTitle)
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.rowSubtitle)
                    .foregroundStyle(Theme.textSecondary)
            }
            if !typeSize.isAccessibilitySize { Spacer() }
            accessory
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(minHeight: 76)
    }
}

private struct MoveInProgressCard: View {
    var completed: Int
    var total: Int
    var photos: Int
    var issues: Int
    var nextRoomName: String?
    var onContinue: () -> Void
    var onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MOVE-IN REPORT")
                .scaledFont(14, weight: .semibold)
                .tracking(0.8)
                .foregroundStyle(Color(hex: 0x9AA4B4))

            Text(nextRoomName == nil ? "All rooms done" : "\(completed) of \(total) rooms done")
                .scaledFont(28, weight: .bold)
                .foregroundStyle(.white)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.heroTrack)
                    Capsule().fill(Theme.mint)
                        .frame(width: geo.size.width * CGFloat(completed) / CGFloat(max(total, 1)))
                }
            }
            .frame(height: 10)

            HStack(spacing: 24) {
                Text(photos.counted("photo"))
                Text("\(issues.counted("issue")) flagged")
            }
            .scaledFont(17)
            .foregroundStyle(Color(hex: 0xD7DCE3))

            Label("Stored on this iPhone", systemImage: "lock")
                .scaledFont(17)
                .foregroundStyle(Color(hex: 0xD7DCE3))

            Group {
                if let nextRoomName {
                    Button(action: onContinue) {
                        Label(photos == 0 ? "Start with \(nextRoomName)" : "Continue with \(nextRoomName)", systemImage: "camera")
                    }
                } else {
                    Button(action: onExport) {
                        Label("Export report", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .scaledFont(20, weight: .semibold)
            .buttonStyle(PrimaryButtonStyle(background: Theme.mint, foreground: Theme.onMint))
            .padding(.top, 4)
        }
        .padding(24)
        .background(Theme.heroBackground, in: .rect(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Theme.border.opacity(0.6), lineWidth: 1))
    }
}

private struct InspectionDateSheet: View {
    var date: Date?
    var onSave: (Date?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = Date()

    var body: some View {
        NavigationStack {
            DatePicker("Inspection date", selection: $draft, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .tint(Theme.brand)
                .padding()
                .navigationTitle("Move-out inspection")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    if date != nil {
                        ToolbarItem(placement: .destructiveAction) {
                            Button("Remove", role: .destructive) {
                                onSave(nil)
                                dismiss()
                            }
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave(draft)
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.large])
        .onAppear { draft = date ?? Date() }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: AppDependencies.preview.homeViewModel(for: AppStore.previewTenancy), selectedTab: .constant(.home))
    }
    .environment(AppDependencies.preview)
}
