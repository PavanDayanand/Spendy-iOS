//
//  SpendyRowCard.swift
//  Spendy
//
//  Standardized Shared Row Card Component for Subscriptions, Transactions & Items
//

import SwiftUI

struct SpendyRowCard<LeadingIcon: View, ContentTitle: View, TrailingContent: View>: View {
    var accentColor: Color? = nil
    var cornerRadius: CGFloat = 16
    var paddingHorizontal: CGFloat = 14
    var paddingVertical: CGFloat = 12
    var showChevron: Bool = false
    var onTap: (() -> Void)? = nil
    
    @ViewBuilder var leadingIcon: () -> LeadingIcon
    @ViewBuilder var titleContent: () -> ContentTitle
    @ViewBuilder var trailingContent: () -> TrailingContent
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    onTap()
                }) {
                    cardLayout
                }
                .buttonStyle(.plain)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
            } else {
                cardLayout
            }
        }
    }
    
    private var effectiveAccent: Color? {
        SpendyColors.isMonoMode ? nil : accentColor
    }
    
    private var cardLayout: some View {
        HStack(spacing: 12) {
            leadingIcon()
            
            titleContent()
            
            Spacer(minLength: 8)
            
            trailingContent()
            
            if showChevron {
                Image(systemName: SFIcons.chevronRight)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary.opacity(0.5))
            }
        }
        .padding(.horizontal, paddingHorizontal)
        .padding(.vertical, paddingVertical)
        .background {
            let fillStyle: AnyShapeStyle = {
                if let accent = effectiveAccent {
                    return AnyShapeStyle(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.12),
                                accent.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                } else {
                    return AnyShapeStyle(SpendyColors.cardBackground)
                }
            }()
            let strokeColor = effectiveAccent?.opacity(0.18) ?? SpendyColors.separator

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fillStyle)
                .background(SpendyColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(strokeColor, lineWidth: 0.8)
                }
        }
    }
}
