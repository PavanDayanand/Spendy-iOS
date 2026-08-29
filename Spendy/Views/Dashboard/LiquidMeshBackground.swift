//
//  LiquidMeshBackground.swift
//  Spendy
//
//  Asymmetric Upper-Right Ambient Liquid Light Flow:
//  - Deep, glowing ambient light source situated in the upper-right corner
//  - Asymmetric diagonal falloff spreading softly across the top and cascading into pitch black
//  - Slow breathing & organic floating animation
//  - Dynamically updates when the user switches colors in settings
//

import SwiftUI

struct LiquidMeshBackground: View {
    @Environment(ExpenseStore.self) private var store
    @State private var animateFlow: Bool = false
    
    enum Style {
        case screen
        case sheet
    }
    
    var style: Style = .screen
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let maxDimension = max(size.width, size.height)
            let hue = store.topGradientHue
            let brightness = min(max(store.topGradientBrightness, 0.20), 0.95)
            let liftedBrightness = max(brightness, 0.76)
            let coreBrightness = min(liftedBrightness * 0.88, 0.72)
            let midBrightness = min(liftedBrightness * 0.62, 0.46)
            let edgeBrightness = min(liftedBrightness * 0.34, 0.26)
            
            let glowCore = Color(hue: hue, saturation: 0.92, brightness: coreBrightness)
            let glowMid = Color(hue: hue, saturation: 0.96, brightness: midBrightness)
            let glowEdge = Color(hue: hue, saturation: 0.99, brightness: edgeBrightness)
            let shadowTone = Color(hue: hue, saturation: 1.0, brightness: 0.04)
            let primaryRadius = maxDimension * (style == .sheet ? 1.30 : 1.02)
            let secondaryRadius = maxDimension * (style == .sheet ? 0.98 : 0.78)
            let sideRadius = maxDimension * (style == .sheet ? 0.84 : 0.64)
            
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if store.isGradientBackgroundEnabled {
                    LinearGradient(
                        stops: [
                            .init(color: glowCore.opacity(style == .sheet ? 0.26 : 0.22), location: 0.00),
                            .init(color: glowMid.opacity(style == .sheet ? 0.36 : 0.32), location: 0.14),
                            .init(color: glowEdge.opacity(style == .sheet ? 0.28 : 0.24), location: 0.30),
                            .init(color: shadowTone.opacity(0.24), location: 0.50),
                            .init(color: Color.black.opacity(0.94), location: 0.76),
                            .init(color: Color.black, location: 1.00)
                        ],
                        startPoint: .topTrailing,
                        endPoint: UnitPoint(x: 0.12, y: 0.95)
                    )
                    .blendMode(.screen)
                    .ignoresSafeArea()
                    
                    RadialGradient(
                        stops: [
                            .init(color: glowCore.opacity(style == .sheet ? 1.00 : 0.98), location: 0.00),
                            .init(color: glowMid.opacity(style == .sheet ? 0.90 : 0.86), location: 0.22),
                            .init(color: glowEdge.opacity(style == .sheet ? 0.58 : 0.50), location: 0.56),
                            .init(color: shadowTone.opacity(0.14), location: 0.76),
                            .init(color: .clear, location: 1.00)
                        ],
                        center: style == .sheet
                            ? UnitPoint(x: animateFlow ? 0.90 : 0.85, y: animateFlow ? 0.04 : 0.08)
                            : UnitPoint(x: animateFlow ? 0.88 : 0.83, y: animateFlow ? 0.05 : 0.10),
                        startRadius: 10,
                        endRadius: primaryRadius
                    )
                    .scaleEffect(x: 1.28, y: 0.92, anchor: .topTrailing)
                    .blur(radius: style == .sheet ? 84 : 70)
                    .blendMode(.screen)
                    .ignoresSafeArea()
                    
                    RadialGradient(
                        stops: [
                            .init(color: glowMid.opacity(style == .sheet ? 0.68 : 0.58), location: 0.00),
                            .init(color: glowEdge.opacity(style == .sheet ? 0.38 : 0.30), location: 0.50),
                            .init(color: .clear, location: 1.00)
                        ],
                        center: style == .sheet
                            ? UnitPoint(x: animateFlow ? 0.52 : 0.62, y: animateFlow ? -0.04 : 0.02)
                            : UnitPoint(x: animateFlow ? 0.46 : 0.58, y: animateFlow ? -0.02 : 0.04),
                        startRadius: 18,
                        endRadius: secondaryRadius
                    )
                    .scaleEffect(x: 1.42, y: 0.60, anchor: .top)
                    .blur(radius: style == .sheet ? 98 : 82)
                    .blendMode(.plusLighter)
                    .ignoresSafeArea()
                    
                    RadialGradient(
                        stops: [
                            .init(color: glowMid.opacity(style == .sheet ? 0.42 : 0.36), location: 0.00),
                            .init(color: shadowTone.opacity(0.18), location: 0.56),
                            .init(color: .clear, location: 1.00)
                        ],
                        center: style == .sheet
                            ? UnitPoint(x: animateFlow ? 1.02 : 0.96, y: animateFlow ? 0.34 : 0.24)
                            : UnitPoint(x: animateFlow ? 0.98 : 0.93, y: animateFlow ? 0.32 : 0.22),
                        startRadius: 16,
                        endRadius: sideRadius
                    )
                    .scaleEffect(x: 0.82, y: 1.34, anchor: .trailing)
                    .blur(radius: style == .sheet ? 74 : 58)
                    .blendMode(.screen)
                    .ignoresSafeArea()
                    
                    LinearGradient(
                        stops: [
                            .init(color: Color.black.opacity(0.00), location: 0.00),
                            .init(color: Color.black.opacity(0.18), location: 0.32),
                            .init(color: Color.black.opacity(0.48), location: 0.60),
                            .init(color: Color.black.opacity(0.82), location: 0.82),
                            .init(color: Color.black.opacity(0.96), location: 1.00)
                        ],
                        startPoint: UnitPoint(x: 0.50, y: 0.05),
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
            .animation(.easeInOut(duration: 0.6), value: hue)
            .animation(.easeInOut(duration: 0.6), value: brightness)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                    animateFlow = true
                }
            }
        }
    }
}
