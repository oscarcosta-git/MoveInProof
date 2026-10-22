import SwiftUI

// MARK: - Layout

struct ScreenHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.screenTitle)
                .foregroundStyle(Theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionLabel: View {
    var text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 14, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(Theme.textSecondary)
            .padding(.leading, 4)
    }
}

/// Rounded white (or dark) card with a hairline border.
struct CardModifier: ViewModifier {
    var padding: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface, in: .rect(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border, lineWidth: 1))
    }
}

extension View {
    func card(padding: CGFloat = 0) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

/// Vertical stack of rows separated by hairlines, for use inside a card.
struct DividedStack<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { subviews in
                ForEach(Array(subviews.enumerated()), id: \.offset) { index, subview in
                    if index > 0 {
                        Rectangle().fill(Theme.border).frame(height: 1)
                    }
                    subview
                }
            }
        }
    }
}

// MARK: - Pills

enum PillTone {
    case brand, warning, danger, neutral

    var foreground: Color {
        switch self {
        case .brand: Theme.brandStrong
        case .warning: Theme.warning
        case .danger: Theme.danger
        case .neutral: Theme.textSecondary
        }
    }

    var background: Color {
        switch self {
        case .brand: Theme.brandTint
        case .warning: Theme.warningTint
        case .danger: Theme.dangerTint
        case .neutral: Theme.surfaceSunken
        }
    }
}

struct Pill: View {
    var text: String
    var tone: PillTone

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tone.foreground)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(tone.background, in: .capsule)
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var background: Color = Theme.brand
    var foreground: Color = Theme.onBrand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(background, in: .rect(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(Theme.brandStrong)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(Theme.surface, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.brand, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

struct CircleIconButton: View {
    var systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 48, height: 48)
                .background(Theme.surface, in: .circle)
                .overlay(Circle().strokeBorder(Theme.border, lineWidth: 1))
        }
    }
}

// MARK: - Chips

struct FilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.onBrand : Theme.textPrimary)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(isSelected ? Theme.brand : Theme.surface, in: .capsule)
                .overlay(Capsule().strokeBorder(isSelected ? .clear : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Overlays

struct TimestampLabel: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.black.opacity(0.72), in: .rect(cornerRadius: 8))
    }
}

/// Dashed outline marking a detected or flagged area on a photo.
struct DetectionBox: View {
    var color: Color = Theme.mint
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(color, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
    }
}
