import SwiftUI
import UIKit

/// A deliberately small palette for primary actions, independent of financial status colors.
enum SpendyAccentPreset: String, Codable, CaseIterable, Identifiable, Sendable {
    case blue, green, pink, yellow, white

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    private var components: (red: Double, green: Double, blue: Double) {
        switch self {
        // A deeper blue keeps white action labels readable.
        case .blue: (0, 112.0 / 255, 224.0 / 255)
        case .green: (48.0 / 255, 209.0 / 255, 88.0 / 255)
        case .pink: (1, 100.0 / 255, 130.0 / 255)
        case .yellow: (1, 214.0 / 255, 10.0 / 255)
        case .white: (1, 1, 1)
        }
    }

    var fill: Color {
        let rgb = components
        return Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: 1)
    }

    /// Compare black and white against the fill using linear sRGB luminance.
    var usesLightForeground: Bool {
        let rgb = components
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linear(rgb.red) + 0.7152 * linear(rgb.green) + 0.0722 * linear(rgb.blue)
        let whiteContrast = 1.05 / (luminance + 0.05)
        let blackContrast = (luminance + 0.05) / 0.05
        return whiteContrast > blackContrast
    }

    var foreground: Color { usesLightForeground ? .white : .black }

    /// White remains an adaptive neutral selection in both appearances.
    var selectionFill: Color { self == .white ? SpendyColors.elevatedControlFill : fill }
    var selectionForeground: Color { self == .white ? SpendyColors.elevatedControlForeground : foreground }

    /// Small glyphs, links, and chart highlights need contrast against their surface.
    var contentTint: Color {
        guard self != .white else { return SpendyColors.textPrimary }
        return Color(uiColor: .dynamic(
            light: adjustedColor(against: 1, minimumContrast: 4.5, towardsWhite: false),
            dark: adjustedColor(against: 0.05, minimumContrast: 4.5, towardsWhite: true)
        ))
    }

    /// Preserve separation from the native switch's white thumb.
    var switchTint: Color {
        guard self != .white else { return Color(white: 0.45) }
        return Color(uiColor: adjustedColor(against: 1, minimumContrast: 3, towardsWhite: false))
    }

    private func adjustedColor(against background: Double, minimumContrast: Double, towardsWhite: Bool) -> UIColor {
        let rgb = components
        func luminance(_ red: Double, _ green: Double, _ blue: Double) -> Double {
            func linear(_ value: Double) -> Double {
                value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        }
        let target = towardsWhite ? 1.0 : 0.0
        var amount = 0.0
        var red = rgb.red, green = rgb.green, blue = rgb.blue
        for _ in 0..<101 {
            red = rgb.red + (target - rgb.red) * amount
            green = rgb.green + (target - rgb.green) * amount
            blue = rgb.blue + (target - rgb.blue) * amount
            let value = luminance(red, green, blue)
            let ratio = (max(value, background) + 0.05) / (min(value, background) + 0.05)
            if ratio >= minimumContrast { break }
            amount = min(1, amount + 0.01)
        }
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

}
