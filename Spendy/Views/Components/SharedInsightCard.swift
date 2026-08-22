//
//  SharedInsightCard.swift
//  Spendy
//
//  Standardized Reusable Rectangle Insight Card Component.
//  Matching Home Page Dashboard 2-Card Dimensions (Corner Radius: 24pt, Padding: 18pt).
//

import SwiftUI

struct SharedInsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var tagText: String? = nil
    var tagColor: Color? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if let action = action {
                HapticsManager.shared.trigger(.selection)
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Top Header Row: Category Icon Avatar (Top-Left) + Optional Tag (Top-Right)
                HStack(alignment: .top) {
                    // Category Icon Circle Avatar with Glowing Aura Shadow
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 52, height: 52)
                            .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 4)
                        
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                    
                    Spacer()
                    
                    // Optional Top-Right Tag / Pill Badge
                    if let tagText = tagText {
                        Text(tagText)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(tagColor ?? color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill((tagColor ?? color).opacity(0.15))
                            )
                    }
                }
                
                // Bottom Text Info Stack: Title, Main Value, & Insight Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(value)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 165, alignment: .topLeading)
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
