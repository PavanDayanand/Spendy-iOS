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
        SpendyPlainEmptyState(
            title: title ?? "Nothing here yet",
            message: message,
            icon: icon ?? "tray",
            actionTitle: actionTitle,
            action: action
        )
        .padding(16)
    }
}
