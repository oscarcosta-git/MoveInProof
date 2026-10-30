import SwiftUI

struct ExportView: View {
    @State private var viewModel: ExportViewModel
    @State private var sharedFile: ExportedFile?
    @State private var fileToSave: URL?

    init(viewModel: ExportViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(title: "Export report", subtitle: viewModel.summary)

                ReportPreview(tenancy: viewModel.tenancy, room: viewModel.includedRooms.first, includePhotos: viewModel.options.includePhotos)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .background(Theme.surfaceSunken, in: .rect(cornerRadius: 24))

                DividedStack {
                    ToggleRow(
                        title: "Include photos",
                        subtitle: "\(viewModel.includedPhotoCount.counted("photo")) with date and time",
                        isOn: $viewModel.options.includePhotos
                    )
                    ToggleRow(
                        title: "Flagged issues only",
                        subtitle: "Leave out rooms with no issues",
                        isOn: $viewModel.options.flaggedOnly
                    )
                }
                .card()

                VStack(spacing: 16) {
                    Button {
                        Task { sharedFile = await viewModel.generate().map(ExportedFile.init) }
                    } label: {
                        if viewModel.isGenerating {
                            ProgressView().tint(Theme.onBrand)
                        } else {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                        }
                    }
                    .buttonStyle(.primary)

                    Button("Save to Files") {
                        Task { fileToSave = await viewModel.generate() }
                    }
                    .buttonStyle(.secondary)
                }
                .disabled(!viewModel.canExport)
                .opacity(viewModel.includedRooms.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $sharedFile) { file in
            ShareSheet(url: file.url)
                .ignoresSafeArea()
                .presentationDetents([.medium, .large])
        }
        .fileMover(isPresented: Binding(get: { fileToSave != nil }, set: { if !$0 { fileToSave = nil } }), file: fileToSave) { result in
            if case .failure(let error) = result { viewModel.errorMessage = error.localizedDescription }
        }
        .errorAlert($viewModel.errorMessage)
    }
}

private struct ExportedFile: Identifiable {
    var url: URL
    var id: URL { url }
}

/// The system share sheet for a file.
private struct ShareSheet: UIViewControllerRepresentable {
    var url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
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
    NavigationStack { ExportView(viewModel: AppDependencies.preview.exportViewModel(for: AppStore.previewTenancy)) }
}
