//
//  MinimalCategoryCard.swift
//  Spendy
//
//  Card Design: Spending by Category Card (Large Icon Badge, Title Underneath, Middle Space, Bottom Data)
//  Features:
//  - Top: 42pt circular solid icon badge with subtle glow
//  - Just below icon: Category Name (Medium/Semibold)
//  - Middle: Open breathing space
//  - Bottom: Amount & 2-line subtitle moved one step up to prevent text truncation
//

import SwiftUI

struct MinimalCategoryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(value), \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top: Rounded Icon Badge with Subtle Glow
                SpendyIconBadge(
                    sfSymbol: icon,
                    color: color,
                    size: .medium,
                    style: .circle,
                    monogramName: title
                )
                
                Spacer().frame(height: 10)
                
                // 2. Just below icon: Category Name
                Text(title)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                // 3. Middle: Open Space
                Spacer(minLength: 12)
                
                // 4. Bottom: Spending Amount + 2-Line Subtitle (Moved one step up)
                VStack(alignment: .leading, spacing: 2.5) {
                    if !value.isEmpty {
                        Text(value)
                            .spendyNumberFont(size: 20, weight: .bold, tracking: -0.4)
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.80)
                }
                .padding(.bottom, 2)
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            MinimalCategoryCard(
                title: "Subscriptions",
                value: "₹17,782",
                subtitle: "4 active · Monthly committed",
                icon: "repeat.circle.fill",
                color: .purple
            )
            
            MinimalCategoryCard(
                title: "Food delivery",
                value: "$21,144",
                subtitle: "3 expenses this month",
                icon: "pizza.fill",
                color: .orange
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
