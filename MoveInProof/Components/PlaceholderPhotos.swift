import SwiftUI

// Drawn stand-ins for real photos, so the UI can be built before the camera is wired up.

/// A benchtop edge with a chip, as in the Issue and Compare mockups.
struct BenchtopPhoto: View {
    var flagExisting = false
    var showNewDamage = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0xCFCCC3), Color(hex: 0xD9D6CD)], startPoint: .top, endPoint: .bottom)
                    .frame(height: h * 0.54)
                LinearGradient(colors: [Color(hex: 0xEAE6DC), Color(hex: 0xDCD8CC)], startPoint: .top, endPoint: .bottom)
                    .frame(height: h * 0.46)
                    .offset(y: h * 0.54)
                Rectangle()
                    .fill(Color(hex: 0xB8B4AA))
                    .frame(height: 2)
                    .offset(y: h * 0.54)

                Ellipse()
                    .fill(Color(hex: 0x7F786D).opacity(0.85))
                    .frame(width: w * 0.24, height: h * 0.08)
                    .rotationEffect(.degrees(-6))
                    .offset(x: w * 0.26, y: h * 0.5)

                if flagExisting {
                    DetectionBox(color: Theme.brand)
                        .frame(width: w * 0.36, height: h * 0.28)
                        .offset(x: w * 0.2, y: h * 0.42)
                }

                if showNewDamage {
                    Capsule()
                        .fill(Color(hex: 0x7F786D))
                        .frame(width: w * 0.2, height: 5)
                        .rotationEffect(.degrees(8))
                        .offset(x: w * 0.69, y: h * 0.78)
                    DetectionBox(color: Theme.danger)
                        .frame(width: w * 0.3, height: h * 0.22)
                        .offset(x: w * 0.64, y: h * 0.67)
                }
            }
        }
        .clipped()
    }
}

/// A bedroom wall with a window and a scuff, as seen through the capture viewfinder.
struct WallScene: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                Color(hex: 0xD6D1C6)

                // Window
                ZStack {
                    Rectangle().fill(Color(hex: 0xF3F1EA))
                    Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                        GridRow { pane; pane }
                        GridRow { pane; pane }
                    }
                    .padding(10)
                }
                .frame(width: w * 0.39, height: h * 0.34)
                .offset(x: w * 0.1, y: h * 0.08)

                // Light switch
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: 0xEFEDE7))
                    .frame(width: w * 0.066, height: h * 0.064)
                    .offset(x: w * 0.83, y: h * 0.415)

                // Scuff
                Ellipse()
                    .fill(RadialGradient(colors: [Color(hex: 0x6E665C).opacity(0.85), .clear], center: .center, startRadius: 2, endRadius: w * 0.16))
                    .frame(width: w * 0.36, height: h * 0.085)
                    .offset(x: w * 0.53, y: h * 0.585)

                // Skirting board and floor
                Rectangle()
                    .fill(Color(hex: 0xEDEAE1))
                    .frame(height: h * 0.025)
                    .offset(y: h * 0.723)
                LinearGradient(colors: [Color(hex: 0x8A7A5C), Color(hex: 0x6E5D42)], startPoint: .top, endPoint: .bottom)
                    .frame(height: h * 0.252)
                    .offset(y: h * 0.748)
            }
        }
    }

    private var pane: some View {
        LinearGradient(colors: [Color(hex: 0xB3D0EC), Color(hex: 0xE8F2FB)], startPoint: .top, endPoint: .bottom)
    }
}

/// Neutral textured tile used for thumbnails and report previews.
struct PhotoSwatch: View {
    var seed: Int = 0

    var body: some View {
        let tones: [UInt32] = [0xCFCAC0, 0xC2BCAF, 0xD8D4CB, 0xBDB7AA, 0xD1CCC1, 0xC6C0B3]
        LinearGradient(
            colors: [Color(hex: tones[seed % tones.count]), Color(hex: tones[(seed + 3) % tones.count])],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    VStack {
        BenchtopPhoto(flagExisting: true, showNewDamage: true).frame(height: 220)
        WallScene().frame(height: 400)
    }
}
