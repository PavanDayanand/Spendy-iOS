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
    
    @Environment(\.scenePhase) private var scenePhase
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
            let calculatedHeight = height ?? (style == .sheet ? totalScreenHeight * 0.55 : totalScreenHeight * 0.95)
            
            ZStack {
                canvasColor
                    .ignoresSafeArea()
                
                if style == .sheet {
                    // Sheet Ambient Multi-Blue Header Glow
                    sheetAmbientHeader(effectiveHeight: calculatedHeight)
                } else if store.isGradientBackgroundEnabled {
                    // Broad screen mesh with a gradual fade into the canvas.
                    screenFluidMesh(effectiveHeight: calculatedHeight)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: store.isGradientBackgroundEnabled)
            .animation(.easeInOut(duration: 0.28), value: colorScheme)
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Screen Mesh
    private func screenFluidMesh(effectiveHeight: CGFloat) -> some View {
        let pausesMotion = reduceMotion || scenePhase != .active || ProcessInfo.processInfo.isLowPowerModeEnabled
        return VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: pausesMotion)) { context in
                let time = pausesMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                MeshGradient(
                    width: 4,
                    height: 4,
                    points: meshPoints(at: time),
                    colors: meshColors,
                    background: canvasColor,
                    smoothsColors: true,
                    colorSpace: .perceptual
                )
                .opacity(isLight ? opacity * meshStrength : min(1, opacity * 1.65))
            }
            .frame(height: effectiveHeight)
            Spacer(minLength: 0)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    private var meshColors: [Color] {
        let quiet = isLight ? Color(hex: "#D7E4FF") : Color(hex: "#06102D")
        let middle = isLight ? SpendySignatureTheme.skyBlue : baseDeepElectricBlue
        let edgeBlue = isLight ? Color(hex: "#BDD5FF") : Color(hex: "#122773")
        return [
            canvasColor, quiet, quiet, canvasColor,
            edgeBlue, baseRoyalBlue, middle, edgeBlue,
            quiet, middle, middle, quiet,
            canvasColor, canvasColor, canvasColor, canvasColor
        ]
    }

    private func meshPoints(at time: TimeInterval) -> [SIMD2<Float>] {
        // Keep the perimeter fixed; interior points drift on separate, slow cycles.
        func wave(_ seconds: Double, _ phase: Double = 0) -> Float {
            Float(sin(time * 2 * .pi / seconds + phase))
        }
        return [
            [0, 0], [0.33, 0], [0.67, 0], [1, 0],
            [0, 0.33],
            [0.28 + 0.045 * wave(23), 0.33 + 0.035 * wave(29, 1)],
            [0.72 + 0.040 * wave(31, 2), 0.33 + 0.050 * wave(37)],
            [1, 0.33],
            [0, 0.67],
            [0.28 + 0.055 * wave(41, 1), 0.70 + 0.040 * wave(31, 3)],
            [0.72 + 0.035 * wave(29, 4), 0.70 + 0.055 * wave(43, 2)],
            [1, 0.67],
            [0, 1], [0.33, 1], [0.67, 1], [1, 1]
        ]
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
