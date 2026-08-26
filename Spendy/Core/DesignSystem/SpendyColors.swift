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
        light: UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0),
        dark: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    ))
    
    static let cardBackground = Color(uiColor: .dynamic(
        light: UIColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1.0),
        dark: UIColor(red: 0.055, green: 0.055, blue: 0.058, alpha: 1.0) // Neutral Dark Grey-Black (#0E0E0F)
    ))
    
    static let cardBackgroundSecondary = Color(uiColor: .dynamic(
        light: UIColor(red: 0.86, green: 0.86, blue: 0.89, alpha: 1.0),
        dark: UIColor(red: 0.080, green: 0.080, blue: 0.085, alpha: 1.0) // Charcoal Grey Surface (#141416)
    ))
    
    static let sheetCardBackground = Color(uiColor: .dynamic(
        light: UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0),
        dark: UIColor(red: 0.145, green: 0.145, blue: 0.155, alpha: 1.0) // Elevated Sheet Card Gray (#252528)
    ))
    
    static let settingsBackground = Color(uiColor: .dynamic(
        light: UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0),
        dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // Apple Dark Gray Sheet (#1C1C1E)
    ))
    
    static let separator = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.08),
        dark: UIColor(white: 1.0, alpha: 0.07)
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
    
    // Monochrome Accents (Crisp White in Dark Mode, Solid Black in Light Mode)
    static let primaryBlue = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 1.0),
        dark: UIColor(white: 1.0, alpha: 1.0)
    ))
    
    // Tab Bar Accent Blue (Default Apple System Blue)
    static let tabSelectedBlue = Color.blue
    
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
}
