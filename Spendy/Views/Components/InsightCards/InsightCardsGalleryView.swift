//
//  InsightCardsGalleryView.swift
//  Spendy
//
//  Interactive Visual Showcase for the Modern Insight & Analytics Card Archetypes
//

import SwiftUI

struct InsightCardsGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var colorSchemeOverride: ColorScheme = .dark
    @State private var lastTappedCard: String = "None"
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Section Header + Dismiss Button
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Insight Cards Studio")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Text("Modern Micro-Charts & Minimalist Typography · 188pt")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(SpendyColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                HapticsManager.shared.trigger(.selection)
                                dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 10)
                        
                        // Theme Switcher & Last Tapped Indicator
                        HStack {
                            Picker("Theme", selection: $colorSchemeOverride) {
                                Text("Dark").tag(ColorScheme.dark)
                                Text("Light").tag(ColorScheme.light)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 140)
                            
                            Spacer()
                            
                            Text("Tapped: \(lastTappedCard)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(SpendyColors.textTertiary)
                                .lineLimit(1)
                        }
                        
                        // 2-Column Showcase Grid
                        InsightCardGrid(spacing: 14) {
                            // 1. Apple Health Style Today Pacing Pin Bar
                            PacingPinBarCard(
                                title: "Today",
                                value: "8,351",
                                deltaText: "+1.2k",
                                subtitle: "More than usual by this point",
                                progress: 0.75,
                                icon: "figure.walk",
                                color: .orange
                            ) {
                                lastTappedCard = "Today Pacing Pin"
                            }
                            
                            // 2. 7-Day Vertical Bar Chart with Target Baseline Line
                            WeeklyBarChartCard(
                                title: "Last 7 days",
                                value: "6,201",
                                unit: "Avg.",
                                icon: "chart.bar.fill",
                                color: .orange,
                                barValues: [0.45, 0.30, 0.95, 0.65, 0.40, 0.35, 0.50],
                                dayLabels: ["T", "F", "S", "S", "M", "T", "W"],
                                avgBaselineRatio: 0.52
                            ) {
                                lastTappedCard = "7-Day Bar Chart"
                            }
                            
                            // 3. Avg Spent with Gradient Floor Block
                            GradientTrendCard(
                                title: "Avg spent",
                                value: "$19.2K",
                                subtitle: "Per week",
                                lineColor: Color.blue.opacity(0.85)
                            ) {
                                lastTappedCard = "Avg Spent Gradient"
                            }
                            
                            // 4. Top Day Spotlight Pill Bar
                            SpotlightBarCard(
                                title: "Top day",
                                peakDayName: "Tuesday",
                                peakDayIndex: 2
                            ) {
                                lastTappedCard = "Top Day Spotlight"
                            }
                            
                            // 5. 30-Day Dot Matrix Streak Card
                            DotMatrixCard(
                                title: "Budget Streak",
                                streakCount: 24,
                                streakUnit: "days in a row",
                                icon: "flame.fill",
                                color: .orange,
                                totalDays: 30,
                                activeDays: 24
                            ) {
                                lastTappedCard = "Budget Streak Matrix"
                            }
                            
                            // 6. Clean Typography Insight Takeaway
                            EditorialTagCard(
                                title: "Public Transport",
                                value: "₹3,168",
                                subtitle: "14 rides · +12% higher than last month",
                                icon: nil,
                                color: .blue
                            ) {
                                lastTappedCard = "Clean Typography"
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .preferredColorScheme(colorSchemeOverride)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    InsightCardsGalleryView()
}
