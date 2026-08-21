//
//  GlassSectionHeader.swift
//  Spendy
//
//  Shared Section Title and Action Button Component
//

import SwiftUI

struct GlassSectionHeader: View {
    var title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    action()
                }) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                            .font(.system(.subheadline, weight: .medium))
                        Image(systemName: SFIcons.chevronRight)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(SpendyColors.primaryBlue)
                }
            }
        }
    }
}
