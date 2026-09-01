//
//  SharedInsightCard.swift
//  Spendy
//
//  Standardized Reusable Rectangle Insight Card Component.
//  Matching Home Page Dashboard 2-Card Dimensions (Corner Radius: 24pt, Padding: 18pt).
//

import SwiftUI

struct SharedInsightCard<MiddleContent: View>: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var tagText: String? = nil
    var tagColor: Color? = nil
    var action: (() -> Void)? = nil
    @ViewBuilder var middleContent: () -> MiddleContent
    
    init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color,
        tagText: String? = nil,
        tagColor: Color? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder middleContent: @escaping () -> MiddleContent
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.tagText = tagText
        self.tagColor = tagColor
        self.action = action
        self.middleContent = middleContent
    }
    
    var body: some View {
        Button(action: {
            if let action = action {
                HapticsManager.shared.trigger(.selection)
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Top Header Row: Icon Badge (Top-Left, NO progress ring!) + Optional Tag
                HStack(alignment: .top, spacing: 4) {
                    SpendyIconBadge(
                        sfSymbol: icon,
                        color: color,
                        size: .medium,
                        style: .circle
                    )
                    
                    Spacer(minLength: 2)
                    
                    if let tagText = tagText {
                        let effectiveTagColor = SpendyColors.isMonoMode ? SpendyColors.textPrimary : (tagColor ?? color)
                        Text(tagText)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(effectiveTagColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(effectiveTagColor.opacity(SpendyColors.isMonoMode ? 0.12 : 0.15))
                            )
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 8)
                
                // Name / Title directly below icon
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
                
                // Optional Middle Custom Visualizer Content or Gap
                let middle = middleContent()
                if !(middle is EmptyView) {
                    middle
                        .padding(.top, 6)
                }
                
                Spacer(minLength: 12)
                
                // Bottom Area: Amount Text & Subtext underneath
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .spendyNumberFont(size: 19, weight: .bold)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 175, maxHeight: 175, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(SharedCardButtonStyle(isEnabled: action != nil))
    }
}

// Extension for default empty middle content
extension SharedInsightCard where MiddleContent == EmptyView {
    init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color,
        tagText: String? = nil,
        tagColor: Color? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            value: value,
            subtitle: subtitle,
            icon: icon,
            color: color,
            tagText: tagText,
            tagColor: tagColor,
            action: action,
            middleContent: { EmptyView() }
        )
    }
}

// MARK: - Interactive Button Style for Shared Cards
private struct SharedCardButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled ? 0.97 : 1.0)
            .opacity(configuration.isPressed && isEnabled ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        LiquidMeshBackground()
        
        VStack(spacing: 20) {
            // 2-Column Grid Preview (Standard Home Dashboard Placement)
            HStack(spacing: 14) {
                SharedInsightCard(
                    title: "Public Transport",
                    value: "₹3,168",
                    subtitle: "14 expenses this month",
                    icon: "bus.fill",
                    color: .blue,
                    tagText: "+12%"
                )
                
                SharedInsightCard(
                    title: "Groceries",
                    value: "₹852",
                    subtitle: "Under monthly budget limit",
                    icon: "cart.fill",
                    color: .green
                )
            }
            
            // Full Width Single Card Preview
            SharedInsightCard(
                title: "Smart Insight",
                value: "High Dining Expense",
                subtitle: "You spent 35% more on Restaurants this week compared to last week.",
                icon: "fork.knife",
                color: .orange,
                tagText: "Alert",
                tagColor: .orange
            )
        }
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
