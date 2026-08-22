//
//  LiquidMeshBackground.swift
//  Spendy
//
//  Top 30% Semicircle Gradient & 70% Deep Black Canvas
//

import SwiftUI

struct LiquidMeshBackground: View {
    @Environment(ExpenseStore.self) private var store
    
    var body: some View {
        GeometryReader { geometry in
            let topColor = store.topGradientColor
            let height = geometry.size.height
            let width = geometry.size.width
            
            ZStack {
                // Base 100% Pitch Black Canvas
                Color.black
                    .ignoresSafeArea()
                
                if store.isGradientBackgroundEnabled {
                    // Top ~40% Semicircle Radial Arc Gradient Bloom
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: topColor.opacity(0.85), location: 0.0),
                            .init(color: topColor.opacity(0.55), location: 0.25),
                            .init(color: topColor.opacity(0.25), location: 0.50),
                            .init(color: topColor.opacity(0.08), location: 0.75),
                            .init(color: Color.black.opacity(0.0), location: 1.0)
                        ]),
                        center: UnitPoint(x: 0.5, y: -0.05),
                        startRadius: 0,
                        endRadius: max(width * 0.85, height * 0.48)
                    )
                    .blendMode(.normal)
                    .ignoresSafeArea()
                    
                    // Smooth linear transition layer to guarantee seamless blending down into 60% deep black
                    LinearGradient(
                        gradient: Gradient(colors: [
                            topColor.opacity(0.22),
                            Color.black.opacity(0.0)
                        ]),
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.44)
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .ignoresSafeArea()
    }
}
