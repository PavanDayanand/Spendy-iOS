//
//  DotMatrixCard.swift
//  Spendy
//
//  Archetype 1: Habit / Streak Dot Matrix Card (Inspired by Fitness & Habit Trackers)
//  Features:
//  - Optional Category/Insight icon badge + section title
//  - Hero streak metric with 2-line stacked description
//  - 3-row × 10-column dot matrix representing 30-day activity completion
//

import SwiftUI

struct DotMatrixCard: View {
    let title: String
    let streakCount: Int
    let streakUnit: String // e.g. "days in a row" or "days under budget"
    var icon: String? = "flame.fill"
    var color: Color = .orange
    var totalDays: Int = 30
    var activeDays: Int = 24
    var action: (() -> Void)? = nil
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(streakCount) \(streakUnit)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top Row: Optional Icon badge + Section Title
                HStack(spacing: 8) {
                    if let icon = icon {
                        SpendyIconBadge(
                            sfSymbol: icon,
                            color: color,
                            size: .small,
                            style: .rounded()
                        )
                    }
                    
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    Spacer(minLength: 0)
                }
                
                Spacer(minLength: 8)
                
                // 2. Hero Streak Display (Large Number + Stacked Subtitle)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    let effectiveColor = SpendyColors.isMonoMode ? SpendyColors.textPrimary : color
                    Text("\(streakCount)")
                        .spendyNumberFont(size: 34, weight: .heavy, tracking: -0.5)
                        .foregroundStyle(effectiveColor)
                        .lineLimit(1)
                    
                    Text(streakUnit)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 12)
                
                // 3. Dot Matrix Grid (3 rows x 10 dots = 30 days)
                let effectiveColor = SpendyColors.isMonoMode ? SpendyColors.textPrimary : color
                VStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: 5) {
                            ForEach(0..<10, id: \.self) { col in
                                let index = row * 10 + col
                                Circle()
                                    .fill(index < activeDays ? effectiveColor : effectiveColor.opacity(0.18))
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            DotMatrixCard(
                title: "Budget Streak",
                streakCount: 24,
                streakUnit: "days in a row",
                icon: "flame.fill",
                color: .orange,
                totalDays: 30,
                activeDays: 24
            )
            
            DotMatrixCard(
                title: "Groceries Goal",
                streakCount: 12,
                streakUnit: "days under limit",
                icon: "cart.fill",
                color: .green,
                totalDays: 30,
                activeDays: 12
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
