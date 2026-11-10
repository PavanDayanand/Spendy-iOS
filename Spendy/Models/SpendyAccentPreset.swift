import SwiftUI

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
}
