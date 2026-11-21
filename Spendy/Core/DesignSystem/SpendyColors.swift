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
    /// Rendering is always monochrome, including shared widget badges.
    static let isMonoMode = true
    static let switchTint = Color(white: 0.45)
    
    // Dynamic Base Backgrounds (paper white in Light, pitch black in Dark)
    static let appBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),                                              // #FFFFFF
        dark: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)                           // #000000
    ))

    // Card Surfaces — opaque white in Light, solid opaque charcoal black in Dark
    static let cardBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),                                               // #FFFFFF
        dark: UIColor(white: 18.0/255.0, alpha: 1.0)      // Neutral charcoal
    ))

    // Home's activity drawer stays distinct from the flat page in both appearances.
    static let recentActivityBackground = Color(uiColor: UIColor { traits in
        let highContrast = traits.accessibilityContrast == .high
        let white: CGFloat = traits.userInterfaceStyle == .dark
            ? (highContrast ? 36.0 / 255.0 : 28.0 / 255.0)
            : (highContrast ? 232.0 / 255.0 : 242.0 / 255.0)
        return UIColor(white: white, alpha: 1)
    })

    // Elevated Secondary Fill (Inside cards or pills)
    static let cardBackgroundSecondary = Color(uiColor: .dynamic(
        light: UIColor(white: 246.0/255.0, alpha: 1.0), // Neutral light grey
        dark: UIColor(white: 30.0/255.0, alpha: 1.0)       // Neutral raised grey
    ))

    // Sheet Card Surfaces
    static let sheetCardBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),                                               // #FFFFFF
        dark: UIColor(white: 18.0/255.0, alpha: 1.0)      // #121214 Solid
    ))

    // Native grouped surfaces adapt to light/dark mode and sheet elevation.
    static let settingsBackground = Color(uiColor: .systemGroupedBackground)
    static let settingsCardBackground = Color(uiColor: .secondarySystemGroupedBackground)

    static let separator = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.10),
        dark: UIColor(white: 1.0, alpha: 0.08)
    ))

    // Dynamic Text Hierarchies
    static let textPrimary = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 1.0),
        dark: UIColor(white: 1.0, alpha: 1.0)
    ))

    static let textSecondary = Color(uiColor: UIColor { traits in
        let alpha: CGFloat = traits.accessibilityContrast == .high ? 0.85 : 0.60
        return UIColor(white: traits.userInterfaceStyle == .dark ? 1 : 0, alpha: alpha)
    })

    static let textTertiary = Color(uiColor: UIColor { traits in
        let alpha: CGFloat = traits.accessibilityContrast == .high ? 0.75 : 0.40
        return UIColor(white: traits.userInterfaceStyle == .dark ? 1 : 0, alpha: alpha)
    })

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

    // Transaction entry uses distinct adaptive surfaces so controls remain
    // readable against both the white canvas and the dark keypad tray.
    static let transactionControlSurface = Color(uiColor: .dynamic(
        light: UIColor(white: 246.0/255.0, alpha: 1.0),
        dark: UIColor(white: 28.0/255.0, alpha: 1.0)
    ))

    static let transactionTraySurface = Color(uiColor: .dynamic(
        light: UIColor(white: 246.0/255.0, alpha: 1.0),
        dark: UIColor(white: 20.0/255.0, alpha: 1.0)
    ))

    static let transactionKeySurface = Color(uiColor: .dynamic(
        light: UIColor(white: 1.0, alpha: 1.0),
        dark: UIColor(white: 28.0/255.0, alpha: 1.0)
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
        light: UIColor(white: 1.0, alpha: 0.78),
        dark: UIColor(white: 1.0, alpha: 0.08)
    ))

    // Tab Bar Accent follows the monochrome system.
    static let tabSelectedBlue = primaryBlue


    // Status Beacons & Chips
    static var statusBeaconCoral: Color { textPrimary }
    static var statusBeaconGreen: Color { textPrimary }
    static var statusBeaconAmber: Color { textPrimary }
    static var statusBeaconBlue: Color { textPrimary }
    static var statusBeaconYellow: Color { textPrimary }
    
    static let chipBackground = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.05),
        dark: UIColor(white: 1.0, alpha: 0.08)
    ))
    static let chipBorder = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.08),
        dark: UIColor(white: 1.0, alpha: 0.12)
    ))

    // Semantic Status Colors — Mono-aware: resolve to textPrimary when Mono Mode is on
    static var expenseRed: Color { textPrimary }
    static var incomeGreen: Color { textPrimary }
    static var transferBlue: Color { textPrimary }
    static var warningOrange: Color { textPrimary }
    static var dangerRed: Color { textPrimary }
    static var goldYellow: Color { textPrimary }
    static var pinkSubscription: Color { textPrimary }
    static var tealSavings: Color { textPrimary }

    // Static Helpers
    static let monochromeBlack = Color(hex: "#000000")
    static let monochromeWhite = Color(hex: "#FFFFFF")
    static let monochromeGray = Color(hex: "#71717A")

    // Interactive Pressed States
    static let pressedOverlay = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.04),
        dark: UIColor(white: 1.0, alpha: 0.06)
    ))
}

// MARK: - Light Mode Card Lift
private struct SpendyCardLiftModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        if colorScheme == .light {
            content
                .shadow(color: Color.black.opacity(0.045), radius: 2, y: 1)
                .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
        } else {
            content
        }
    }
}

extension View {
    /// Neutral elevation used so white cards separate from the paper canvas.
    func spendyCardLift() -> some View {
        modifier(SpendyCardLiftModifier())
    }
}
