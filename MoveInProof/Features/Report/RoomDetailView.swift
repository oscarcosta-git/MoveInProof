import SwiftUI

/// A single room's photos and flagged issues. Not in the mockups; bridges the report list to the issue screen.
struct RoomDetailView: View {
    var room: Room

    @State private var isCapturing = false

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenHeader(title: room.name, subtitle: subtitle)

                if !room.issues.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Flagged issues")
                        DividedStack {
                            ForEach(room.issues) { issue in
                                NavigationLink(value: issue) {
                                    IssueRow(issue: issue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .card()
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Photos")
                    if room.photoCount == 0 {
                        Text("No photos yet. Walk the room and photograph each wall, the floor and the ceiling.")
                            .font(.rowSubtitle)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .card(padding: 20)
                    } else {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(0..<room.photoCount, id: \.self) { index in
                                PhotoSwatch(seed: index)
                                    .aspectRatio(1, contentMode: .fit)
                                    .clipShape(.rect(cornerRadius: 10))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { EmptyView() }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                isCapturing = true
            } label: {
                Label(room.photoCount == 0 ? "Start \(room.name)" : "Add photos", systemImage: "camera")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Theme.background)
        }
        .fullScreenCover(isPresented: $isCapturing) {
            CaptureView(roomName: room.name)
        }
    }

    private var subtitle: String {
        switch room.status {
        case .done: "\(room.photoCount) photos · \(room.issues.count) issues"
        case .upNext: "Up next"
        case .notStarted: "Not started"
        }
    }
}

private struct IssueRow: View {
    var issue: Issue

    var body: some View {
        HStack(spacing: 14) {
            BenchtopPhoto()
                .frame(width: 52, height: 52)
                .clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.title)
                    .font(.rowTitle)
                    .foregroundStyle(Theme.textPrimary)
                Text("\(issue.severity.rawValue) · \(issue.photoCount) photos")
                    .font(.rowSubtitle)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(.rect)
    }
}

#Preview {
    NavigationStack { RoomDetailView(room: SampleData.rooms[2]) }
}
