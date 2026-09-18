//
//  SpendyAmbientHeaderBackground.swift
//  Spendy
//
//  Seamless Edge-to-Edge Ambient Linear Header Glow for Spendy iOS.
//  Replaces legacy spherical radial semi-circles with a smooth, full-width multi-stop
//  vertical ease-out gradient that fills the top safe area and gently fades into pure dark base.
//

import SwiftUI

public struct SpendyAmbientHeaderBackground: View {
    @Environment(\.isMonoIconMode) private var isMonoMode
    
    public var color: Color
    public var height: CGFloat = 360
    public var opacity: Double = 0.32
    public var blurRadius: CGFloat = 0
    
    public init(
        color: Color,
        height: CGFloat = 360,
        opacity: Double = 0.32,
        blurRadius: CGFloat = 0
    ) {
        self.color = color
        self.height = height
        self.opacity = opacity
        self.blurRadius = blurRadius
    }
    
    private var isEffectivelyMono: Bool {
        isMonoMode || SpendyColors.isMonoMode
    }
    
    public var body: some View {
        if !isEffectivelyMono {
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
}

// MARK: - Previews
struct SpendyAmbientHeaderBackground_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()
            SpendyAmbientHeaderBackground(color: .indigo, height: 380, opacity: 0.35)
        }
    }
}
