import SwiftUI
import UIKit

/// The subset of the app's colour tokens the widgets use.
/// Kept separate so the extension doesn't depend on app-only code.
enum WidgetTheme {
    static let background = Color(light: 0xFFFFFF, dark: 0x19202B)
    static let divider = Color(light: 0xE1E4E9, dark: 0x2A3240)
    static let textPrimary = Color(light: 0x111827, dark: 0xF1F3F6)
    static let textSecondary = Color(light: 0x5B6472, dark: 0x9CA4B0)
    static let brand = Color(light: 0x35786F, dark: 0x6BCFC2)
    static let brandStrong = Color(light: 0x22665C, dark: 0x7FD8CB)
    static let warning = Color(light: 0x8A5414, dark: 0xEDB65E)
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        let lightColor = UIColor(hex: light)
        let darkColor = UIColor(hex: dark)
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? darkColor : lightColor })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
