import SwiftUI

/// A drawn wall used as the viewfinder and saved photo where there's no camera (the Simulator).
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
    WallScene().frame(height: 320)
}
