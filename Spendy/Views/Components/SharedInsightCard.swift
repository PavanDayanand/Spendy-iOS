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
                // Top Header Row: Title & Optional Tag
                HStack(alignment: .center, spacing: 4) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                        .layoutPriority(1)
                    
                    Spacer(minLength: 2)
                    
                    if let tagText = tagText {
                        Text(tagText)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(tagColor ?? color)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill((tagColor ?? color).opacity(0.15))
                            )
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 4)
                
                // Main Value Row
                Text(value)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                
                // Optional Middle Custom Visualizer Content
                let middle = middleContent()
                if !(middle is EmptyView) {
                    middle
                        .padding(.top, 6)
                }
                
                Spacer(minLength: 8)
                
                // Bottom Footer Row: Insight Icon Circle Avatar (Bottom-Left) + Engine Description Text (Bottom-Right)
                HStack(alignment: .center, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 34, height: 34)
                            .shadow(color: color.opacity(0.40), radius: 6, x: 0, y: 2)
                        
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.80)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .topLeading)
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
