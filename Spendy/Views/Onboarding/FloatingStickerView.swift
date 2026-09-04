//
//  FloatingStickerView.swift
//  Spendy
//
//  Floating sticker showcase with continuous physical levitation,
//  organic breathing scale, interactive tactile bounce, and dynamic shadow.
//

import SwiftUI

public struct FloatingStickerView: View {
    public let sticker: SpendySticker
    public var size: CGFloat = 220
    public var interactiveTap: Bool = true
    
    @State private var isFloating: Bool = false
    @State private var isPressed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(sticker: SpendySticker, size: CGFloat = 220, interactiveTap: Bool = true) {
        self.sticker = sticker
        self.size = size
        self.interactiveTap = interactiveTap
    }
    
    public var body: some View {
        ZStack {
            // Ground shadow that responds dynamically to floating elevation
            Ellipse()
                .fill(Color.black.opacity(isFloating ? 0.22 : 0.38))
                .frame(width: size * 0.65, height: 16)
                .blur(radius: isFloating ? 12 : 6)
                .offset(y: (size / 2) + 20 + (isFloating ? 8 : -4))
            
            // Levitating Sticker
            sticker.image
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .scaleEffect(isPressed ? 0.92 : (isFloating ? 1.03 : 0.98))
                .rotationEffect(.degrees(reduceMotion ? 0 : (isFloating ? 1.8 : -1.8)))
                .offset(y: reduceMotion ? 0 : (isFloating ? -10 : 8))
                .shadow(
                    color: Color.black.opacity(isFloating ? 0.28 : 0.40),
                    radius: isFloating ? 20 : 12,
                    x: 0,
                    y: isFloating ? 16 : 8
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    guard interactiveTap else { return }
                    HapticsManager.shared.trigger(.cardSnap)
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.5, blendDuration: 0)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                            isPressed = false
                        }
                    }
                }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 2.6)
                .repeatForever(autoreverses: true)
            ) {
                isFloating = true
            }
        }
    }
}
