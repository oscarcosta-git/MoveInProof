import SwiftData
import SwiftUI

struct ReportView: View {
    var tenancy: Tenancy

    @State private var capturingRoom: Room?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenHeader(
                    title: "Move-in report",
                    subtitle: "\(tenancy.streetAddress) · \(tenancy.completedRoomCount) of \(tenancy.rooms.count) rooms · \(tenancy.photoCount.counted("photo"))"
                )

                DividedStack {
                    ForEach(tenancy.sortedRooms) { room in
                        NavigationLink(value: room) {
                            RoomRow(room: room, status: tenancy.status(of: room))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .card()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationTitle("Move-in report")
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if let nextRoom = tenancy.nextRoom {
                Button {
                    capturingRoom = nextRoom
                } label: {
                    Label(nextRoom.photos.isEmpty ? "Start \(nextRoom.name)" : "Continue \(nextRoom.name)", systemImage: "camera")
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.background)
            }
        }
        .navigationDestination(for: Room.self) { room in
            RoomDetailView(room: room)
        }
        .navigationDestination(for: Issue.self) { issue in
            IssueDetailView(issue: issue)
        }
        .fullScreenCover(item: $capturingRoom) { room in
            CaptureView(room: room)
        }
    }
}

private struct RoomRow: View {
    var room: Room
    var status: RoomStatus

    var body: some View {
        HStack(spacing: 16) {
            StatusIndicator(status: status)

            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.rowTitle)
                    .foregroundStyle(Theme.textPrimary)
                statusText
            }

            Spacer()

            if !room.issues.isEmpty {
                Pill(text: room.issues.count.counted("issue"), tone: .danger)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 76)
        .contentShape(.rect)
    }

    @ViewBuilder
    private var statusText: some View {
        switch status {
        case .done:
            Text(room.photos.count.counted("photo"))
                .font(.rowSubtitle)
                .foregroundStyle(Theme.textSecondary)
        case .upNext:
            Text(room.photos.isEmpty ? "Up next" : "Up next · \(room.photos.count.counted("photo"))")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.brand)
        case .inProgress:
            Text("In progress · \(room.photos.count.counted("photo"))")
                .font(.rowSubtitle)
                .foregroundStyle(Theme.textSecondary)
        case .notStarted:
            Text("Not started")
                .font(.rowSubtitle)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

struct StatusIndicator: View {
    var status: RoomStatus

    var body: some View {
        switch status {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.onBrand)
                .frame(width: 32, height: 32)
                .background(Theme.brand, in: .circle)
        case .upNext:
            Circle()
                .strokeBorder(Theme.brand, lineWidth: 2)
                .frame(width: 32, height: 32)
        case .inProgress:
            Circle()
                .strokeBorder(Theme.textTertiary, lineWidth: 2)
                .overlay(Circle().fill(Theme.textTertiary).padding(9))
                .frame(width: 32, height: 32)
        case .notStarted:
            Circle()
                .strokeBorder(Theme.textTertiary, lineWidth: 2)
                .frame(width: 32, height: 32)
        }
    }
}

#Preview {
    NavigationStack { ReportView(tenancy: AppStore.previewTenancy) }
        .modelContainer(AppStore.preview)
}
