//
//  LiquidMeshBackground.swift
//  Spendy
//
//  Smooth, Seamless Organic Top Blue Bloom Fading Naturally into Pitch Black Base
//

import SwiftUI

struct LiquidMeshBackground: View {
    @Environment(ExpenseStore.self) private var store
    
    var body: some View {
        let topColor = store.topGradientColor
        
        ZStack {
            // 1. Base Pitch Black Canvas
            Color.black
                .ignoresSafeArea()
                
                if store.isGradientBackgroundEnabled {
                    // 2. Smooth Linear Flow Fading Gently into Black (No Hard Cuts)
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: topColor, location: 0.0),
                            .init(color: topColor.opacity(0.85), location: 0.08),
                            .init(color: Color(hex: "#0A2878").opacity(0.75), location: 0.18),
                            .init(color: Color(hex: "#041548").opacity(0.45), location: 0.28),
                            .init(color: Color(hex: "#020924").opacity(0.18), location: 0.38),
                            .init(color: Color.black, location: 0.48)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    // 3. Top Ambient Full-Width Luminous Flow
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: topColor.opacity(0.45), location: 0.0),
                            .init(color: topColor.opacity(0.20), location: 0.15),
                            .init(color: topColor.opacity(0.05), location: 0.30),
                            .init(color: Color.black.opacity(0.0), location: 0.48)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}
