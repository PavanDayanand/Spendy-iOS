//
//  SpendyColors.swift
//  Spendy
//
//  Design Tokens and Semantic Colors for Spendy iOS
//

import SwiftUI

// MARK: - Color Extension for Hex Support
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

// MARK: - Spendy Color System
enum SpendyColors {
    // Base Backgrounds (Clean, native OLED Dark)
    static let appBackground = Color(hex: "#000000")
    static let cardBackground = Color(hex: "#141417")
    static let cardBackgroundSecondary = Color(hex: "#1C1C20")
    static let separator = Color.white.opacity(0.08)
    
    // Brand & Primary Accents (Native Apple HIG Palette)
    static let primaryBlue = Color(hex: "#007AFF")
    static let accentCyan = Color(hex: "#32ADE6")
    static let vibrantPurple = Color(hex: "#AF52DE")
    static let vibrantIndigo = Color(hex: "#5856D6")
    
    // Financial Status Colors
    static let expenseRed = Color(hex: "#FF453A")
    static let incomeGreen = Color(hex: "#30D158")
    static let transferBlue = Color(hex: "#0A84FF")
    static let warningOrange = Color(hex: "#FF9F0A")
    static let goldYellow = Color(hex: "#FFD60A")
    static let pinkSubscription = Color(hex: "#FF2D55")
    static let tealSavings = Color(hex: "#64D2FF")
    
    // Text Hierarchies
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textTertiary = Color.white.opacity(0.40)
}
