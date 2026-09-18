//
//  SpendyMascotHeroHUD.swift
//  Spendy
//
//  Hero interactive companion mascot HUD with continuous organic levitation,
//  haptic spring reactions, comic speech bubble dialogue, and mood badge indicators.
//

import SwiftUI

public struct SpendyMascotHeroHUD: View {
    public let sticker: SpendySticker
    public var overrideSpeech: String? = nil
    public var kicker: String? = nil
    public var badgeText: String? = nil
    public var badgePalette: SpendyComicPalette = .cyberGold
    public var mascotSize: CGFloat = 80
    public var onMascotTap: (() -> Void)? = nil
    
    @State private var tapCycleIndex: Int = 0
    @State private var isBouncing: Bool = false
    @State private var isFloating: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(
        sticker: SpendySticker,
        overrideSpeech: String? = nil,
        kicker: String? = nil,
        badgeText: String? = nil,
        badgePalette: SpendyComicPalette = .cyberGold,
        mascotSize: CGFloat = 80,
        onMascotTap: (() -> Void)? = nil
    ) {
        self.sticker = sticker
        self.overrideSpeech = overrideSpeech
        self.kicker = kicker
        self.badgeText = badgeText
        self.badgePalette = badgePalette
        self.mascotSize = mascotSize
        self.onMascotTap = onMascotTap
    }
    
    private var activeDialogue: String {
        if let custom = overrideSpeech, !custom.isEmpty {
            return custom
        }
        return sticker.interactiveQuote(tapIndex: tapCycleIndex)
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // 1. Interactive Companion Mascot with Floating Physics & Tactile Bounce
            Button {
                HapticsManager.shared.trigger(.cardSnap)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.42)) {
                    isBouncing = true
                    tapCycleIndex += 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.6)) {
                        isBouncing = false
                    }
                }
                onMascotTap?()
            } label: {
                ZStack {
                    // Soft Ground Shadow
                    Ellipse()
                        .fill(Color.black.opacity(isFloating ? 0.18 : 0.32))
                        .frame(width: mascotSize * 0.65, height: 10)
                        .blur(radius: isFloating ? 6 : 3)
                        .offset(y: (mascotSize / 2) + 6 + (isFloating ? 4 : -2))
                    
                    sticker.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: mascotSize, height: mascotSize)
                        .scaleEffect(isBouncing ? 1.14 : (isFloating ? 1.03 : 0.98))
                        .rotationEffect(.degrees(reduceMotion ? 0 : (isBouncing ? (tapCycleIndex % 2 == 0 ? 10 : -10) : (isFloating ? 2.2 : -2.2))))
                        .offset(y: reduceMotion ? 0 : (isFloating ? -5 : 4))
                }
                .frame(width: mascotSize + 10, height: mascotSize + 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(sticker.title). Tap to interact.")
            
            // 2. Comic Speech Bubble & Header Kicker
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text((kicker ?? sticker.title).uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(SpendyColors.primaryBlue)
                        .tracking(0.8)
                    
                    if let badge = badgeText {
                        SpendyComicBadge(
                            badge,
                            palette: badgePalette,
                            size: .custom(fontSize: 14, borderWidth: 2.8),
                            rotationAngle: -3
                        )
                    }
                    
                    Spacer()
                }
                
                SpendyComicSpeechBubble(
                    activeDialogue,
                    tailDirection: .leading,
                    fontSize: 13.5,
                    maxWidth: 240
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: activeDialogue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(SpendyColors.separator.opacity(0.8), lineWidth: 0.8)
                }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }
}
