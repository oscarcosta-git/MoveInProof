import SwiftUI
import UIKit

/// Colour tokens taken from the mockups. Each one adapts to light and dark mode.
enum Theme {
    static let background = Color(light: 0xF4F5F7, dark: 0x0B1018)
    static let surface = Color(light: 0xFFFFFF, dark: 0x19202B)
    static let surfaceSunken = Color(light: 0xE6E9EE, dark: 0x232B37)
    static let border = Color(light: 0xE1E4E9, dark: 0x2A3240)

    static let textPrimary = Color(light: 0x111827, dark: 0xF1F3F6)
    static let textSecondary = Color(light: 0x5B6472, dark: 0x9CA4B0)
    static let textTertiary = Color(light: 0x9AA2AE, dark: 0x6B7482)

    /// Primary action colour: deep teal in light mode, mint in dark mode.
    static let brand = Color(light: 0x35786F, dark: 0x6BCFC2)
    static let onBrand = Color(light: 0xFFFFFF, dark: 0x0B1018)
    static let brandTint = Color(light: 0xE3F1EF, dark: 0x173A35)
    static let brandStrong = Color(light: 0x22665C, dark: 0x7FD8CB)

    static let mint = Color(hex: 0x6BCFC2)
    static let onMint = Color(hex: 0x0E1520)

    static let heroBackground = Color(light: 0x121A2B, dark: 0x1C2738)
    static let heroTrack = Color(hex: 0x3A4352)

    static let danger = Color(light: 0x9B2C22, dark: 0xF09088)
    static let dangerTint = Color(light: 0xF7E2E0, dark: 0x3D1D1B)
    static let warning = Color(light: 0x8A5414, dark: 0xEDB65E)
    static let warningTint = Color(light: 0xF9EDD3, dark: 0x3A2B12)

    static let camera = Color(hex: 0x07090D)
    static let cameraControl = Color(hex: 0x2A2D33)
}

extension Font {
    // Built-in text styles, so they follow the user's Dynamic Type setting.
    static let screenTitle = Font.largeTitle.bold()
    static let cardTitle = Font.title3.weight(.semibold)
    static let rowTitle = Font.headline
    static let rowSubtitle = Font.subheadline
}

// nonisolated: SwiftUI can resolve dynamic colours on its background render thread,
// so this provider closure must not be main-actor isolated (that crashed the app).
nonisolated extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    init(light: UInt32, dark: UInt32) {
        let lightColor = UIColor(hex: light)
        let darkColor = UIColor(hex: dark)
        self.init(uiColor: UIColor { @Sendable traits in
            traits.userInterfaceStyle == .dark ? darkColor : lightColor
        })
    }
}

nonisolated extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
