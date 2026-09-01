//
//  TelemetryHUDCard.swift
//  Spendy
//
//  Archetype 2: Daily Burn Rate & Pacing Card
//  Features:
//  - Clean header: Icon + Title (or pure text title)
//  - Large bold burn rate figure with monospaced unit
//  - Clean, elegant bottom runway text (NO capsule buttons or safe badges)
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
                // 1. Top Row: Optional Icon badge + Section Title
                HStack(spacing: 8) {
                    if let icon = icon {
                        SpendyIconBadge(
                            sfSymbol: icon,
                            color: color,
                            size: .small,
                            style: .circle
                        )
                    }
                    
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    Spacer(minLength: 0)
                }
                
                Spacer(minLength: 12)
                
                // 2. Middle: Large Burn Rate Amount + Unit
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .spendyNumberFont(size: 28, weight: .heavy, tracking: -0.5)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Text(unit)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 14)
                
                // 3. Bottom: Clean Text Runway (No pill badges)
                Text(subtitle)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
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
                subtitle: "18 days left · Safe pace",
                icon: "gauge.with.dots.needle.bottom.50percent",
                color: .green
            )
            
            TelemetryHUDCard(
                title: "Spending Velocity",
                value: "₹1,240",
                unit: "/day",
                subtitle: "Higher than your ₹800 daily target",
                icon: "speedometer",
                color: .orange
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
