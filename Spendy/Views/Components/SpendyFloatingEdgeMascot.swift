//
//  SpendyFloatingEdgeMascot.swift
//  Spendy
//
//  Authentic cartoon comic floating companion mascot with tactile edge docking,
//  interactive code sticker physics, die-cut vinyl border, particle bursts, and speed logger triggers.
//

import SwiftUI

public struct SpendyFloatingEdgeMascot: View {
    public let sticker: SpendySticker
    public var dynamicSpeech: String? = nil
    public var kicker: String? = nil
    public var actionTitle: String? = nil
    public var action: (() -> Void)? = nil
    public var onMascotTap: (() -> Void)? = nil
    public var mascotSize: CGFloat = 90
    public var showSpeech: Bool = false
    
    @Binding var isDocked: Bool
    @State private var dragOffsetX: CGFloat = 0
    @State private var tapCycle: Int = 0
    @State private var stickerBurstTrigger: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(
        sticker: SpendySticker,
        dynamicSpeech: String? = nil,
        kicker: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        onMascotTap: (() -> Void)? = nil,
        mascotSize: CGFloat = 90,
        showSpeech: Bool = false,
        isDocked: Binding<Bool>
    ) {
        self.sticker = sticker
        self.dynamicSpeech = dynamicSpeech
        self.kicker = kicker
        self.actionTitle = actionTitle
        self.action = action
        self.onMascotTap = onMascotTap
        self.mascotSize = mascotSize
        self.showSpeech = showSpeech
        self._isDocked = isDocked
    }
    
    private var activeSpeechText: String {
        if let custom = dynamicSpeech, !custom.isEmpty {
            return custom
        }
        return sticker.interactiveQuote(tapIndex: tapCycle)
    }
    
    // Offset when docked: hide ~85% of mascot off the right screen edge
    private var dockedOffset: CGFloat {
        mascotSize * 0.82
    }
    
    private var currentTotalOffset: CGFloat {
        (isDocked ? dockedOffset : 0) + dragOffsetX
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            Spacer(minLength: 0)
            
            // 1. Comic Angled Speech Bubble with Pointer Tail
            if showSpeech && !isDocked && dragOffsetX <= 10 {
                ZStack(alignment: .bottomTrailing) {
                    // Main Bubble Card
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center) {
                            if let k = kicker {
                                Text(k.uppercased())
                                    .font(.system(size: 9.5, weight: .black, design: .rounded))
                                    .foregroundStyle(SpendyColors.primaryBlue)
                                    .tracking(0.5)
                            }
                            
                            Spacer(minLength: 8)
                            
                            // Discreet dock button to slide mascot away
                            Button {
                                HapticsManager.shared.trigger(.selection)
                                withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
                                    isDocked = true
                                    dragOffsetX = 0
                                }
                            } label: {
                                Image(systemName: "chevron.right.2")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundStyle(Color.black.opacity(0.40))
                                    .padding(3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Dock mascot to screen edge")
                        }
                        
                        // Interactive Quote Button (Cycles quotes on tap)
                        Button {
                            HapticsManager.shared.trigger(.light)
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                                tapCycle += 1
                            }
                            // Also trigger subtle squish hug on sticker
                            stickerBurstTrigger += 1
                        } label: {
                            Text(activeSpeechText)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.black)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                                .lineSpacing(1.5)
                                .contentTransition(.numericText())
                        }
                        .buttonStyle(.plain)
                        
                        // Action Shortcut Button (e.g. Voice Log)
                        if let actTitle = actionTitle, let act = action {
                            Button {
                                HapticsManager.shared.trigger(.selection)
                                act()
                            } label: {
                                HStack(spacing: 4) {
                                    Text(actTitle)
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundStyle(SpendyColors.primaryBlue)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundStyle(SpendyColors.primaryBlue)
                                }
                                .padding(.top, 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black, lineWidth: 2.4)
                    )
                    
                    // Speech Bubble Tail pointing towards the Mascot
                    ComicPointerTail()
                        .fill(Color.white)
                        .frame(width: 15, height: 13)
                        .overlay(
                            ComicPointerTailOutline()
                                .stroke(Color.black, lineWidth: 2.4)
                        )
                        .offset(x: 10, y: 7)
                }
                .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 4)
                .rotationEffect(.degrees(-5))
                .frame(maxWidth: 240, alignment: .trailing)
                .offset(y: -10)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.85, anchor: .bottomTrailing)),
                    removal: .opacity.combined(with: .scale(scale: 0.85, anchor: .bottomTrailing))
                ))
            }
            
            // 2. Pure Floating Interactive Code Sticker (Right side, Edge-Dockable)
            Button {
                HapticsManager.shared.trigger(.cardSnap)
                if isDocked {
                    // Un-dock and spring out onto canvas
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.70)) {
                        isDocked = false
                        dragOffsetX = 0
                    }
                } else {
                    // Trigger live code sticker burst: elastic hug squish, holographic glint, heart particles
                    stickerBurstTrigger += 1
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                        tapCycle += 1
                    }
                    onMascotTap?()
                }
            } label: {
                ZStack(alignment: .trailing) {
                    // Peeking Indicator Pill when docked
                    if isDocked {
                        HStack(spacing: 3) {
                            Capsule()
                                .fill(SpendyColors.accentCyan)
                                .frame(width: 4.5, height: 42)
                                .shadow(color: SpendyColors.accentCyan.opacity(0.9), radius: 6)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 9.5, weight: .black))
                                .foregroundStyle(SpendyColors.accentCyan)
                                .offset(x: -1)
                        }
                        .offset(x: -dockedOffset + mascotSize - 4)
                    }
                    
                    SpendyInteractiveStickerView(
                        sticker: sticker,
                        size: mascotSize,
                        enableIdleHover: !isDocked,
                        enableTouchReactivity: false, // Managed by parent button
                        dragTiltOffset: dragOffsetX,
                        externalTrigger: stickerBurstTrigger
                    )
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDocked ? "Mascot peeking. Tap to expand." : "\(sticker.title) interactive sticker. Tap to squish and hug.")
        }
        .offset(x: currentTotalOffset)
        .padding(.trailing, 4)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    let translationX = gesture.translation.width
                    if isDocked {
                        // Swiping left pulls it out
                        if translationX < 0 {
                            dragOffsetX = max(-dockedOffset, translationX)
                        }
                    } else {
                        // Swiping right pushes it into the dock
                        if translationX > 0 {
                            dragOffsetX = translationX
                        }
                    }
                }
                .onEnded { gesture in
                    let translationX = gesture.translation.width
                    let velocityX = gesture.velocity.width
                    
                    if isDocked {
                        if translationX < -20 || velocityX < -150 {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
                                isDocked = false
                                dragOffsetX = 0
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffsetX = 0
                            }
                        }
                    } else {
                        if translationX > 25 || velocityX > 150 {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
                                isDocked = true
                                dragOffsetX = 0
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffsetX = 0
                            }
                        }
                    }
                }
        )
        .animation(.spring(response: 0.36, dampingFraction: 0.74), value: isDocked)
    }
}

// MARK: - Comic Pointer Tail Shapes
private struct ComicPointerTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 2))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX + 2, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 3, y: rect.maxY - 2),
            control: CGPoint(x: rect.midX - 2, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private struct ComicPointerTailOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 2))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX + 2, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 3, y: rect.maxY - 2),
            control: CGPoint(x: rect.midX - 2, y: rect.maxY)
        )
        return path
    }
}
