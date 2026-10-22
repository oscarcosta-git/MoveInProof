import SwiftUI

struct HomeView: View {
    @State private var tenancy = SampleData.tenancy
    @State private var isCapturing = false
    @State private var isPickingInspectionDate = false
    @State private var isShowingSettings = false

    var body: some View {
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

                if let next = SampleData.nextRoom {
                    MoveInProgressCard(
                        completed: SampleData.completedRooms,
                        total: SampleData.rooms.count,
                        photos: SampleData.totalPhotos,
                        issues: SampleData.totalIssues,
                        nextRoomName: next.name,
                        onContinue: { isCapturing = true }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $isCapturing) {
            CaptureView(roomName: SampleData.nextRoom?.name ?? "Bedroom 2")
        }
        .sheet(isPresented: $isPickingInspectionDate) {
            InspectionDateSheet(date: $tenancy.moveOutInspection)
        }
        .sheet(isPresented: $isShowingSettings) {
            TenancySettingsSheet(tenancy: tenancy)
        }
    }

    private var keyDates: some View {
        DividedStack {
            KeyDateRow(title: "Condition report due", subtitle: tenancy.reportDue) {
                Pill(text: "\(tenancy.reportDaysLeft) days left", tone: .warning)
            }
            KeyDateRow(
                title: "Move-out inspection",
                subtitle: tenancy.moveOutInspection.map { $0.formatted(.dateTime.weekday().day().month().year()) } ?? "Not booked yet"
            ) {
                Button(tenancy.moveOutInspection == nil ? "Add date" : "Change") {
                    isPickingInspectionDate = true
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.brandStrong)
                .padding(.horizontal, 20)
                .frame(height: 48)
                .background(Theme.brandTint, in: .capsule)
            }
            KeyDateRow(title: "Lease ends", subtitle: tenancy.leaseEnds) {
                Pill(text: "\(tenancy.leaseDaysLeft) days", tone: .neutral)
            }
        }
        .card()
    }
}

private struct PropertyCard: View {
    var tenancy: Tenancy

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: "house")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Theme.brand)
                .frame(width: 54, height: 54)
                .background(Theme.brandTint, in: .rect(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text(tenancy.streetAddress)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(tenancy.suburb)
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.textSecondary)
                Text(tenancy.term)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.rowTitle)
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.rowSubtitle)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            accessory
        }
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
    var nextRoomName: String
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MOVE-IN REPORT")
                .font(.system(size: 14, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color(hex: 0x9AA4B4))

            Text("\(completed) of \(total) rooms done")
                .font(.system(size: 28, weight: .bold))
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
                Text("\(photos) photos")
                Text("\(issues) issues flagged")
            }
            .font(.system(size: 17))
            .foregroundStyle(Color(hex: 0xD7DCE3))

            Label("Stored on this iPhone", systemImage: "lock")
                .font(.system(size: 17))
                .foregroundStyle(Color(hex: 0xD7DCE3))

            Button(action: onContinue) {
                Label("Continue with \(nextRoomName)", systemImage: "camera")
                    .font(.system(size: 20, weight: .semibold))
            }
            .buttonStyle(PrimaryButtonStyle(background: Theme.mint, foreground: Theme.onMint))
            .padding(.top, 4)
        }
        .padding(24)
        .background(Theme.heroBackground, in: .rect(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Theme.border.opacity(0.6), lineWidth: 1))
    }
}

private struct InspectionDateSheet: View {
    @Binding var date: Date?
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
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            date = draft
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.large])
        .onAppear { draft = date ?? Date() }
    }
}

private struct TenancySettingsSheet: View {
    var tenancy: Tenancy
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Property") {
                    LabeledContent("Address", value: tenancy.streetAddress)
                    LabeledContent("Suburb", value: tenancy.suburb)
                }
                Section("Lease") {
                    LabeledContent("Term", value: "Fixed term")
                    LabeledContent("Ends", value: tenancy.leaseEnds)
                }
            }
            .navigationTitle("Tenancy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

#Preview {
    NavigationStack { HomeView() }
}
