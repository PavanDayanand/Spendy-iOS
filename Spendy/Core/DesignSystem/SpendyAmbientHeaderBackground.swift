//
//  SpendyAmbientHeaderBackground.swift
//  Spendy
//
//  Seamless Edge-to-Edge Ambient Linear Header Glow for Spendy iOS.
//  Replaces legacy spherical radial semi-circles with a smooth, full-width multi-stop
//  vertical ease-out gradient that fills the top safe area and gently fades into pure dark base.
//

import SwiftUI

struct SpendyAmbientHeaderBackground: View {
    var color: Color
    var height: CGFloat = 360
    var opacity: Double = 0.32
    var blurRadius: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    .init(color: color.opacity(opacity), location: 0.0),
                    .init(color: color.opacity(opacity * 0.82), location: 0.20),
                    .init(color: color.opacity(opacity * 0.52), location: 0.48),
                    .init(color: color.opacity(opacity * 0.25), location: 0.74),
                    .init(color: color.opacity(opacity * 0.08), location: 0.90),
                    .init(color: Color.clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height)
            .blur(radius: blurRadius)
            .ignoresSafeArea(edges: .top)
            
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        SpendyAmbientHeaderBackground(color: .indigo, height: 380, opacity: 0.35)
    }
}
