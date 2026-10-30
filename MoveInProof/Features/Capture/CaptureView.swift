import SwiftUI

/// Camera screen. Uses the back camera; where there isn't one (the Simulator) it shows a drawn
/// placeholder and saves that instead, so the rest of the flow still works.
struct CaptureView: View {
    @State private var viewModel: CaptureViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var camera = CameraController()
    @State private var isShutterFlashing = false
    @State private var focusPoint: CGPoint?

    init(viewModel: CaptureViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
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
        // Camera controls sit around a fixed viewfinder; cap their growth so it stays usable.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .task { await camera.start() }
        .onDisappear { camera.stop() }
        .errorAlert($viewModel.errorMessage)
    }

    private var topBar: some View {
        HStack {
            cameraIconButton("xmark", label: "Close") { dismiss() }
            Spacer()
            Menu {
                Picker("Location", selection: $viewModel.location) {
                    ForEach(SampleData.captureLocations, id: \.self) { Text($0) }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.title)
                        .scaledFont(17, weight: .semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "chevron.down")
                        .scaledFont(13, weight: .bold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(minHeight: 48)
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
                    // No camera (the Simulator): show a drawn wall, which is saved like a photo.
                    WallScene()
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

                if canCapture, let tag = viewModel.selectedTag {
                    flagBanner(for: tag)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                        .allowsHitTesting(false)
                        .transition(.move(edge: .top).combined(with: .opacity))
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

    /// Says plainly that the tag the user picked will flag the next shot as an issue.
    private func flagBanner(for tag: String) -> some View {
        Label("Next photo will be flagged: \(tag == "More" ? "damage" : tag.lowercased())", systemImage: "exclamationmark.circle.fill")
            .scaledFont(15, weight: .semibold)
            .foregroundStyle(Theme.onMint)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.mint, in: .capsule)
    }

    private func cameraMessage(icon: String, title: String, detail: String, action: (String, () -> Void)? = nil) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .scaledFont(34)
                .foregroundStyle(Theme.mint)
            Text(title)
                .scaledFont(20, weight: .semibold)
                .foregroundStyle(.white)
            Text(detail)
                .scaledFont(16)
                .foregroundStyle(Color(hex: 0xB7BEC9))
                .multilineTextAlignment(.center)
            if let action {
                Button(action.0, action: action.1)
                    .scaledFont(17, weight: .semibold)
                    .foregroundStyle(Theme.onMint)
                    .padding(.horizontal, 22)
                    .frame(minHeight: 46)
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
                    let isSelected = viewModel.selectedTag == tag
                    Button {
                        withAnimation(.snappy) { viewModel.toggleTag(tag) }
                    } label: {
                        HStack(spacing: 6) {
                            if isSelected {
                                Image(systemName: "checkmark").scaledFont(14, weight: .bold)
                            }
                            Text(tag).scaledFont(17, weight: .semibold)
                        }
                        .foregroundStyle(isSelected ? Theme.onMint : .white)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 50)
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
                .overlay { PhotoThumbnail(fileName: viewModel.latestPhotoFileName, seed: 2) }
                .clipShape(.rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white, lineWidth: 2))
                .overlay(alignment: .topTrailing) {
                    if viewModel.photoCount > 0 {
                        Text("\(viewModel.photoCount)")
                            .scaledFont(14, weight: .bold)
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
                    .opacity(viewModel.isSaving || !canCapture ? 0.4 : 1)
            }
            .disabled(viewModel.isSaving || !canCapture)
            .accessibilityLabel("Take photo")

            Button("Done") {
                viewModel.finish()
                dismiss()
            }
                .scaledFont(19, weight: .semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(minHeight: 50)
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
                .scaledFont(19, weight: .semibold)
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
        withAnimation(.easeOut(duration: 0.08)) { isShutterFlashing = true }
        withAnimation(.easeIn(duration: 0.25).delay(0.08)) { isShutterFlashing = false }
        await viewModel.takePhoto(with: camera)
    }
}

#Preview {
    CaptureView(viewModel: AppDependencies.preview.captureViewModel(for: AppStore.previewTenancy.sortedRooms[5]))
}
