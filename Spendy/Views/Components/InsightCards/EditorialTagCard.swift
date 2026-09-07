//
//  EditorialTagCard.swift
//  Spendy
//
//  Archetype 5: Clean Insight & Trend Callout Card
//  Features:
//  - Flexible header: Optional modern trend icon or clean typography eyebrow
//  - Clean, uncluttered layout with generous breathing room
//  - Large primary amount and rich contextual takeaway subtitle
//

import SwiftUI

struct EditorialTagCard: View {
    let title: String
    let value: String
    let subtitle: String
    var icon: String? = "chart.line.uptrend.xyaxis"
    var color: Color = .orange
    var action: (() -> Void)? = nil
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(value), \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top Row: Optional sleek trend icon or eyebrow label
                HStack(spacing: 8) {
                    if let icon = icon {
                        SpendyIconBadge(
                            sfSymbol: icon,
                            color: color,
                            size: .small,
                            style: .rounded(),
                            monogramName: title
                        )
                    }
                    
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    Spacer(minLength: 0)
                }
                
                Spacer(minLength: 14)
                
                // 2. Bottom Area: Primary Value & Clean Insight Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .spendyNumberFont(size: 28, weight: .heavy, tracking: -0.5)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            // Variant A: With Trend Line Icon
            EditorialTagCard(
                title: "Weekend Spike",
                value: "₹9,990",
                subtitle: "3x higher than average for Sunday",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
            
            // Variant B: Pure Typography (No Top-Left Icon)
            EditorialTagCard(
                title: "Public Transport",
                value: "₹3,168",
                subtitle: "14 rides · +12% vs last month",
                icon: nil,
                color: .blue
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
