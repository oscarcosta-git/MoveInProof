import SwiftUI

/// A single room's photos and flagged issues. Not in the mockups; bridges the report list to the issue screen.
struct RoomDetailView: View {
    @State private var viewModel: RoomDetailViewModel

    @Environment(AppDependencies.self) private var dependencies
    @State private var isCapturing = false
    @State private var viewingPhoto: Photo?

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    init(viewModel: RoomDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var room: Room { viewModel.room }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenHeader(title: room.name, subtitle: viewModel.subtitle)

                if !room.issues.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Flagged issues")
                        DividedStack {
                            ForEach(room.sortedIssues) { issue in
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
                    if room.photos.isEmpty {
                        Text("No photos yet. Walk the room and photograph each wall, the floor and the ceiling.")
                            .font(.rowSubtitle)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .card(padding: 20)
                    } else {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(Array(room.sortedPhotos.enumerated()), id: \.element.id) { index, photo in
                                Button {
                                    viewingPhoto = photo
                                } label: {
                                    Color.clear
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay { PhotoThumbnail(fileName: photo.fileName, seed: index) }
                                        .clipShape(.rect(cornerRadius: 10))
                                        .overlay(alignment: .topTrailing) {
                                            if photo.issue != nil {
                                                Image(systemName: "exclamationmark.circle.fill")
                                                    .scaledFont(18)
                                                    .foregroundStyle(.white, Theme.danger)
                                                    .padding(6)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    if photo.issue == nil {
                                        Button("Flag as issue", systemImage: "exclamationmark.circle") { viewModel.flag(photo) }
                                    }
                                    Button("Delete photo", systemImage: "trash", role: .destructive) {
                                        viewModel.delete(photo)
                                    }
                                }
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
            ToolbarItem(placement: .topBarTrailing) {
                Button(room.isComplete ? "Reopen" : "Mark done") {
                    withAnimation { viewModel.toggleComplete() }
                }
                .disabled(!viewModel.canToggleComplete)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                isCapturing = true
            } label: {
                Label(room.photos.isEmpty ? "Start \(room.name)" : "Add photos", systemImage: "camera")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Theme.background)
        }
        .fullScreenCover(isPresented: $isCapturing) {
            CaptureView(viewModel: dependencies.captureViewModel(for: room))
        }
        .errorAlert($viewModel.errorMessage)
        .sheet(item: $viewingPhoto) { photo in
            PhotoViewer(photo: photo)
        }
    }
}

private struct IssueRow: View {
    var issue: Issue

    var body: some View {
        HStack(spacing: 14) {
            Color.clear
                .frame(width: 52, height: 52)
                .overlay { PhotoThumbnail(fileName: issue.sortedPhotos.first?.fileName) }
                .clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.title)
                    .font(.rowTitle)
                    .foregroundStyle(Theme.textPrimary)
                Text("\(issue.severity.rawValue) · \(issue.photos.count.counted("photo"))")
                    .font(.rowSubtitle)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .scaledFont(15, weight: .semibold)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(.rect)
    }
}

private struct PhotoViewer: View {
    var photo: Photo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PhotoThumbnail(fileName: photo.fileName)
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
                .navigationTitle(photo.location)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                    ToolbarItem(placement: .bottomBar) {
                        Text(photo.capturedAt.timestampText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NavigationStack { RoomDetailView(viewModel: AppDependencies.preview.roomDetailViewModel(for: AppStore.previewTenancy.sortedRooms[2])) }
        .environment(AppDependencies.preview)
}
