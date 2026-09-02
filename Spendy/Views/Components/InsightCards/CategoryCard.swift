//
//  CategoryCard.swift
//  Spendy
//
//  Compact Solid Minimal Insight Card:
//  - Top: Colored Category Icon Badge (SpendyIconBadge)
//  - Title: Bold Category Name
//  - Value: Formatted Spend Amount (Monospaced Bold)
//  - Subtitle: Full multi-line insight description without truncation
//

import SwiftUI

struct CategoryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var tagText: String? = nil
    var tagColor: Color? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(value), \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top Row: Circular Category Icon Badge
                SpendyIconBadge(
                    sfSymbol: icon,
                    color: color,
                    size: .small,
                    style: .circle
                )
                
                Spacer().frame(height: 10)
                
                // 2. Title & Value
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15.5, weight: .bold, design: .default))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    if !value.isEmpty {
                        Text(value)
                            .spendyNumberFont(size: 18, weight: .bold, tracking: -0.4)
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 6)
                
                // 3. Full Insight Message (Multi-line, no cutoff)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            CategoryCard(
                title: "Restaurants",
                value: "₹240",
                subtitle: "Saved ₹2,342 vs last month • Great progress on dining out!",
                icon: "fork.knife",
                color: Color(hex: "#FF9F0A")
            )
            
            CategoryCard(
                title: "Food Delivery",
                value: "₹340",
                subtitle: "Saved ₹789 vs last month • 2 orders logged",
                icon: "bag.badge.plus",
                color: Color(hex: "#FF6482")
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
