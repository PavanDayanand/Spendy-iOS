//
//  SharedInsightCard.swift
//  Spendy
//
//  Standardized Reusable Modern Insight Card Component.
//  Matching Screenshot Architecture:
//  - Top: SpendyIconBadge + Tag Chip
//  - Middle: Eyebrow + Bold Title + Custom Middle Content
//  - Hairline Divider
//  - Bottom: Large Monospaced Spend Value + Subtitle + Action Chevron
//

import SwiftUI

struct SharedInsightCard<MiddleContent: View>: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var eyebrow: String = "INSIGHT"
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
        eyebrow: String = "INSIGHT",
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
        self.eyebrow = eyebrow
        self.tagText = tagText
        self.tagColor = tagColor
        self.action = action
        self.middleContent = middleContent
    }
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(tagText != nil ? "\(tagText!), " : "")\(value), \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top Header Row: Icon Badge (Left) + Tag (Right)
                HStack(alignment: .center) {
                    SpendyIconBadge(
                        sfSymbol: icon,
                        color: color,
                        size: .small,
                        style: .circle
                    )
                    
                    Spacer(minLength: 4)
                    
                    if let tagText = tagText, !tagText.isEmpty {
                        let effectiveTagColor = SpendyColors.isMonoMode ? SpendyColors.textPrimary : (tagColor ?? color)
                        Text(tagText)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(effectiveTagColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(effectiveTagColor.opacity(SpendyColors.isMonoMode ? 0.12 : 0.15))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(effectiveTagColor.opacity(0.25), lineWidth: 0.8)
                            )
                            .lineLimit(1)
                    }
                }
                
                Spacer().frame(height: 8)
                
                // 2. Eyebrow + Hero Title
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 9.5, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(SpendyColors.textTertiary)
                        .lineLimit(1)
                    
                    Text(title)
                        .font(.system(size: 16.5, weight: .bold, design: .default))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                
                // 3. Middle Custom Content
                let middle = middleContent()
                if !(middle is EmptyView) {
                    middle
                        .padding(.top, 4)
                }
                
                Spacer(minLength: 8)
                
                // 4. Hairline Divider
                Rectangle()
                    .fill(SpendyColors.separator)
                    .frame(height: 0.8)
                    .padding(.bottom, 8)
                
                // 5. Bottom Footer Row: Value (Left) + Chevron (Right)
                HStack(alignment: .bottom, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1.5) {
                        if !value.isEmpty {
                            Text(value)
                                .spendyNumberFont(size: 18.5, weight: .bold, tracking: -0.4)
                                .foregroundStyle(SpendyColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        
                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.80)
                    }
                    
                    Spacer(minLength: 4)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary.opacity(0.6))
                        .padding(.bottom, 3)
                }
            }
        }
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
        eyebrow: String = "INSIGHT",
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
            eyebrow: eyebrow,
            tagText: tagText,
            tagColor: tagColor,
            action: action,
            middleContent: { EmptyView() }
        )
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            HStack(spacing: 14) {
                SharedInsightCard(
                    title: "Public Transport",
                    value: "₹3,168",
                    subtitle: "14 expenses this month",
                    icon: "tram.fill",
                    color: .blue,
                    eyebrow: "COMMUTE",
                    tagText: "+12%"
                )
                
                SharedInsightCard(
                    title: "Groceries",
                    value: "₹852",
                    subtitle: "Under monthly budget limit",
                    icon: "cart.fill",
                    color: .green,
                    eyebrow: "LIVING",
                    tagText: "On Track"
                )
            }
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
