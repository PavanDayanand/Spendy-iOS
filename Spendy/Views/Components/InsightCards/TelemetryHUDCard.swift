//
//  TelemetryHUDCard.swift
//  Spendy
//
//  Redesigned Daily Burn Rate & Pacing Card matching Screenshot Architecture:
//  - Top: Icon badge + Tag chip
//  - Middle: Eyebrow + Title + Velocity Rate
//  - Hairline Divider
//  - Bottom: Main Metric + Runway Subtitle + Action Chevron
//

import SwiftUI

struct TelemetryHUDCard: View {
    let title: String
    let value: String
    let unit: String // e.g. "/day"
    let subtitle: String // e.g. "18 days remaining · On track"
    var icon: String? = "gauge.with.dots.needle.bottom.50percent"
    var color: Color = .green
    var action: (() -> Void)? = nil
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(value) \(unit), \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top Header Row
                let effectiveColor = SpendyColors.isMonoMode ? SpendyColors.textPrimary : color
                HStack(alignment: .center) {
                    if let icon = icon {
                        SpendyIconBadge(
                            sfSymbol: icon,
                            color: color,
                            size: .small,
                            style: .rounded()
                        )
                    }
                    
                    Spacer(minLength: 4)
                    
                    Text("Velocity")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(effectiveColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(effectiveColor.opacity(0.12))
                        )
                        .overlay(
                            Capsule().stroke(effectiveColor.opacity(0.25), lineWidth: 0.8)
                        )
                }
                
                Spacer().frame(height: 8)
                
                // 2. Eyebrow + Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("SPENDING VELOCITY")
                        .font(.system(size: 9.5, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                // 3. Middle: Rate Figure
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .spendyNumberFont(size: 22, weight: .heavy, tracking: -0.4)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(unit)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Spacer(minLength: 10)
                
                // 4. Hairline Divider
                Rectangle()
                    .fill(SpendyColors.separator)
                    .frame(height: 0.8)
                    .padding(.bottom, 8)
                
                // 5. Bottom Footer Row
                HStack(alignment: .bottom, spacing: 6) {
                    Text(subtitle)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 4)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary.opacity(0.6))
                        .padding(.bottom, 2)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            TelemetryHUDCard(
                title: "Daily Burn",
                value: "₹450",
                unit: "/day",
                subtitle: "18 days left • Safe pace",
                icon: "gauge.with.dots.needle.bottom.50percent",
                color: .green
            )
            
            TelemetryHUDCard(
                title: "Spending Velocity",
                value: "₹1,240",
                unit: "/day",
                subtitle: "Pacing above target",
                icon: "speedometer",
                color: .orange
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
