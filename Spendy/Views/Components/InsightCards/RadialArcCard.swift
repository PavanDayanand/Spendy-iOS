//
//  RadialArcCard.swift
//  Spendy
//
//  Archetype 3: Progress & Budget Health Card
//  Features:
//  - Clean header with optional category icon & title
//  - Large primary spend figure
//  - Sleek horizontal progress bar indicator
//  - Bottom budget remaining & health status
//

import SwiftUI

struct RadialArcCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double // 0.0 to 1.0 (e.g. 0.84 for 84%)
    var icon: String? = "chart.pie.fill"
    var color: Color = .purple
    var action: (() -> Void)? = nil
    
    private var progressPercentageText: String {
        "\(Int(min(1.0, max(0.0, progress)) * 100))%"
    }
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(value), \(progressPercentageText) spent, \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top Row: Optional Icon Badge + Title (Clean top-right)
                HStack(spacing: 8) {
                    if let icon = icon {
                        SpendyIconBadge(
                            sfSymbol: icon,
                            color: color,
                            size: .small,
                            style: .circle,
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
                
                Spacer(minLength: 12)
                
                // 2. Middle: Large Spend Figure
                VStack(alignment: .leading, spacing: 3) {
                    Text(value)
                        .spendyNumberFont(size: 28, weight: .heavy, tracking: -0.5)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Text("\(progressPercentageText) of budget limit")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SpendyColors.isMonoMode ? SpendyColors.textSecondary : color)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 12)
                
                // 3. Bottom: Sleek Progress Bar Track & Remaining Text
                let activeColor = SpendyColors.isMonoMode ? SpendyColors.textPrimary : color
                let trackColor = SpendyColors.isMonoMode ? SpendyColors.cardBackgroundSecondary : color.opacity(0.18)
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(trackColor)
                                .frame(height: 5)
                            
                            Capsule()
                                .fill(activeColor)
                                .frame(width: max(5, geo.size.width * CGFloat(min(1.0, max(0.0, progress)))), height: 5)
                        }
                    }
                    .frame(height: 5)
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            RadialArcCard(
                title: "Dining Out",
                value: "₹8,450",
                subtitle: "₹1,550 left · 8 days remaining",
                progress: 0.84,
                icon: "fork.knife",
                color: .purple
            )
            
            RadialArcCard(
                title: "Groceries",
                value: "₹4,200",
                subtitle: "₹5,800 left · Safe pace",
                progress: 0.42,
                icon: "cart.fill",
                color: .green
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
