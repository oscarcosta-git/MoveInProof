import SwiftUI

struct ReportView: View {
    @State private var rooms = SampleData.rooms
    @State private var capturingRoom: Room?

    private var completed: Int { rooms.filter { $0.status == .done }.count }
    private var photos: Int { rooms.reduce(0) { $0 + $1.photoCount } }
    private var nextRoom: Room? { rooms.first { $0.status == .upNext } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenHeader(
                    title: "Move-in report",
                    subtitle: "\(SampleData.tenancy.streetAddress) · \(completed) of \(rooms.count) rooms · \(photos) photos"
                )

                DividedStack {
                    ForEach(rooms) { room in
                        NavigationLink(value: room) {
                            RoomRow(room: room)
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
            if let nextRoom {
                Button {
                    capturingRoom = nextRoom
                } label: {
                    Label("Start \(nextRoom.name)", systemImage: "camera")
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
            CaptureView(roomName: room.name)
        }
    }
}

private struct RoomRow: View {
    var room: Room

    var body: some View {
        HStack(spacing: 16) {
            StatusIndicator(status: room.status)

            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.rowTitle)
                    .foregroundStyle(Theme.textPrimary)
                statusText
            }

            Spacer()

            if !room.issues.isEmpty {
                Pill(text: room.issues.count == 1 ? "1 issue" : "\(room.issues.count) issues", tone: .danger)
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
        switch room.status {
        case .done:
            Text("\(room.photoCount) photos")
                .font(.rowSubtitle)
                .foregroundStyle(Theme.textSecondary)
        case .upNext:
            Text("Up next")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.brand)
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
        case .notStarted:
            Circle()
                .strokeBorder(Theme.textTertiary, lineWidth: 2)
                .frame(width: 32, height: 32)
        }
    }
}

#Preview {
    NavigationStack { ReportView() }
}
