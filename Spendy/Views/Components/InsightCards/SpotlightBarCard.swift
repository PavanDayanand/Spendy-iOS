//
//  SpotlightBarCard.swift
//  Spendy
//
//  Card Design: Top Day / Spotlight Pill Card (Inspired by Modern Financial Dashboards)
//  Features:
//  - Clean header label "Top day"
//  - Primary highlighted day name in clean white bold typography
//  - 7 weekday slots with subtle dashes for inactive days & glowing gradient pill for peak day
//  - Clean day labels underneath with highlighted active day letter
//

import SwiftUI

struct SpotlightBarCard: View {
    let title: String // e.g. "Top day"
    let peakDayName: String // e.g. "Tuesday" or "Saturday"
    var peakDayIndex: Int = 2 // 0 = S, 1 = M, 2 = T, 3 = W, 4 = T, 5 = F, 6 = S
    var icon: String? = nil
    var accentColor: Color = .white
    var action: (() -> Void)? = nil
    
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(peakDayName)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Header: Clean subtle label + optional glyph
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    
                    Spacer()
                    
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                }
                
                Spacer(minLength: 6)
                
                // 2. Primary Day Name (Restrained, crisp typography)
                Text(peakDayName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
                
                Spacer(minLength: 12)
                
                // 3. Spotlight Weekday Bar Slots
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        let isPeak = index == peakDayIndex
                        VStack(spacing: 6) {
                            if isPeak {
                                // Glowing Spotlight Pill Bar
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white, Color(white: 0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: 38)
                                    .shadow(color: Color.white.opacity(0.2), radius: 4)
                            } else {
                                // Muted Horizontal Dash Marker
                                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                    .fill(SpendyColors.textTertiary.opacity(0.4))
                                    .frame(height: 3)
                                    .padding(.bottom, 2)
                            }
                            
                            Text(dayLabels[index])
                                .font(.system(size: 10, weight: isPeak ? .bold : .medium))
                                .foregroundStyle(isPeak ? SpendyColors.textPrimary : SpendyColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 52)
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            SpotlightBarCard(
                title: "Top day",
                peakDayName: "Tuesday",
                peakDayIndex: 2
            )
            
            SpotlightBarCard(
                title: "Peak Weekend",
                peakDayName: "Saturday",
                peakDayIndex: 6
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
