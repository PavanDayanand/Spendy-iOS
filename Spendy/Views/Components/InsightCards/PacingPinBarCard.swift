//
//  PacingPinBarCard.swift
//  Spendy
//
//  Card Design: Pacing Bar with Delta Tag (Inspired by Apple Health Today Metric)
//  Features:
//  - Subtle header label + tiny top-right unbordered glyph
//  - Value moved up close to header
//  - Open middle space
//  - Horizontal track with floating delta pill tag (+₹1.2k / surplus / deficit)
//  - Restrained 2-line legible secondary subtitle
//

import SwiftUI

struct PacingPinBarCard: View {
    let title: String // e.g. "Today" or "Daily Budget"
    let value: String // e.g. "₹8,351"
    let deltaText: String // e.g. "+1.2k" or "-₹350"
    let subtitle: String // e.g. "More than usual by this point"
    var progress: Double = 0.72 // 0.0 to 1.0
    var icon: String? = "flame.fill"
    var color: Color = .orange
    var action: (() -> Void)? = nil
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(value), \(deltaText), \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Header: Clean label + minimal top-right glyph
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    
                    Spacer()
                    
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(color)
                    }
                }
                
                Spacer().frame(height: 6)
                
                // 2. Primary Value (Moved up close to header)
                Text(value)
                    .spendyNumberFont(size: 28, weight: .bold, tracking: -0.5)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                // 3. Middle: Open Space
                Spacer(minLength: 16)
                
                // 4. Pacing Pin Track Bar
                GeometryReader { geo in
                    let trackWidth = geo.size.width
                    let barWidth = max(20, min(trackWidth - 36, trackWidth * CGFloat(progress)))
                    let effectiveColor = SpendyColors.isMonoMode ? SpendyColors.textPrimary : color
                    
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(SpendyColors.cardBackgroundSecondary)
                            .frame(height: 8)
                        
                        // Filled bar
                        Capsule()
                            .fill(SpendyColors.separator.opacity(0.8))
                            .frame(width: barWidth, height: 8)
                        
                        // Floating pin pill
                        HStack(spacing: 0) {
                            Spacer().frame(width: max(0, barWidth - 14))
                            
                            HStack(spacing: 2) {
                                Text(deltaText)
                                    .font(.system(size: 10, weight: .bold, design: .default))
                                    .monospacedDigit()
                                    .foregroundStyle(Color.black)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill(effectiveColor)
                            )
                        }
                    }
                }
                .frame(height: 18)
                
                Spacer().frame(height: 8)
                
                // 5. Subtitle (2-line support)
                Text(subtitle)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            PacingPinBarCard(
                title: "Daily Burn",
                value: "₹5,000/day",
                deltaText: "+₹5000",
                subtitle: "30 days remaining in cycle",
                progress: 0.75,
                icon: "gauge.with.dots.needle.bottom.50percent",
                color: .green
            )
            
            PacingPinBarCard(
                title: "Groceries",
                value: "₹2,400",
                deltaText: "-450",
                subtitle: "Under daily average pace",
                progress: 0.40,
                icon: "cart.fill",
                color: .green
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
