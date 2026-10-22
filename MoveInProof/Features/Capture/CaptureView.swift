import SwiftUI

/// Camera screen. The viewfinder shows a drawn placeholder until AVFoundation capture is added.
struct CaptureView: View {
    var roomName: String

    @Environment(\.dismiss) private var dismiss
    @State private var location = SampleData.captureLocations[0]
    @State private var selectedTag: String? = "Scuff"
    @State private var photoCount = 9
    @State private var isFlashOn = false
    @State private var isShutterFlashing = false

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
                    Text("\(roomName) · \(location)")
                        .font(.system(size: 17, weight: .semibold))
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
                if selectedTag != nil {
                    Label("Possible \((selectedTag ?? "scuff").lowercased())", systemImage: "sparkle")
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

                TimestampLabel(text: Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()) + " · " + Date.now.formatted(date: .omitted, time: .shortened))
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
            PhotoSwatch(seed: 2)
                .frame(width: 64, height: 64)
                .clipShape(.rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white, lineWidth: 2))
                .overlay(alignment: .topTrailing) {
                    Text("\(photoCount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.onMint)
                        .frame(minWidth: 28, minHeight: 28)
                        .background(Theme.mint, in: .circle)
                        .offset(x: 10, y: -10)
                        .contentTransition(.numericText())
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

            Button("Done") { dismiss() }
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
        withAnimation { photoCount += 1 }
    }
}

#Preview {
    CaptureView(roomName: "Bedroom 2")
}
