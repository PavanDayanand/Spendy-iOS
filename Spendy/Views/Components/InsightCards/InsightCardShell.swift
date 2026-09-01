//
//  InsightCardShell.swift
//  Spendy
//
//  Unified polymorphic card container enforcing:
//  - Strictly standardized dimensions: Fixed 170pt height, flexible width in 2-column grid
//  - Corner radius: 24pt continuous Apple squircle
//  - Subtle 0.8pt border and adaptive dark/light surfaces
//  - Spring press animation & haptic feedback
//  - 44×44pt minimum touch target and accessible content shape
//

import SwiftUI

struct InsightCardShell<Content: View>: View {
    var action: (() -> Void)? = nil
    var accessibilityLabel: String? = nil
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        Button(action: {
            if let action = action {
                HapticsManager.shared.trigger(.selection)
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 188, maxHeight: 188, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(InsightCardPressStyle(isEnabled: action != nil))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel ?? "Insight card")
    }
}

// MARK: - Interactive Button Style
private struct InsightCardPressStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled ? 0.97 : 1.0)
            .opacity(configuration.isPressed && isEnabled ? 0.92 : 1.0)
            .animation(.spring(response: 0.26, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
