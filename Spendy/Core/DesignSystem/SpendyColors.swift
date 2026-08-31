//
//  SpendyColors.swift
//  Spendy
//
//  Adaptive Dynamic Monochrome Design Tokens for Spendy iOS
//

import SwiftUI
import UIKit

// MARK: - Color Extension for Hex & Dynamic Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }
        return "#4F46E5"
    }

    func clampedToDarkModeAccent() -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            // Clamp brightness to max 0.55 so bright/light colors (white, pastel pink, bright yellow)
            // are automatically turned into dark-mode-safe, rich saturated accent tones.
            let clampedBrightness = min(brightness, 0.55)
            let clampedSaturation = max(saturation, 0.35)
            let adjustedUIColor = UIColor(hue: hue, saturation: clampedSaturation, brightness: clampedBrightness, alpha: alpha)
            return Color(uiColor: adjustedUIColor)
        }
        return self
    }
}

extension UIColor {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}

// MARK: - Spendy Adaptive Monochrome Color System
enum SpendyColors {
    // Dynamic Base Backgrounds
    static let appBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),
        dark: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    ))

    static let cardBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),
        dark: UIColor(red: 20.0/255.0, green: 20.0/255.0, blue: 22.0/255.0, alpha: 1.0) // Sleek rich dark surface (#141416)
    ))

    static let cardBackgroundSecondary = Color(uiColor: .dynamic(
        light: UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0),
        dark: UIColor(red: 28.0/255.0, green: 28.0/255.0, blue: 30.0/255.0, alpha: 1.0) // Elevated secondary layer (#1C1C1E)
    ))

    static let sheetCardBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),
        dark: UIColor(red: 0.16, green: 0.16, blue: 0.173, alpha: 1.0)
    ))

    static let settingsBackground = Color(uiColor: .dynamic(
        light: UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1.0), // Apple systemGroupedBackground (#F2F2F7)
        dark: UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1.0)     // Sleek dark gray (#1C1C1E) in dark mode
    ))

    static let separator = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.08),
        dark: UIColor(white: 1.0, alpha: 0.08)
    ))

    // Dynamic Text Hierarchies
    static let textPrimary = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 1.0),
        dark: UIColor(white: 1.0, alpha: 1.0)
    ))

    static let textSecondary = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.60),
        dark: UIColor(white: 1.0, alpha: 0.60)
    ))

    static let textTertiary = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.40),
        dark: UIColor(white: 1.0, alpha: 0.40)
    ))

    // Monochrome Accents (Solid black in light mode, crisp white in dark mode)
    static let primaryBlue = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 1.0),
        dark: UIColor(white: 1.0, alpha: 1.0)
    ))

    static let inverseText = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),
        dark: UIColor(white: 0.0, alpha: 1.0)
    ))

    static let elevatedControlFill = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 1.0),
        dark: UIColor(white: 1.0, alpha: 1.0)
    ))

    static let elevatedControlForeground = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),
        dark: UIColor(white: 0.0, alpha: 1.0)
    ))

    static let monoGraphLine = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.88),
        dark: UIColor(white: 0.72, alpha: 1.0)
    ))

    static let monoGraphFill = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.14),
        dark: UIColor(white: 1.0, alpha: 0.12)
    ))

    static let glassFallbackFill = Color(uiColor: .dynamic(
        light: UIColor(white: 0.96, alpha: 0.78),
        dark: UIColor(white: 1.0, alpha: 0.08)
    ))

    // Tab Bar Accent follows the monochrome system.
    static let tabSelectedBlue = primaryBlue

    static let accentCyan = Color(uiColor: .dynamic(
        light: UIColor(white: 0.20, alpha: 1.0),
        dark: UIColor(white: 0.85, alpha: 1.0)
    ))

    static let vibrantPurple = Color(uiColor: .dynamic(
        light: UIColor(white: 0.30, alpha: 1.0),
        dark: UIColor(white: 0.80, alpha: 1.0)
    ))

    static let vibrantIndigo = Color(uiColor: .dynamic(
        light: UIColor(white: 0.25, alpha: 1.0),
        dark: UIColor(white: 0.85, alpha: 1.0)
    ))

    // Status Beacons & Chips
    static let statusBeaconCoral = Color(hex: "#FF5959")
    static let statusBeaconGreen = Color(hex: "#30D158")
    static let statusBeaconAmber = Color(hex: "#FF9F0A")
    static let chipBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.05),
        dark: UIColor(white: 1.0, alpha: 0.08)
    ))
    static let chipBorder = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.08),
        dark: UIColor(white: 1.0, alpha: 0.12)
    ))

    // Monochrome Status Colors
    static let expenseRed = Color(uiColor: .dynamic(
        light: UIColor(white: 0.15, alpha: 1.0),
        dark: UIColor(white: 0.95, alpha: 1.0)
    ))

    static let incomeGreen = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 1.0),
        dark: UIColor(white: 1.0, alpha: 1.0)
    ))

    static let transferBlue = Color(uiColor: .dynamic(
        light: UIColor(white: 0.40, alpha: 1.0),
        dark: UIColor(white: 0.70, alpha: 1.0)
    ))

    static let warningOrange = Color(uiColor: .dynamic(
        light: UIColor(white: 0.30, alpha: 1.0),
        dark: UIColor(white: 0.80, alpha: 1.0)
    ))

    static let goldYellow = Color(uiColor: .dynamic(
        light: UIColor(white: 0.35, alpha: 1.0),
        dark: UIColor(white: 0.75, alpha: 1.0)
    ))

    static let pinkSubscription = Color(uiColor: .dynamic(
        light: UIColor(white: 0.20, alpha: 1.0),
        dark: UIColor(white: 0.85, alpha: 1.0)
    ))

    static let tealSavings = Color(uiColor: .dynamic(
        light: UIColor(white: 0.25, alpha: 1.0),
        dark: UIColor(white: 0.80, alpha: 1.0)
    ))

    // Static Helpers
    static let monochromeBlack = Color(hex: "#000000")
    static let monochromeWhite = Color(hex: "#FFFFFF")
    static let monochromeGray = Color(hex: "#71717A")

    // Preset accent swatches
    static let presetAccentColors: [String] = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#00C7BE", "#007AFF", "#5856D6", "#AF52DE"
    ]
}
