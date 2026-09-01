//
//  WeeklyBarChartCard.swift
//  Spendy
//
//  Card Design: 7-Day Bar Chart with Target Average Rule Line (Inspired by Apple Health Weekly View)
//  Features:
//  - Subtle header label + tiny top-right unbordered glyph
//  - Large primary value with inline "Avg." subtitle
//  - 7 vertical bar columns with variable spend heights
//  - Horizontal average target baseline line cutting across the bars
//  - Bottom day letter row (T F S S M T W)
//

import SwiftUI

struct WeeklyBarChartCard: View {
    let title: String // e.g. "Last 7 days"
    let value: String // e.g. "₹6,201"
    var unit: String = "Avg."
    var icon: String? = "chart.bar.fill"
    var color: Color = .orange
    
    // 7 days normalized heights (0.0 to 1.0)
    var barValues: [Double] = [0.45, 0.30, 0.95, 0.65, 0.40, 0.35, 0.50]
    var dayLabels: [String] = ["T", "F", "S", "S", "M", "T", "W"]
    var avgBaselineRatio: Double = 0.52 // Normalized height (0.0 to 1.0) of average line
    var action: (() -> Void)? = nil
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(value) \(unit)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Header: Clean label + minimal top-right glyph
                let effectiveColor = SpendyColors.isMonoMode ? SpendyColors.textPrimary : color
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    
                    Spacer()
                    
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(effectiveColor)
                    }
                }
                
                Spacer(minLength: 6)
                
                // 2. Value + Inline Avg. Label
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(value)
                        .spendyNumberFont(size: 30, weight: .bold, tracking: -0.5)
                        .foregroundStyle(effectiveColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Text(unit)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Spacer(minLength: 10)
                
                // 3. 7-Day Vertical Bar Chart with Horizontal Target Line
                GeometryReader { geo in
                    let chartHeight: CGFloat = geo.size.height - 18
                    let baselineY = chartHeight * CGFloat(1.0 - avgBaselineRatio)
                    
                    ZStack(alignment: .topLeading) {
                        // 7 Vertical Bars
                        HStack(alignment: .bottom, spacing: 6) {
                            ForEach(0..<min(7, barValues.count), id: \.self) { idx in
                                let val = barValues[idx]
                                VStack(spacing: 5) {
                                    Spacer(minLength: 0)
                                    
                                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                        .fill(SpendyColors.cardBackgroundSecondary)
                                        .frame(height: max(6, chartHeight * CGFloat(val)))
                                    
                                    Text(idx < dayLabels.count ? dayLabels[idx] : "")
                                        .font(.system(size: 9.5, weight: .medium))
                                        .foregroundStyle(SpendyColors.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // Thin Horizontal Baseline Rule Line
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: baselineY))
                            path.addLine(to: CGPoint(x: geo.size.width, y: baselineY))
                        }
                        .stroke(effectiveColor, lineWidth: 1.5)
                    }
                }
                .frame(height: 58)
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            WeeklyBarChartCard(
                title: "Last 7 days",
                value: "₹6,201",
                unit: "Avg.",
                icon: "chart.bar.fill",
                color: .orange
            )
            
            WeeklyBarChartCard(
                title: "Dining Spend",
                value: "₹1,450",
                unit: "Avg.",
                icon: "fork.knife",
                color: .purple,
                barValues: [0.2, 0.4, 0.8, 1.0, 0.3, 0.2, 0.5],
                dayLabels: ["S", "M", "T", "W", "T", "F", "S"],
                avgBaselineRatio: 0.45
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
