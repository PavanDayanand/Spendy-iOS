//
//  SpendyCharacterMomentCard.swift
//  Spendy
//
//  Interactive character companion banner with floating sticker graphics,
//  comic speech bubbles, tactile spring physics, and witty contextual financial quotes.
//

import SwiftUI

public struct SpendyCharacterMomentCard: View {
    public let sticker: SpendySticker
    public let speechText: String
    public var kicker: String? = nil
    public var stickerSize: CGFloat = 100
    public var onStickerTap: (() -> Void)? = nil
    
    public init(
        sticker: SpendySticker,
        speechText: String,
        kicker: String? = nil,
        stickerSize: CGFloat = 100,
        onStickerTap: (() -> Void)? = nil
    ) {
        self.sticker = sticker
        self.speechText = speechText
        self.kicker = kicker
        self.stickerSize = stickerSize
        self.onStickerTap = onStickerTap
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 1. Comic Speech Bubble (Left / Center)
            VStack(alignment: .leading, spacing: 4) {
                if let kicker = kicker {
                    Text(kicker.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                        .tracking(0.6)
                        .padding(.leading, 4)
                }
                
                SpendyComicSpeechBubble(
                    speechText,
                    tailDirection: .bottomTrailing,
                    fontSize: 14,
                    maxWidth: 220
                )
            }
            
            Spacer(minLength: 4)
            
            // 2. Interactive Character Companion Sticker (Right)
            SpendyInteractiveStickerView(
                sticker: sticker,
                size: stickerSize,
                enableIdleHover: true,
                enableTouchReactivity: true,
                onStickerTap: onStickerTap
            )
            .accessibilityLabel("Companion: \(sticker.title). Tap for character reaction.")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
