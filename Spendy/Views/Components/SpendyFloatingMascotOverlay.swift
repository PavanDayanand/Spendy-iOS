//
//  SpendyFloatingMascotOverlay.swift
//  Spendy
//
//  Non-intrusive floating mascot overlay with frosted glass blur,
//  interactive expand/collapse physics, swipe-to-hide gesture, and contextual commentary.
//

import SwiftUI

public struct SpendyFloatingMascotOverlay: View {
    public let sticker: SpendySticker
    public var speechText: String
    public var kicker: String? = nil
    public var badgeText: String? = nil
    public var badgePalette: SpendyComicPalette = .cyberGold
    public var topPadding: CGFloat = 8
    public var onMascotTap: (() -> Void)? = nil
    
    @Binding var isExpanded: Bool
    @State private var dragOffset: CGSize = .zero
    @State private var isBouncing: Bool = false
    @State private var tapCycle: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(
        sticker: SpendySticker,
        speechText: String,
        kicker: String? = nil,
        badgeText: String? = nil,
        badgePalette: SpendyComicPalette = .cyberGold,
        isExpanded: Binding<Bool>,
        topPadding: CGFloat = 8,
        onMascotTap: (() -> Void)? = nil
    ) {
        self.sticker = sticker
        self.speechText = speechText
        self.kicker = kicker
        self.badgeText = badgeText
        self.badgePalette = badgePalette
        self._isExpanded = isExpanded
        self.topPadding = topPadding
        self.onMascotTap = onMascotTap
    }
    
    private var displayedDialogue: String {
        if tapCycle > 0 {
            return sticker.interactiveQuote(tapIndex: tapCycle)
        }
        return speechText
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedBanner
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.92, anchor: .topTrailing)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        )
                    )
            } else {
                collapsedMiniPill
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.85)),
                            removal: .opacity.combined(with: .scale(scale: 0.85))
                        )
                    )
            }
        }
        .padding(.top, topPadding)
        .padding(.horizontal, 16)
        .animation(.spring(response: 0.36, dampingFraction: 0.76), value: isExpanded)
    }
    
    // MARK: - 1. Expanded Floating Banner (Frosted Glass Blur Backdrop)
    private var expandedBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            // Mascot Graphic (Interactive Tap)
            Button {
                HapticsManager.shared.trigger(.cardSnap)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
                    isBouncing = true
                    tapCycle += 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        isBouncing = false
                    }
                }
                onMascotTap?()
            } label: {
                sticker.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .scaleEffect(isBouncing ? 1.16 : 1.0)
                    .rotationEffect(.degrees(isBouncing ? (tapCycle % 2 == 0 ? 8 : -8) : 0))
                    .shadow(color: Color.black.opacity(0.35), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mascot: \(sticker.title). Tap for quotes.")
            
            // Speech Bubble & Metadata
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text((kicker ?? sticker.title).uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.primaryBlue)
                        .tracking(0.6)
                    
                    if let badge = badgeText {
                        SpendyComicBadge(
                            badge,
                            palette: badgePalette,
                            size: .custom(fontSize: 12, borderWidth: 2.2),
                            rotationAngle: -2
                        )
                    }
                    
                    Spacer()
                    
                    // Minimize / Hide Button
                    Button {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            isExpanded = false
                        }
                    } label: {
                        Image(systemName: "chevron.up.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Minimize companion")
                }
                
                Text(displayedDialogue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            // Frosted Ultra-Thin Material Blur with Border & Shadow
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SpendyColors.separator.opacity(0.85), lineWidth: 0.8)
                }
                .shadow(color: Color.black.opacity(0.28), radius: 14, x: 0, y: 6)
        }
        .offset(y: max(-60, dragOffset.height))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if gesture.translation.height < 0 {
                        dragOffset = gesture.translation
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.height < -25 || gesture.velocity.height < -150 {
                        HapticsManager.shared.trigger(.light)
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            isExpanded = false
                            dragOffset = .zero
                        }
                    } else {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }
    
    // MARK: - 2. Collapsed Floating Mini Pill (Stays unobtrusively in the corner)
    private var collapsedMiniPill: some View {
        HStack {
            Spacer()
            
            Button {
                HapticsManager.shared.trigger(.cardSnap)
                withAnimation(.spring(response: 0.36, dampingFraction: 0.74)) {
                    isExpanded = true
                }
            } label: {
                HStack(spacing: 6) {
                    sticker.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    
                    Text(sticker.title)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SpendyColors.accentCyan)
                }
                .padding(.leading, 6)
                .padding(.trailing, 10)
                .frame(height: 34)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule().stroke(SpendyColors.separator.opacity(0.85), lineWidth: 0.8)
                        }
                        .shadow(color: Color.black.opacity(0.22), radius: 8, x: 0, y: 3)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Expand \(sticker.title) companion")
        }
    }
}
