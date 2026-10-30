import SwiftData
import SwiftUI

/// Move-in vs move-out. Move-out capture isn't built yet, so this shows the move-in side
/// (existing issues and photos) and leaves the move-out side waiting.
struct CompareView: View {
    var tenancy: Tenancy

    @State private var selectedRoomID: PersistentIdentifier?

    // Rooms with flagged issues first, since that's where disputes happen.
    private var rooms: [Room] {
        tenancy.sortedRooms
            .filter { !$0.photos.isEmpty }
            .sorted { $0.issues.count > $1.issues.count }
    }

    private var selectedRoom: Room? {
        rooms.first { $0.id == selectedRoomID } ?? rooms.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(title: "Compare", subtitle: "\(selectedRoom?.name ?? "No rooms yet") · Move-in vs move-out")
                    .padding(.horizontal, 20)

                if let room = selectedRoom {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(rooms) { candidate in
                                FilterChip(title: candidate.name, isSelected: candidate == room) {
                                    withAnimation { selectedRoomID = candidate.id }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    comparison(for: room)
                        .padding(.horizontal, 20)
                } else {
                    Text("Photograph a room in your move-in report and it will show up here.")
                        .font(.rowSubtitle)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card(padding: 20)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarBackground()
    }

    private func comparison(for room: Room) -> some View {
        let moveInPhoto = room.sortedIssues.first?.sortedPhotos.first ?? room.sortedPhotos.first

        return VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 12) {
                CompareColumn(title: "Move-in", date: moveInPhoto?.capturedAt.shortText ?? "") {
                    PhotoThumbnail(fileName: moveInPhoto?.fileName)
                }
                CompareColumn(title: "Move-out", date: tenancy.moveOutInspection.map { "Booked \($0.shortText)" } ?? "Not taken yet") {
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .scaledFont(22, weight: .medium)
                        Text("Waiting for\nmove-out photos")
                            .scaledFont(13, weight: .medium)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.surfaceSunken)
                }
            }

            HStack(spacing: 12) {
                StatTile(value: "\(room.issues.count)", label: "Existing", tone: .brand)
                StatTile(value: "–", label: "New", tone: .danger)
                StatTile(value: "–", label: "No change", tone: .neutral)
            }

            if room.issues.isEmpty {
                Text("No issues were flagged in this room at move-in.")
                    .font(.rowSubtitle)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card(padding: 20)
            } else {
                DividedStack {
                    ForEach(room.sortedIssues) { issue in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(issue.title)
                                    .font(.rowTitle)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(issue.typeName), flagged at move-in")
                                    .font(.rowSubtitle)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Pill(text: CompareStatus.existing.rawValue, tone: CompareStatus.existing.tone)
                        }
                        .padding(.horizontal, 20)
                        .frame(minHeight: 76)
                    }
                }
                .card()
            }

            Text("New damage and unchanged areas will show here once you take your move-out photos.")
                .scaledFont(14)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

private struct CompareColumn<Content: View>: View {
    var title: String
    var date: String
    @ViewBuilder var image: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Color.clear
                .aspectRatio(1.2, contentMode: .fit)
                .overlay { image }
                .clipShape(.rect(cornerRadius: 18))
                .padding(.bottom, 8)
            Text(title)
                .font(.rowTitle)
                .foregroundStyle(Theme.textPrimary)
            Text(date)
                .font(.rowSubtitle)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatTile: View {
    var value: String
    var label: String
    var tone: PillTone

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .scaledFont(30, weight: .bold)
                .contentTransition(.numericText())
            Text(label)
                .scaledFont(16, weight: .semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(tone.foreground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(tone.background, in: .rect(cornerRadius: 16))
    }
}

private extension CompareStatus {
    var tone: PillTone {
        switch self {
        case .existing: .brand
        case .new: .danger
        case .noChange: .neutral
        }
    }
}

#Preview {
    NavigationStack { CompareView(tenancy: AppStore.previewTenancy) }
}
