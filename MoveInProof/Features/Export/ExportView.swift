import SwiftData
import SwiftUI

struct ExportView: View {
    var tenancy: Tenancy

    @State private var includePhotos = true
    @State private var flaggedOnly = false

    private var includedRooms: [Room] {
        tenancy.sortedRooms.filter { flaggedOnly ? !$0.issues.isEmpty : !$0.photos.isEmpty }
    }

    private var includedPhotoCount: Int {
        includedRooms.reduce(0) { $0 + $1.photos.count }
    }

    private var summary: String {
        // Rough estimates until a real PDF is generated: a cover page, then a page per room
        // plus a page per six photos, at roughly 90 KB per photo.
        let photoPages = includePhotos ? includedRooms.reduce(0) { $0 + ($1.photos.count + 5) / 6 } : 0
        let pages = 1 + includedRooms.count + photoPages
        let bytes = Int64(40_000 * pages + (includePhotos ? 90_000 * includedPhotoCount : 0))
        return "\(tenancy.streetAddress) · \(pages.counted("page")) · \(bytes.formatted(.byteCount(style: .file)))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(title: "Export report", subtitle: summary)

                ReportPreview(tenancy: tenancy, room: includedRooms.first, includePhotos: includePhotos)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .background(Theme.surfaceSunken, in: .rect(cornerRadius: 24))

                DividedStack {
                    ToggleRow(
                        title: "Include photos",
                        subtitle: "\(includedPhotoCount.counted("photo")) with date and time",
                        isOn: $includePhotos
                    )
                    ToggleRow(
                        title: "Flagged issues only",
                        subtitle: "Leave out rooms with no issues",
                        isOn: $flaggedOnly
                    )
                }
                .card()

                VStack(spacing: 16) {
                    // TODO: Generate the PDF and present the share sheet.
                    Button {} label: {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.primary)

                    // TODO: Present a document exporter.
                    Button("Save to Files") {}
                        .buttonStyle(.secondary)
                }
                .disabled(includedRooms.isEmpty)
                .opacity(includedRooms.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ToggleRow: View {
    var title: String
    var subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.rowTitle)
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.rowSubtitle)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .tint(Theme.brand)
        .padding(.horizontal, 20)
        .frame(minHeight: 76)
    }
}

/// Miniature first page of the condition report. Always light, like paper.
private struct ReportPreview: View {
    var tenancy: Tenancy
    var room: Room?
    var includePhotos: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Condition report")
                .font(.system(size: 15, weight: .semibold))
            Text([tenancy.streetAddress, tenancy.suburb].filter { !$0.isEmpty }.joined(separator: ", "))
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: 0x5B6472))
            Rectangle()
                .fill(Color(hex: 0x35786F))
                .frame(width: 36, height: 2)
                .padding(.vertical, 4)
            Text(room?.name ?? "No rooms to include")
                .font(.system(size: 13, weight: .semibold))

            if includePhotos, let room, !room.photos.isEmpty {
                LazyVGrid(columns: columns, spacing: 7) {
                    ForEach(Array(room.sortedPhotos.prefix(6).enumerated()), id: \.element.id) { index, photo in
                        Color.clear
                            .aspectRatio(1.15, contentMode: .fit)
                            .overlay { PhotoThumbnail(fileName: photo.fileName, seed: index) }
                            .clipShape(.rect(cornerRadius: 4))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                textLine(1)
                textLine(0.75)
                textLine(0.5)
            }
            .padding(.top, 4)

            Text("Photos timestamped on this iPhone")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: 0x5B6472))
                .padding(.top, 4)
        }
        .foregroundStyle(Color(hex: 0x111827))
        .padding(18)
        .frame(width: 252)
        .background(.white, in: .rect(cornerRadius: 6))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .environment(\.colorScheme, .light)
    }

    private func textLine(_ fraction: CGFloat) -> some View {
        GeometryReader { geo in
            Capsule()
                .fill(Color(hex: 0xDDE2E8))
                .frame(width: geo.size.width * fraction)
        }
        .frame(height: 4)
    }
}

#Preview {
    NavigationStack { ExportView(tenancy: AppStore.previewTenancy) }
        .modelContainer(AppStore.preview)
}
