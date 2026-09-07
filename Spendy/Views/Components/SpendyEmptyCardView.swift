//
//  SpendyEmptyCardView.swift
//  Spendy
//
//  Compact, Minimal Editorial Empty State Component for Spendy.
//  Matches Apple HIG with left-aligned natural typography and a
//  prominent full-width Liquid Glass action pill button.
//

import SwiftUI

struct SpendyEmptyCardView: View {
    var icon: String? = nil
    var iconColor: Color = SpendyColors.primaryBlue
    var title: String? = nil
    var message: String
    var actionTitle: String? = nil
    var isEnclosedInCard: Bool = true
    var action: (() -> Void)? = nil
    
    // Convenience init to support title/message
    init(
        icon: String? = nil,
        iconColor: Color = SpendyColors.primaryBlue,
        title: String? = nil,
        subtitle: String? = nil,
        message: String? = nil,
        actionTitle: String? = nil,
        isEnclosedInCard: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.message = message ?? (subtitle ?? (title ?? ""))
        self.actionTitle = actionTitle
        self.isEnclosedInCard = isEnclosedInCard
        self.action = action
    }
    
    var body: some View {
        if isEnclosedInCard {
            cardBody
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                        .spendyCardLift()
                }
        } else {
            cardBody
        }
    }
    
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. Left-Aligned Editorial Text
            Text(message)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(SpendyColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 2. Full-Width Liquid Glass Pill Button
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    action()
                }) {
                    Text(actionTitle)
                        .font(.system(size: 15.5, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .nativeLiquidGlassCapsule(isInteractive: true)
                        .contentShape(Capsule())
                }
                .buttonStyle(EmptyCardPressStyle())
            }
        }
        .padding(16)
    }
}

// MARK: - Interactive Button Press Style
private struct EmptyCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
