//
//  SpendyGradientTypography.swift
//  Spendy
//
//  Vibrant Vertical Gradient Number & Typography System
//  Inspired by Reference Image 1 (Vertical Electric Blue to Crisp White Gradient).
//

import SwiftUI

// MARK: - Gradient Presets
public enum SpendyGradientPresets {
    /// Electric Blue fading to Crisp White (Dark Mode, on the black canvas)
    public static let electricBlueToWhite: [Color] = [
        Color(hex: "#2563EB"), // Vibrant Royal/Electric Blue
        Color(hex: "#60A5FA"), // Lighter Sky Blue
        Color(hex: "#FFFFFF")  // Crisp White
    ]
    
    /// Electric Blue fading to ink (Light Mode, on the paper canvas)
    public static let electricBlueToInk: [Color] = [
        Color(hex: "#2F6BFF"),
        Color(hex: "#1D4ED8"),
        Color(hex: "#111827")
    ]
    
    public static func heroAmount(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .light ? electricBlueToInk : electricBlueToWhite
    }
    
    /// Cyan to Icy White
    public static let cyanToWhite: [Color] = [
        Color(hex: "#06B6D4"),
        Color(hex: "#67E8F9"),
        Color(hex: "#FFFFFF")
    ]
    
    /// Emerald Green to Soft Mint
    public static let emeraldToMint: [Color] = [
        Color(hex: "#059669"),
        Color(hex: "#34D399"),
        Color(hex: "#FFFFFF")
    ]
    
    /// Dynamic Hero Gradient (Adapts to light/dark)
    public static func dynamicHero(for color: Color? = nil) -> [Color] {
        if let color = color {
            return [
                color,
                color.opacity(0.85),
                Color.white
            ]
        }
        return electricBlueToWhite
    }
}

// MARK: - Spendy Gradient Text View
public struct SpendyGradientText: View {
    let text: String
    var size: CGFloat = 38
    var weight: Font.Weight = .heavy
    var tracking: CGFloat = -1.0
    var colors: [Color] = SpendyGradientPresets.electricBlueToWhite
    var startPoint: UnitPoint = .top
    var endPoint: UnitPoint = .bottom
    @Environment(\.colorScheme) private var colorScheme
    
    private var resolvedColors: [Color] {
        if colors == SpendyGradientPresets.electricBlueToWhite {
            return SpendyGradientPresets.heroAmount(for: colorScheme)
        }
        return colors
    }
    
    public init(
        _ text: String,
        size: CGFloat = 38,
        weight: Font.Weight = .heavy,
        tracking: CGFloat = -1.0,
        colors: [Color] = SpendyGradientPresets.electricBlueToWhite,
        startPoint: UnitPoint = .top,
        endPoint: UnitPoint = .bottom
    ) {
        self.text = text
        self.size = size
        self.weight = weight
        self.tracking = tracking
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    public var body: some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: .monospaced))
            .monospacedDigit()
            .tracking(tracking)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(
                LinearGradient(
                    colors: resolvedColors,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .contentTransition(.numericText())
    }
}

// MARK: - View Modifier for Gradient Number Fill
public struct SpendyGradientNumberModifier: ViewModifier {
    var colors: [Color]
    var startPoint: UnitPoint
    var endPoint: UnitPoint
    @Environment(\.colorScheme) private var colorScheme
    
    private var resolvedColors: [Color] {
        if colors == SpendyGradientPresets.electricBlueToWhite {
            return SpendyGradientPresets.heroAmount(for: colorScheme)
        }
        return colors
    }
    
    public init(
        colors: [Color] = SpendyGradientPresets.electricBlueToWhite,
        startPoint: UnitPoint = .top,
        endPoint: UnitPoint = .bottom
    ) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    public func body(content: Content) -> some View {
        content
            .foregroundStyle(
                LinearGradient(
                    colors: resolvedColors,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
    }
}

public extension View {
    /// Applies a vertical linear gradient to text or icons (e.g. electric blue to white)
    func spendyGradientNumber(
        colors: [Color] = SpendyGradientPresets.electricBlueToWhite,
        startPoint: UnitPoint = .top,
        endPoint: UnitPoint = .bottom
    ) -> some View {
        modifier(SpendyGradientNumberModifier(colors: colors, startPoint: startPoint, endPoint: endPoint))
    }
}
