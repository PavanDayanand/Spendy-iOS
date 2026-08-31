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

// MARK: - Typography Tokens (Apple HIG Dynamic Type & Scalable System Tokens)
public enum AppTypography {
    /// Scalable 42pt Heavy — Main Balance / Hero Amount
    public static let heroBalance = Font.system(size: 42, weight: .heavy, design: .rounded)
    
    /// Scalable 38pt Heavy — Large Metric / Sheet Hero Amount
    public static let heroLarge = Font.system(size: 38, weight: .heavy, design: .rounded)
    
    /// Scalable 34pt Heavy — Section Totals & Sub-hero Amounts
    public static let heroAmount = Font.system(size: 34, weight: .heavy, design: .rounded)
    
    /// Primary Screen Large Title (Scales with .largeTitle)
    public static let largeTitle = Font.system(.largeTitle, design: .default, weight: .heavy)
    
    /// Card Section Header Title (Scales with .title2)
    public static let title2 = Font.system(.title2, design: .default, weight: .bold)
    
    /// Section Headers (Scales with .title3)
    public static let sectionTitle = Font.system(.title3, design: .default, weight: .semibold)
    
    /// Modal & Sheet Titles (Scales with .headline / title3)
    public static let sheetTitle = Font.system(.headline, design: .default, weight: .bold)
    
    /// Card Titles & Major Items (Scales with .headline)
    public static let bodyBold = Font.system(.headline, design: .default, weight: .bold)
    
    /// Account / Category Names (Scales with .callout)
    public static let rowTitle = Font.system(.callout, design: .default, weight: .bold)
    
    /// Transaction Row Titles (Scales with .subheadline)
    public static let itemTitle = Font.system(.subheadline, design: .default, weight: .bold)
    
    /// Subtitle & Pill Controls (Scales with .subheadline)
    public static let subheadlineSemibold = Font.system(.subheadline, design: .default, weight: .semibold)
    
    /// Description & Secondary Labels (Scales with .footnote)
    public static let footnoteMedium = Font.system(.footnote, design: .default, weight: .medium)
    
    /// Tertiary / Micro Metadata (Scales with .caption)
    public static let captionMedium = Font.system(.caption, design: .default, weight: .medium)
    
    /// Section Header Eyebrows (UPPERCASE) (Scales with .caption2)
    public static let eyebrow = Font.system(.caption2, design: .default, weight: .bold)
    
    /// Micro Badge Text (Scales with .caption2)
    public static let badgeMicro = Font.system(.caption2, design: .default, weight: .bold)
    
    // Financial numbers with .rounded design & monospaced digits
    public static let numberHero = Font.system(size: 38, weight: .heavy, design: .rounded).monospacedDigit()
    public static let numberLarge = Font.system(.title2, design: .rounded, weight: .bold).monospacedDigit()
    public static let numberMedium = Font.system(.headline, design: .rounded, weight: .semibold).monospacedDigit()
    public static let numberSmall = Font.system(.subheadline, design: .rounded, weight: .medium).monospacedDigit()
    public static let numberCaption = Font.system(.caption, design: .rounded, weight: .bold).monospacedDigit()
}

// MARK: - Typography Helpers
public extension Font {
    /// Apple system font helper with Dynamic Type scaling
    static func spendyDynamic(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        Font.system(size: size, weight: weight, design: design)
    }
    
    /// Financial number font helper with rounded design and monospaced digits
    static func spendyNumber(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

// MARK: - Number Typography Modifier (Monospaced Digits & Rounded Design)
public struct SpendyNumberModifier: ViewModifier {
    var size: CGFloat
    var weight: Font.Weight
    var tracking: CGFloat?
    var design: Font.Design
    
    public init(size: CGFloat, weight: Font.Weight = .bold, tracking: CGFloat? = nil, design: Font.Design = .rounded) {
        self.size = size
        self.weight = weight
        self.tracking = tracking
        self.design = design
    }
    
    public func body(content: Content) -> some View {
        let text = content
            .font(.system(size: size, weight: weight, design: design))
            .monospacedDigit()
            .contentTransition(.numericText())
        
        if let tracking = tracking {
            text.tracking(tracking)
        } else {
            text
        }
    }
}

public extension View {
    /// Applies numeric font with monospaced digits and Apple rounded design
    func spendyNumberFont(size: CGFloat, weight: Font.Weight = .bold, tracking: CGFloat? = nil, design: Font.Design = .rounded) -> some View {
        modifier(SpendyNumberModifier(size: size, weight: weight, tracking: tracking, design: design))
    }
    
    /// Applies system font with specified size, weight, and design
    func spendyFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.font(.system(size: size, weight: weight, design: design))
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
