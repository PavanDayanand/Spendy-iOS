//
//  WeekdaySpectrumCard.swift
//  Spendy
//
//  Archetype 4: Weekday Spectrum Bar Card (7-day distribution & peak day spotlight)
//  Features:
//  - Optional Category/Insight icon badge + section title
//  - 7-day spectrum bar columns (S M T W T F S) with peak day elevated/highlighted
//  - Primary highlighted day name
//  - Subtitle with average spend metric
//

import SwiftUI

struct WeekdaySpectrumCard: View {
    let title: String
    let peakDayName: String // e.g. "Saturday"
    let subtitle: String // e.g. "Highest spending day" or "₹6,707 avg"
    var icon: String? = "calendar"
    var color: Color = .indigo
    var peakDayIndex: Int = 6 // 0 = Sun, 1 = Mon, ..., 6 = Sat
    var action: (() -> Void)? = nil
    
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(peakDayName), \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top Row: Optional Icon Badge + Section Title
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
                
                Spacer(minLength: 10)
                
                // 2. Middle: 7-Day Spectrum Columns
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        let isPeak = index == peakDayIndex
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                .fill(isPeak ? color : SpendyColors.cardBackgroundSecondary)
                                .frame(height: isPeak ? 22 : 9)
                                .overlay {
                                    if !isPeak {
                                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                            .stroke(SpendyColors.separator, lineWidth: 0.5)
                                    }
                                }
                            
                            Text(dayLabels[index])
                                .font(.system(size: 9.5, weight: isPeak ? .bold : .medium))
                                .foregroundStyle(isPeak ? color : SpendyColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 4)
                
                Spacer(minLength: 12)
                
                // 3. Bottom: Primary Day Name + Context Subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(peakDayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                    
                    Text(subtitle)
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            WeekdaySpectrumCard(
                title: "Top Day",
                peakDayName: "Saturday",
                subtitle: "₹6,707 avg · Peak spend",
                icon: "calendar",
                color: .purple,
                peakDayIndex: 6
            )
            
            WeekdaySpectrumCard(
                title: "Coffee Runs",
                peakDayName: "Monday",
                subtitle: "5 visits avg · High volume",
                icon: "cup.and.saucer.fill",
                color: .brown,
                peakDayIndex: 1
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
