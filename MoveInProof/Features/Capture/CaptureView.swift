import SwiftData
import SwiftUI

/// Camera screen. Uses the back camera; where there isn't one (the Simulator) it shows a drawn
/// placeholder and saves that instead, so the rest of the flow still works.
struct CaptureView: View {
    @Bindable var room: Room

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @State private var camera = CameraController()
    @State private var location = SampleData.captureLocations[0]
    @State private var selectedTag: String?
    @State private var isCapturing = false
    @State private var isShutterFlashing = false
    @State private var focusPoint: CGPoint?
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
        .task {
            await camera.start()
            // The placeholder scene has a scuff drawn on it, so suggest one like detection would.
            if camera.status == .unavailable { selectedTag = "Scuff" }
        }
        .onDisappear { camera.stop() }
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
            cameraIconButton(camera.isFlashOn ? "bolt.fill" : "bolt.slash", label: camera.isFlashOn ? "Flash on" : "Flash off") {
                camera.isFlashOn.toggle()
            }
            .disabled(camera.status == .ready && !camera.hasFlash)
        }
    }

    private var viewfinder: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                switch camera.status {
                case .ready:
                    CameraPreview(session: camera.worker.session) { devicePoint, viewPoint in
                        camera.focus(at: devicePoint)
                        showFocusRing(at: viewPoint)
                    }
                    if let focusPoint {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Theme.mint, lineWidth: 2)
                            .frame(width: 76, height: 76)
                            .position(focusPoint)
                            .allowsHitTesting(false)
                            .transition(.scale(scale: 1.4).combined(with: .opacity))
                    }
                case .unavailable:
                    placeholderScene(size: geo.size)
                case .denied:
                    cameraMessage(
                        icon: "camera.fill",
                        title: "Camera access is off",
                        detail: "Turn on camera access for MoveIn Proof in Settings to photograph your rooms.",
                        action: ("Open Settings", { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } })
                    )
                case .failed:
                    cameraMessage(icon: "exclamationmark.triangle.fill", title: "The camera couldn't start", detail: "Close this screen and try again.")
                case .starting:
                    ProgressView().tint(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if canCapture {
                    TimelineView(.everyMinute) { context in
                        TimestampLabel(text: context.date.timestampText)
                    }
                    .offset(x: 20, y: geo.size.height - 72)
                    .allowsHitTesting(false)
                }

                Color.white
                    .opacity(isShutterFlashing ? 0.8 : 0)
                    .allowsHitTesting(false)
            }
        }
        .background(Color.black)
        .clipShape(.rect(cornerRadius: 26))
    }

    /// The drawn wall with the mock detection overlay from the mockups.
    private func placeholderScene(size: CGSize) -> some View {
        let w = size.width
        let h = size.height
        return ZStack(alignment: .topLeading) {
            WallScene()
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
        }
    }

    private func cameraMessage(icon: String, title: String, detail: String, action: (String, () -> Void)? = nil) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(Theme.mint)
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
            Text(detail)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: 0xB7BEC9))
                .multilineTextAlignment(.center)
            if let action {
                Button(action.0, action: action.1)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.onMint)
                    .padding(.horizontal, 22)
                    .frame(height: 46)
                    .background(Theme.mint, in: .capsule)
                    .padding(.top, 6)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

            Button {
                Task { await takePhoto() }
            } label: {
                Circle()
                    .fill(.white)
                    .frame(width: 70, height: 70)
                    .padding(6)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 5))
                    .opacity(isCapturing || !canCapture ? 0.4 : 1)
            }
            .disabled(isCapturing || !canCapture)
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

    private var canCapture: Bool {
        camera.status == .ready || camera.status == .unavailable
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

    private func showFocusRing(at point: CGPoint) {
        withAnimation(.easeOut(duration: 0.2)) { focusPoint = point }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            if focusPoint == point {
                withAnimation(.easeIn(duration: 0.2)) { focusPoint = nil }
            }
        }
    }

    private func takePhoto() async {
        isCapturing = true
        defer { isCapturing = false }
        withAnimation(.easeOut(duration: 0.08)) { isShutterFlashing = true }
        withAnimation(.easeIn(duration: 0.25).delay(0.08)) { isShutterFlashing = false }

        let capturedAt = Date.now
        do {
            let image: UIImage
            if camera.status == .ready {
                image = PhotoStore.stamped(try await camera.capturePhoto(), at: capturedAt)
            } else if let placeholder = PhotoStore.renderPlaceholderPhoto(at: capturedAt) {
                image = placeholder
            } else {
                throw CocoaError(.fileWriteUnknown)
            }
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
