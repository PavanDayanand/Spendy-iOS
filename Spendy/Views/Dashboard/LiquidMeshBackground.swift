//
//  LiquidMeshBackground.swift
//  Spendy
//
//  Adaptive edge-to-edge ambient header gradient background with fluid liquid mesh animation.
//  Uses the user's custom accent/profile color configured in Settings.
//

import SwiftUI

public struct LiquidMeshBackground: View {
    @Environment(ExpenseStore.self) private var store
    
    public enum Style {
        case screen
        case sheet
    }
    
    public var color: Color? = nil
    public var style: Style = .screen
    public var height: CGFloat? = nil
    public var opacity: Double = 0.38
    
    @State private var isDrifting: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(
        color: Color? = nil,
        style: Style = .screen,
        height: CGFloat? = nil,
        opacity: Double = 0.38
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
    
    private var ambientColor: Color {
        if let color = color { return color }
        if let hex = store.profileColorHex, !hex.isEmpty {
            return Color(hex: hex)
        }
        if !store.topGradientColorHex.isEmpty {
            return Color(hex: store.topGradientColorHex)
        }
        return Color(hex: "#007AFF")
    }
    
    public var body: some View {
        ZStack {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            if style == .sheet {
                SpendyAmbientHeaderBackground(
                    color: ambientColor,
                    height: effectiveHeight,
                    opacity: opacity
                )
            } else {
                // Main App Screen Fluid Animated Background
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        // 1. Moving ambient gradient wash across top safe area
                        LinearGradient(
                            stops: [
                                .init(color: ambientColor.opacity(opacity * 1.15), location: 0.0),
                                .init(color: ambientColor.opacity(opacity * 0.85), location: 0.22),
                                .init(color: ambientColor.opacity(opacity * 0.50), location: 0.50),
                                .init(color: ambientColor.opacity(opacity * 0.20), location: 0.76),
                                .init(color: ambientColor.opacity(opacity * 0.05), location: 0.92),
                                .init(color: Color.clear, location: 1.0)
                            ],
                            startPoint: (isDrifting && !reduceMotion) ? .topTrailing : .topLeading,
                            endPoint: (isDrifting && !reduceMotion) ? .bottomLeading : .bottomTrailing
                        )
                        
                        // 2. Animated floating ambient glow orb
                        Circle()
                            .fill(ambientColor.opacity(opacity * 0.70))
                            .frame(width: 340, height: 340)
                            .offset(
                                x: (isDrifting && !reduceMotion) ? 50 : -50,
                                y: (isDrifting && !reduceMotion) ? -30 : -80
                            )
                            .scaleEffect((isDrifting && !reduceMotion) ? 1.15 : 0.90)
                            .blur(radius: 60)
                    }
                    .frame(height: effectiveHeight)
                    .clipped()
                    .ignoresSafeArea(edges: .top)
                    
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
                .onAppear {
                    if !reduceMotion {
                        withAnimation(
                            .easeInOut(duration: 4.5)
                            .repeatForever(autoreverses: true)
                        ) {
                            isDrifting = true
                        }
                    }
                }
                .animation(AppMotion.gentleSpring, value: ambientColor)
            }
        }
        .ignoresSafeArea()
    }
}
