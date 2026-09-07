//
//  InsightCardShell.swift
//  Spendy
//
//  Unified polymorphic card container enforcing:
//  - Clean solid matte card finish matching modern minimalist aesthetic
//  - Strictly standardized compact dimensions (Height: 170pt, flexible width in grid or 170pt in carousel)
//  - Corner radius: 20pt continuous Apple squircle with 0.8pt hairline stroke
//  - Spring press animation & haptic feedback on tap
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
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 170, maxHeight: 170, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
                    .spendyCardLift()
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
            .scaleEffect(configuration.isPressed && isEnabled ? 0.975 : 1.0)
            .opacity(configuration.isPressed && isEnabled ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
