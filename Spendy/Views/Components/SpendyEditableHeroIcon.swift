//
//  SpendyEditableHeroIcon.swift
//  Spendy
//
//  Shared add/edit hero: squircle or circle icon with a dark pencil
//  badge sitting on the top-right corner like a half-moon.
//

import SwiftUI

struct SpendyEditableHeroIcon<Icon: View>: View {
    var accessibilityLabel: String = "Edit icon"
    var action: () -> Void
    @ViewBuilder var icon: () -> Icon
    
    private let badgeSize: CGFloat = 32
    
    var body: some View {
        Button {
            HapticsManager.shared.trigger(.light)
            action()
        } label: {
            icon()
                .overlay(alignment: .topTrailing) {
                    pencilBadge
                        .offset(x: 10, y: -10)
                }
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
        .padding(.trailing, 10)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var pencilBadge: some View {
        Image(systemName: SFIcons.edit)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: badgeSize, height: badgeSize)
            .background {
                Circle()
                    .fill(Color.black)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.28), radius: 6, y: 2)
            }
            .accessibilityHidden(true)
    }
}

extension SpendyEditableHeroIcon where Icon == SpendyIconBadge {
    init(
        sfSymbol: String,
        color: Color,
        style: SpendyIconBadge.Style = .rounded(),
        monogramName: String = "",
        accessibilityLabel: String = "Edit icon",
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
        self.icon = {
            SpendyIconBadge(
                sfSymbol: sfSymbol,
                color: color,
                size: .hero,
                style: style,
                monogramName: monogramName
            )
        }
    }
}
