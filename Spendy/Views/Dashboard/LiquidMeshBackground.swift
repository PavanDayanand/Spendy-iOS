//
//  LiquidMeshBackground.swift
//  Spendy
//
//  Adaptive edge-to-edge ambient header gradient background with fluid liquid mesh animation.
//  Blends the signature electric blue palette into a canvas that follows appearance:
//  - Deep Electric Blue (#1B17E9)
//  - Royal Blue (#1870FF)
//  - Neon Electric Blue (#00E5FF)
//  - Pitch black in Dark, paper white in Light.
//

import SwiftUI

// MARK: - Spendy Signature Palette
public enum SpendySignatureTheme {
    /// 1. Pure Pitch / AMOLED Black Canvas (Dark)
    public static let pitchBlack = Color(hex: "#000000")
    /// Paper white canvas (Light)
    public static let paperWhite = Color(hex: "#FFFFFF")
    /// 2. Deep Electric Ultramarine Blue (Core Brand Blue)
    public static let deepElectricBlue = Color(hex: "#1B17E9")
    /// 3. Deep Saturated Royal Blue ("blur / royal blue")
    public static let royalBlue = Color(hex: "#1870FF")
    /// 4. Luminous Electric Neon Blue
    public static let neonBlue = Color(hex: "#00E5FF")
    /// Softer sky blue used for the Light Mode wash
    public static let skyBlue = Color(hex: "#4C8DFF")
    
    // Hex String Constants for user reference
    public static let hexPitchBlack = "#000000"
    public static let hexPaperWhite = "#FFFFFF"
    public static let hexDeepElectricBlue = "#1B17E9"
    public static let hexRoyalBlue = "#1870FF"
    public static let hexNeonBlue = "#00E5FF"
}

public struct LiquidMeshBackground: View {
    @Environment(ExpenseStore.self) private var store
    
    public enum Style {
        case screen
        case sheet
    }
    
    public var color: Color? = nil
    public var style: Style = .screen
    public var height: CGFloat? = nil
    public var opacity: Double = 0.44
    
    @State private var isDrifting: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    
    private var isLight: Bool { colorScheme == .light }
    
    public init(
        color: Color? = nil,
        style: Style = .screen,
        height: CGFloat? = nil,
        opacity: Double = 0.44
    ) {
        self.color = color
        self.style = style
        self.height = height
        self.opacity = opacity
    }
    
    private var effectiveHeight: CGFloat {
        if let height = height { return height }
        return style == .sheet ? 380 : 540
    }
    
    // Default signature 4-layer palette
    private var baseDeepElectricBlue: Color {
        SpendySignatureTheme.deepElectricBlue
    }
    
    private var baseRoyalBlue: Color {
        SpendySignatureTheme.royalBlue
    }
    
    private var baseTopColor: Color {
        isLight ? SpendySignatureTheme.skyBlue : SpendySignatureTheme.pitchBlack
    }
    
    private var canvasColor: Color {
        SpendyColors.appBackground
    }
    
    private var meshStrength: Double {
        isLight ? 0.62 : 1.0
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let totalScreenHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            let calculatedHeight = height ?? (style == .sheet ? totalScreenHeight * 0.55 : totalScreenHeight * 0.80)
            
            ZStack {
                canvasColor
                    .ignoresSafeArea()
                
                if style == .sheet {
                    // Sheet Ambient Multi-Blue Header Glow
                    sheetAmbientHeader(effectiveHeight: calculatedHeight)
                } else if store.isGradientBackgroundEnabled {
                    // Main App Screen Fluid Multi-Blue Animated Liquid Mesh (Covers 80% of screen, 20% black base)
                    screenFluidMesh(effectiveHeight: calculatedHeight)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: store.isGradientBackgroundEnabled)
            .animation(.easeInOut(duration: 0.28), value: colorScheme)
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Screen Fluid Multi-Blue Mesh Background
    private func screenFluidMesh(effectiveHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                LinearGradient(
                    stops: [
                        .init(color: baseTopColor.opacity(opacity * meshStrength * (isLight ? 0.72 : 1.0)), location: 0.0),
                        .init(color: baseRoyalBlue.opacity(opacity * meshStrength * (isLight ? 0.88 : 1.05)), location: 0.20),
                        .init(color: (isLight ? baseRoyalBlue : baseDeepElectricBlue).opacity(opacity * meshStrength * (isLight ? 0.70 : 1.15)), location: 0.45),
                        .init(color: (isLight ? SpendySignatureTheme.skyBlue : baseDeepElectricBlue).opacity(opacity * meshStrength * (isLight ? 0.28 : 0.60)), location: 0.72),
                        .init(color: canvasColor.opacity(0.0), location: 1.0)
                    ],
                    startPoint: (isDrifting && !reduceMotion) ? .topTrailing : .topLeading,
                    endPoint: (isDrifting && !reduceMotion) ? .bottomLeading : .bottomTrailing
                )
                
                Circle()
                    .fill((isLight ? baseRoyalBlue : baseDeepElectricBlue).opacity(opacity * meshStrength * (isLight ? 0.55 : 1.0)))
                    .frame(width: 420, height: 420)
                    .offset(
                        x: (isDrifting && !reduceMotion) ? 35 : -55,
                        y: (isDrifting && !reduceMotion) ? 20 : -30
                    )
                    .scaleEffect((isDrifting && !reduceMotion) ? 1.10 : 0.94)
                    .blur(radius: isLight ? 88 : 78)
                
                Circle()
                    .fill(baseRoyalBlue.opacity(opacity * meshStrength * (isLight ? 0.42 : 0.85)))
                    .frame(width: 360, height: 360)
                    .offset(
                        x: (isDrifting && !reduceMotion) ? -60 : 50,
                        y: (isDrifting && !reduceMotion) ? 80 : 40
                    )
                    .scaleEffect((isDrifting && !reduceMotion) ? 0.95 : 1.14)
                    .blur(radius: isLight ? 78 : 68)
                
                Circle()
                    .fill((isLight ? SpendySignatureTheme.skyBlue : baseRoyalBlue).opacity(opacity * meshStrength * (isLight ? 0.38 : 0.65)))
                    .frame(width: 280, height: 280)
                    .offset(
                        x: (isDrifting && !reduceMotion) ? 70 : -35,
                        y: (isDrifting && !reduceMotion) ? -40 : -10
                    )
                    .scaleEffect((isDrifting && !reduceMotion) ? 1.15 : 0.90)
                    .blur(radius: isLight ? 64 : 54)
            }
            .frame(height: effectiveHeight)
            .mask(
                LinearGradient(
                    stops: isLight
                        ? [
                            .init(color: .white, location: 0.0),
                            .init(color: .white, location: 0.30),
                            .init(color: .white.opacity(0.85), location: 0.55),
                            .init(color: .white.opacity(0.45), location: 0.75),
                            .init(color: .white.opacity(0.12), location: 0.90),
                            .init(color: .clear, location: 1.0)
                        ]
                        : [
                            .init(color: .white, location: 0.0),
                            .init(color: .white, location: 0.40),
                            .init(color: .white.opacity(0.90), location: 0.65),
                            .init(color: .white.opacity(0.50), location: 0.82),
                            .init(color: .white.opacity(0.15), location: 0.94),
                            .init(color: .clear, location: 1.0)
                        ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(edges: .top)
            
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .onAppear {
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: 4.8)
                    .repeatForever(autoreverses: true)
                ) {
                    isDrifting = true
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Sheet Ambient Multi-Blue Header Glow
    private func sheetAmbientHeader(effectiveHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // Multi-Stop Blend: Top -> Royal -> Deep Electric -> Sheet Base
                LinearGradient(
                    stops: [
                        .init(color: baseTopColor.opacity(opacity * meshStrength * (isLight ? 0.55 : 0.85)), location: 0.0),
                        .init(color: baseRoyalBlue.opacity(opacity * meshStrength * (isLight ? 0.70 : 0.90)), location: 0.20),
                        .init(color: (isLight ? baseRoyalBlue : baseDeepElectricBlue).opacity(opacity * meshStrength * (isLight ? 0.48 : 1.0)), location: 0.42),
                        .init(color: (isLight ? SpendySignatureTheme.skyBlue : baseDeepElectricBlue).opacity(opacity * meshStrength * (isLight ? 0.18 : 0.35)), location: 0.65),
                        .init(color: canvasColor.opacity(0.0), location: 1.0)
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                
                // Floating subtle royal specular orb
                Circle()
                    .fill(baseRoyalBlue.opacity(opacity * meshStrength * (isLight ? 0.28 : 0.45)))
                    .frame(width: 180, height: 180)
                    .offset(x: 50, y: -40)
                    .blur(radius: isLight ? 48 : 40)
            }
            .frame(height: effectiveHeight)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0.0),
                        .init(color: .white.opacity(0.80), location: 0.45),
                        .init(color: .white.opacity(0.25), location: 0.80),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(edges: .top)
            
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }
}
