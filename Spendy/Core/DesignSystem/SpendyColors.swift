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
    // MARK: - Global Mono Mode Flag
    // Set by ExpenseStore when isMonoIconMode changes. Allows static semantic colors
    // to resolve to monochrome without changing any call sites across the app.
    static var isMonoMode: Bool = false
    
    // Dynamic Base Backgrounds (#000000 in Dark Mode, #F6F6F6 in Light Mode for non-gradient surfaces & sheets)
    static let appBackground = Color(uiColor: .dynamic(
        light: UIColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1.0), // #F6F6F6
        dark: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)                           // #000000
    ))

    // Card Surfaces (#1A1A1A in Dark Mode, #FFFFFF in Light Mode)
    static let cardBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),                                               // #FFFFFF
        dark: UIColor(red: 26.0/255.0, green: 26.0/255.0, blue: 26.0/255.0, alpha: 1.0)      // #1A1A1A
    ))

    // Elevated Secondary Fill (Inside cards or pills)
    static let cardBackgroundSecondary = Color(uiColor: .dynamic(
        light: UIColor(red: 238.0/255.0, green: 238.0/255.0, blue: 238.0/255.0, alpha: 1.0), // #EEEEEE
        dark: UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)      // #262626
    ))

    // Sheet Card Surfaces (#1A1A1A in Dark Mode, #FFFFFF in Light Mode)
    static let sheetCardBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),                                               // #FFFFFF
        dark: UIColor(red: 26.0/255.0, green: 26.0/255.0, blue: 26.0/255.0, alpha: 1.0)      // #1A1A1A
    ))

    // Settings Background (#000000 in Dark Mode, #F6F6F6 in Light Mode)
    static let settingsBackground = Color(uiColor: .dynamic(
        light: UIColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1.0), // #F6F6F6
        dark: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)                           // #000000
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

    static let accentCyan = Color(uiColor: .systemCyan)
    static let vibrantPurple = Color(uiColor: .systemPurple)
    static let vibrantIndigo = Color(uiColor: .systemIndigo)

    // Status Beacons & Chips
    static var statusBeaconCoral: Color { isMonoMode ? textPrimary : Color(hex: "#FF5959") }
    static var statusBeaconGreen: Color { isMonoMode ? textPrimary : Color(hex: "#30D158") }
    static var statusBeaconAmber: Color { isMonoMode ? textPrimary : Color(hex: "#FF9F0A") }
    static let chipBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.05),
        dark: UIColor(white: 1.0, alpha: 0.08)
    ))
    static let chipBorder = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.08),
        dark: UIColor(white: 1.0, alpha: 0.12)
    ))

    // Semantic Status Colors — Mono-aware: resolve to textPrimary when Mono Mode is on
    static var expenseRed: Color { isMonoMode ? textPrimary : Color(uiColor: .systemRed) }
    static var incomeGreen: Color { isMonoMode ? textPrimary : Color(uiColor: .systemGreen) }
    static var transferBlue: Color { isMonoMode ? textPrimary : Color(uiColor: .systemBlue) }
    static var warningOrange: Color { isMonoMode ? textPrimary : Color(uiColor: .systemOrange) }
    static var goldYellow: Color { isMonoMode ? textPrimary : Color(uiColor: .systemYellow) }
    static var pinkSubscription: Color { isMonoMode ? textPrimary : Color(uiColor: .systemPink) }
    static var tealSavings: Color { isMonoMode ? textPrimary : Color(uiColor: .systemTeal) }

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
