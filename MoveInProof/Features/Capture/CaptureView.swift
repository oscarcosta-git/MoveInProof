import SwiftData
import SwiftUI

/// Camera screen. The viewfinder shows a drawn placeholder until AVFoundation capture is added;
/// the shutter saves that placeholder as a real photo file so storage works end to end.
struct CaptureView: View {
    @Bindable var room: Room

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var location = SampleData.captureLocations[0]
    @State private var selectedTag: String? = "Scuff"
    @State private var isFlashOn = false
    @State private var isShutterFlashing = false
    @State private var saveError: String?

    var body: some View {
        VStack(spacing: 16) {
            topBar
            viewfinder
            tagRow
            bottomControls
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .background(Theme.camera.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .alert("Couldn't save the photo", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            cameraIconButton("xmark", label: "Close") { dismiss() }
            Spacer()
            Menu {
                Picker("Location", selection: $location) {
                    ForEach(SampleData.captureLocations, id: \.self) { Text($0) }
                }
            } label: {
                HStack(spacing: 8) {
                    Text("\(room.name) · \(location)")
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 48)
                .background(Theme.cameraControl, in: .capsule)
            }
            Spacer()
            cameraIconButton(isFlashOn ? "bolt.fill" : "bolt", label: "Flash") { isFlashOn.toggle() }
        }
    }

    private var viewfinder: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                WallScene()

                // On-device detection overlay
                if let selectedTag {
                    Label("Possible \(selectedTag == "More" ? "damage" : selectedTag.lowercased())", systemImage: "sparkle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.onMint)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(Theme.mint, in: .rect(cornerRadius: 8))
                        .offset(x: w * 0.53, y: h * 0.497)
                    DetectionBox()
                        .frame(width: w * 0.4, height: h * 0.146)
                        .offset(x: w * 0.49, y: h * 0.555)
                }

                TimelineView(.everyMinute) { context in
                    TimestampLabel(text: context.date.timestampText)
                }
                .offset(x: 20, y: h - 72)

                Color.white
                    .opacity(isShutterFlashing ? 0.8 : 0)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(.rect(cornerRadius: 26))
    }

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SampleData.captureTags, id: \.self) { tag in
                    let isSelected = selectedTag == tag
                    Button {
                        selectedTag = isSelected ? nil : tag
                    } label: {
                        HStack(spacing: 6) {
                            if isSelected {
                                Image(systemName: "checkmark").font(.system(size: 14, weight: .bold))
                            }
                            Text(tag).font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(isSelected ? Theme.onMint : .white)
                        .padding(.horizontal, 18)
                        .frame(height: 50)
                        .background(isSelected ? Theme.mint : Theme.cameraControl, in: .capsule)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var bottomControls: some View {
        HStack {
            Color.clear
                .frame(width: 64, height: 64)
                .overlay { PhotoThumbnail(fileName: room.sortedPhotos.last?.fileName, seed: 2) }
                .clipShape(.rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white, lineWidth: 2))
                .overlay(alignment: .topTrailing) {
                    if !room.photos.isEmpty {
                        Text("\(room.photos.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.onMint)
                            .frame(minWidth: 28, minHeight: 28)
                            .background(Theme.mint, in: .circle)
                            .offset(x: 10, y: -10)
                            .contentTransition(.numericText())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: takePhoto) {
                Circle()
                    .fill(.white)
                    .frame(width: 70, height: 70)
                    .padding(6)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 5))
            }
            .accessibilityLabel("Take photo")

            Button("Done", action: finish)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(height: 50)
                .background(Theme.cameraControl, in: .capsule)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 4)
    }

    private func cameraIconButton(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Theme.cameraControl, in: .circle)
        }
        .accessibilityLabel(label)
    }

    private func takePhoto() {
        withAnimation(.easeOut(duration: 0.08)) { isShutterFlashing = true }
        withAnimation(.easeIn(duration: 0.25).delay(0.08)) { isShutterFlashing = false }

        let capturedAt = Date.now
        do {
            guard let image = PhotoStore.renderPlaceholderPhoto(at: capturedAt) else { throw CocoaError(.fileWriteUnknown) }
            let fileName = try PhotoStore.save(image)
            let photo = Photo(fileName: fileName, capturedAt: capturedAt, location: location)
            context.insert(photo)
            withAnimation { photo.room = room }

            // A selected tag flags this shot as an issue, then clears so the next shot is a plain photo.
            if let selectedTag {
                let kind = selectedTag == "More" ? "damage" : selectedTag.lowercased()
                let issue = Issue(title: "\(kind.capitalized) on \(location.lowercased())", suggestion: kind, createdAt: capturedAt)
                context.insert(issue)
                issue.room = room
                photo.issue = issue
                self.selectedTag = nil
            }
            try context.save()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func finish() {
        if !room.photos.isEmpty {
            room.isComplete = true
            try? context.save()
        }
        dismiss()
    }
}

#Preview {
    CaptureView(room: AppStore.previewTenancy.sortedRooms[5])
        .modelContainer(AppStore.preview)
}
