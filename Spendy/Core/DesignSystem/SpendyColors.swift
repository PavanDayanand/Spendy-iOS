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
        dark: UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0)
    ))
    
    static let cardBackgroundSecondary = Color(uiColor: .dynamic(
        light: UIColor(red: 0.86, green: 0.86, blue: 0.89, alpha: 1.0),
        dark: UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
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
    
    // Monochrome Accents (Crisp White in Dark Mode, Solid Black in Light Mode)
    static let primaryBlue = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 1.0),
        dark: UIColor(white: 1.0, alpha: 1.0)
    ))
    
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
