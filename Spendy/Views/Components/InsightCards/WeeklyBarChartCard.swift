//
//  WeeklyBarChartCard.swift
//  Spendy
//
//  Compact 7-Day Spending Bar Chart Card:
//  - Top: SpendyIconBadge
//  - Title & Amount
//  - Middle: 7-Day Vertical Spending Bars with Target Rule Line
//  - Subtitle: Clean period caption
//

import SwiftUI

struct WeeklyBarChartCard: View {
    let title: String
    let value: String
    let subtitle: String
    let dailyValues: [Double] // Expected: exactly 7 elements (Mon..Sun or Sun..Sat)
    var averageBaseline: Double = 0.0
    var icon: String? = "chart.bar.fill"
    var color: Color = .blue
    var action: (() -> Void)? = nil
    
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(value), \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top Header Row: Icon Badge
                if let icon = icon {
                    SpendyIconBadge(
                        sfSymbol: icon,
                        color: color,
                        size: .small,
                        style: .circle,
                        monogramName: title
                    )
                }
                
                Spacer().frame(height: 8)
                
                // 2. Title & Value
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(value)
                        .spendyNumberFont(size: 17, weight: .bold, tracking: -0.4)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 6)
                
                // 3. Middle: 7-Day Micro Bar Chart
                let maxVal = max(1.0, dailyValues.max() ?? 1.0)
                let activeColor = SpendyColors.isMonoMode ? SpendyColors.textPrimary : color
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<min(7, dailyValues.count), id: \.self) { index in
                        let val = dailyValues[index]
                        let barHeight = max(4.0, (val / maxVal) * 24.0)
                        let isHigh = val >= averageBaseline && averageBaseline > 0
                        
                        VStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                .fill(isHigh ? activeColor : activeColor.opacity(0.35))
                                .frame(height: barHeight)
                            
                            Text(index < dayLabels.count ? dayLabels[index] : "")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 34)
                
                Spacer(minLength: 6)
                
                // 4. Subtitle
                Text(subtitle)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            WeeklyBarChartCard(
                title: "Dining Out",
                value: "₹3,450",
                subtitle: "7-day average pace",
                dailyValues: [200, 450, 0, 800, 1200, 600, 200],
                averageBaseline: 492,
                color: .orange
            )
            
            WeeklyBarChartCard(
                title: "Fuel",
                value: "₹2,100",
                subtitle: "Weekly fuel expenditure",
                dailyValues: [0, 1000, 0, 0, 1100, 0, 0],
                averageBaseline: 300,
                color: .blue
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
