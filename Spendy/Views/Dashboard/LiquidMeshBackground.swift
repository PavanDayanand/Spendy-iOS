//
//  LiquidMeshBackground.swift
//  Spendy
//
//  Single-Color Liquid Ambient Flow:
//  - Inverted U-shape dark tint / black arch rising from bottom and wrapping sides
//  - Dark tint spread smoothly into upper region of the solid color
//  - 100% seamless, buttery ease blend
//

import SwiftUI

struct LiquidMeshBackground: View {
    @Environment(ExpenseStore.self) private var store
    
    var body: some View {
        let hue = store.topGradientHue
        let brightness = min(max(store.topGradientBrightness, 0.65), 0.95)
        
        // Color tones derived strictly from the chosen hue (deepened darkness in lower half)
        let topVibrant = Color(hue: hue, saturation: 0.90, brightness: brightness)
        let topLiquidDark = Color(hue: hue, saturation: 0.95, brightness: brightness * 0.62)
        let midDark = Color(hue: hue, saturation: 0.98, brightness: brightness * 0.25)
        let deepMidnight = Color(hue: hue, saturation: 1.00, brightness: brightness * 0.07)
        let nearBlack = Color(hue: hue, saturation: 1.00, brightness: brightness * 0.01)
        
        ZStack {
            // 1. Solid Pitch Black Base Canvas
            Color.black
                .ignoresSafeArea()
            
            if store.isGradientBackgroundEnabled {
                // 2. Linear Flow with Deep Darkness Covering the Lower Half
                LinearGradient(
                    stops: [
                        .init(color: topVibrant, location: 0.0),
                        .init(color: topVibrant.opacity(0.90), location: 0.06),
                        .init(color: topLiquidDark, location: 0.16),
                        .init(color: midDark, location: 0.28),
                        .init(color: deepMidnight, location: 0.42),
                        .init(color: nearBlack, location: 0.56),
                        .init(color: Color.black, location: 0.68),
                        .init(color: Color.black, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // 3. Inverted U-Shape Dark Tint Arch (Deep Darkness on Edges & Lower Half)
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.clear, location: 0.0),
                        .init(color: topLiquidDark.opacity(0.30), location: 0.35),
                        .init(color: deepMidnight.opacity(0.85), location: 0.60),
                        .init(color: Color.black, location: 0.80),
                        .init(color: Color.black, location: 1.0)
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.05),
                    startRadius: 70,
                    endRadius: 500
                )
                .ignoresSafeArea()
                
                // 4. Smooth Bottom-Up Pitch Black Arch
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.black, location: 0.0),
                        .init(color: Color.black.opacity(0.95), location: 0.35),
                        .init(color: deepMidnight.opacity(0.70), location: 0.55),
                        .init(color: midDark.opacity(0.25), location: 0.75),
                        .init(color: Color.clear, location: 1.0)
                    ]),
                    center: UnitPoint(x: 0.5, y: 1.05),
                    startRadius: 50,
                    endRadius: 650
                )
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}
