//
//  AppTokens.swift
//  Spendy
//
//  Unified Design System Tokens for Spendy iOS
//  Standardized Spacing, Corner Radii, Typography, Motion Curves, and Glass Tokens
//

import SwiftUI

// MARK: - Spacing Scale (Blueprint §6)
public enum AppSpacing {
    /// 2pt — Micro spacing
    public static let xxs: CGFloat = 2
    /// 4pt — Tight intra-element padding
    public static let xs: CGFloat = 4
    /// 6pt — Compact badge padding
    public static let sm6: CGFloat = 6
    /// 8pt — Small gap between related items
    public static let sm: CGFloat = 8
    /// 10pt — Button group spacing
    public static let md10: CGFloat = 10
    /// 12pt — Standard card intra-element spacing
    public static let md12: CGFloat = 12
    /// 14pt — Standard pill / row horizontal padding
    public static let md14: CGFloat = 14
    /// 16pt — Default content margin & standard card padding
    public static let md: CGFloat = 16
    /// 18pt — Elevated card padding
    public static let lg18: CGFloat = 18
    /// 20pt — Screen horizontal margin
    public static let lg20: CGFloat = 20
    /// 24pt — Major section spacing
    public static let lg: CGFloat = 24
    /// 32pt — Large screen separation
    public static let xl: CGFloat = 32
    /// 40pt — Hero section spacing
    public static let xxl: CGFloat = 40
}

// MARK: - Corner Radii (Blueprint §6)
public enum AppRadius {
    /// 4pt — Micro elements & indicators
    public static let micro: CGFloat = 4
    /// 8pt — Small tags & badges
    public static let xs: CGFloat = 8
    /// 12pt — Standard compact controls & inputs
    public static let small: CGFloat = 12
    /// 16pt — Sub-cards & nested blocks
    public static let medium: CGFloat = 16
    /// 18pt — Standard row cards
    public static let cardRow: CGFloat = 18
    /// 20pt — Standard cards & dropdown surfaces
    public static let card: CGFloat = 20
    /// 22pt — Elevated metric cards & graph panels
    public static let cardLarge: CGFloat = 22
    /// 24pt — Major container cards
    public static let large: CGFloat = 24
    /// 26pt — Analytics & breakdown cards
    public static let xl: CGFloat = 26
    /// 28pt — Drawers & custom sheet surfaces
    public static let drawer: CGFloat = 28
    /// 32pt — Native modal sheets
    public static let sheet: CGFloat = 32
    /// 999pt — Pill & Capsule shapes
    public static let pill: CGFloat = 999
}

// MARK: - Typography Tokens (Default Apple System Typography)
public enum AppTypography {
    /// 42pt Heavy — Main Balance / Hero Amount
    public static let heroBalance = Font.system(size: 42, weight: .heavy, design: .default)
    
    /// 38pt Heavy — Large Metric / Sheet Hero Amount
    public static let heroLarge = Font.system(size: 38, weight: .heavy, design: .default)
    
    /// 34pt Heavy — Section Totals & Sub-hero Amounts
    public static let heroAmount = Font.system(size: 34, weight: .heavy, design: .default)
    
    /// 32pt Heavy — Primary Screen Large Title
    public static let largeTitle = Font.system(size: 32, weight: .heavy, design: .default)
    
    /// 24pt Bold — Card Section Header Title
    public static let title2 = Font.system(size: 24, weight: .bold, design: .default)
    
    /// 20pt Semibold — Section Headers
    public static let sectionTitle = Font.system(size: 20, weight: .semibold, design: .default)
    
    /// 18pt Bold — Modal & Sheet Titles
    public static let sheetTitle = Font.system(size: 18, weight: .bold, design: .default)
    
    /// 17pt Bold — Card Titles & Major Items
    public static let bodyBold = Font.system(size: 17, weight: .bold, design: .default)
    
    /// 16pt Bold — Account / Category Names
    public static let rowTitle = Font.system(size: 16, weight: .bold, design: .default)
    
    /// 15pt Bold — Transaction Row Titles
    public static let itemTitle = Font.system(size: 15, weight: .bold, design: .default)
    
    /// 14pt Semibold — Subtitle & Pill Controls
    public static let subheadlineSemibold = Font.system(size: 14, weight: .semibold, design: .default)
    
    /// 13pt Medium — Description & Secondary Labels
    public static let footnoteMedium = Font.system(size: 13, weight: .medium, design: .default)
    
    /// 12pt Medium — Tertiary / Micro Metadata
    public static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
    
    /// 11pt Bold Tracked — Section Header Eyebrows (UPPERCASE)
    public static let eyebrow = Font.system(size: 11, weight: .bold, design: .default)
    
    /// 10pt Bold Tracked — Micro Badge Text
    public static let badgeMicro = Font.system(size: 10, weight: .bold, design: .default)
}

// MARK: - Typography Helpers
public extension Font {
    /// Apple default system font helper
    static func spendyCompact(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Number Typography Modifier (Monospaced Digits)
public struct SpendyNumberModifier: ViewModifier {
    var size: CGFloat
    var weight: Font.Weight
    var tracking: CGFloat?
    
    public init(size: CGFloat, weight: Font.Weight = .bold, tracking: CGFloat? = nil) {
        self.size = size
        self.weight = weight
        self.tracking = tracking
    }
    
    public func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: .default))
            .monospacedDigit()
    }
}

public extension View {
    /// Applies numeric font with monospaced digits
    func spendyNumberFont(size: CGFloat, weight: Font.Weight = .bold, tracking: CGFloat? = nil) -> some View {
        modifier(SpendyNumberModifier(size: size, weight: weight, tracking: tracking))
    }
    
    /// Applies system font with specified size and weight
    func spendyFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: size, weight: weight, design: .default))
    }
}

// MARK: - Motion Tokens (Blueprint §6 & §20)
public enum AppMotion {
    /// Standard interactive transition spring (response: 0.35, damping: 0.80)
    public static let standardSpring = Animation.spring(response: 0.35, dampingFraction: 0.80)
    
    /// Snappy feedback spring for taps & toggles (response: 0.28, damping: 0.72)
    public static let snappySpring = Animation.spring(response: 0.28, dampingFraction: 0.72)
    
    /// Fluid spring for hero transitions & drawer presentations (response: 0.38, damping: 0.82)
    public static let fluidSpring = Animation.spring(response: 0.38, dampingFraction: 0.82)
    
    /// Gentle spring for mesh gradients & background transitions (response: 0.60, damping: 0.85)
    public static let gentleSpring = Animation.spring(response: 0.60, dampingFraction: 0.85)
}

// MARK: - Glass Tokens (Blueprint §6 & §13)
public enum AppGlass {
    public static let standardCornerRadius: CGFloat = AppRadius.card
    public static let pillHeight: CGFloat = 44
    public static let buttonSize: CGFloat = 44
    public static let largeFabSize: CGFloat = 54
    public static let strokeWidth: CGFloat = 0.8
    public static let innerGlowOpacity: Double = 0.12
}
