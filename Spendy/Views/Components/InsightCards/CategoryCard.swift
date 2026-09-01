//
//  CategoryCard.swift
//  Spendy
//
//  Dedicated Category Widget Card (Unified Curated Design)
//  Features:
//  - Standard 188pt height with InsightCardShell (24pt squircle radius)
//  - Top: 42×42pt solid vibrant circular icon badge with soft glow
//  - Just below icon: Category Name (Semibold)
//  - Open middle spacing
//  - Bottom: Formatted spend amount + 2-line wrapped subtitle
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
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(tagText != nil ? "\(tagText!), " : "")\(value), \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top: Circular Icon Badge with Subtle Glow + Optional Tag Pill
                HStack(alignment: .top) {
                    Circle()
                        .fill(color)
                        .frame(width: 42, height: 42)
                        .overlay {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: color.opacity(0.35), radius: 5, x: 0, y: 2.5)
                    
                    Spacer(minLength: 4)
                    
                    if let tag = tagText, !tag.isEmpty {
                        Text(tag)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(tagColor ?? color)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill((tagColor ?? color).opacity(0.15))
                            )
                            .lineLimit(1)
                    }
                }
                
                Spacer().frame(height: 10)
                
                // 2. Just below icon: Category Name
                Text(title)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                // 3. Middle: Open Space
                Spacer(minLength: 12)
                
                // 4. Bottom: Spend Amount + 2-Line Subtitle
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
            CategoryCard(
                title: "Subscriptions",
                value: "₹17,782",
                subtitle: "4 active · Monthly committed",
                icon: "repeat.circle.fill",
                color: .purple
            )
            
            CategoryCard(
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

