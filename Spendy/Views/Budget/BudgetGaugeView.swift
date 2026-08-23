//
//  BudgetGaugeView.swift
//  Spendy
//
//  Premium 240-Degree Segmented Progress Arc Gauge consisting of Capsule "small card" segments,
//  vibrant Peach-Orange-Red gradient progression, and a clean pacing status badge.
//

import SwiftUI

struct BudgetGaugeView: View {
    let spent: Double
    let target: Double
    let currencySymbol: String
    var daysLeft: Int = 0
    var periodTitle: String = "Monthly"
    var dateRangeString: String = ""
    var pacingInsightMessage: String? = nil
    let pacingState: ExpenseStore.BudgetPacingState
    
    @State private var animatedFilledSegments: Int = 0
    
    private let totalSegments = 19
    private let radius: CGFloat = 145.0
    
    private var percentage: Double {
        guard target > 0 else { return 0 }
        return (spent / target) * 100.0
    }
    
    private var filledSegments: Int {
        guard target > 0 else { return 0 }
        let progress = spent / target
        return Int(round(min(1.0, max(0.0, progress)) * Double(totalSegments)))
    }
    
    private var isExceeded: Bool {
        spent > target && target > 0
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 1. Title, Large Amount, & Status Badge
            VStack(spacing: 6) {
                Text(periodTitle == "Weekly" ? "Spent this week" : "Spent this month")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(SpendyColors.textTertiary)
                
                HStack(alignment: .center, spacing: 10) {
                    Text(spent.formattedCurrency(symbol: currencySymbol, decimals: 0))
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(isExceeded ? Color(hex: "#FF453A") : SpendyColors.textPrimary)
                    
                    pacingStatusBadge
                }
            }
            .padding(.top, 10)
            
            // 2. 240-Degree Segmented Arc of "Small Cards"
            ZStack {
                // Bounds-defining container
                Color.clear
                    .frame(width: radius * 2 + 40, height: radius * 1.5 + 40)
                
                ForEach(0..<totalSegments, id: \.self) { index in
                    let angleDegrees = 210.0 - Double(index) * (240.0 / Double(totalSegments - 1))
                    let angleRadians = angleDegrees * .pi / 180.0
                    let x = radius * cos(angleRadians)
                    let y = -radius * sin(angleRadians)
                    let isFilled = index < animatedFilledSegments
                    
                    Capsule()
                        .fill(isFilled ? segmentColor(for: index) : Color(uiColor: .dynamic(light: UIColor(white: 0.0, alpha: 0.08), dark: UIColor(white: 1.0, alpha: 0.12))))
                        .frame(width: 9, height: 34)
                        .scaleEffect(isFilled ? 1.05 : 0.95)
                        .shadow(color: isFilled ? segmentColor(for: index).opacity(0.45) : .clear, radius: 4, x: 0, y: 1)
                        .rotationEffect(.degrees(90.0 - angleDegrees))
                        .offset(x: x, y: y + radius * 0.25)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.70)
                            .delay(Double(index) * 0.03),
                            value: animatedFilledSegments
                        )
                }
                
                // Centered text inside the circle
                VStack(spacing: 2) {
                    Text("\(daysLeft)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .contentTransition(.numericText())
                    
                    Text(daysLeft == 1 ? "day left" : "days left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                        .textCase(.uppercase)
                }
                .offset(y: radius * 0.25)
            }
            .frame(width: radius * 2 + 40, height: radius * 1.5 + 40)
            
            // 3. Pacing insight (without card background!)
            if let msg = pacingInsightMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isExceeded ? Color(hex: "#FF453A") : Color(hex: "#30D158"))
                        .padding(.top, 2)
                    
                    Text(msg)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.top, -8)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            animatedFilledSegments = 0
            withAnimation(.easeOut(duration: 0.85).delay(0.1)) {
                animatedFilledSegments = filledSegments
            }
        }
        .onChange(of: filledSegments) { _, newValue in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                animatedFilledSegments = newValue
            }
        }
    }
    
    // MARK: - Pacing Status Badge
    private var pacingStatusBadge: some View {
        let iconName: String
        let badgeText: String
        let badgeColor: Color
        
        switch pacingState {
        case .onTrack:
            iconName = "checkmark.circle.fill"
            badgeText = "On track"
            badgeColor = Color(hex: "#30D158")
        case .overPace(let pctDiff):
            iconName = "arrow.up.forward.circle.fill"
            badgeText = "↑ \(pctDiff)% high"
            badgeColor = Color(hex: "#FF9500")
        case .underPace(let pctDiff):
            iconName = "arrow.down.forward.circle.fill"
            badgeText = "↓ \(pctDiff)% less"
            badgeColor = Color(hex: "#30D158")
        case .exceeded:
            iconName = "exclamationmark.octagon.fill"
            badgeText = "Exceeded"
            badgeColor = Color(hex: "#FF453A")
        }
        
        return HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .bold))
            Text(badgeText)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.12), in: Capsule())
    }
    
    // MARK: - Color Interpolation Helper
    private func interpolateColor(from c1: Color, to c2: Color, fraction: Double) -> Color {
        let ui1 = UIColor(c1)
        let ui2 = UIColor(c2)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        ui1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        ui2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 + (r2 - r1) * CGFloat(fraction)
        let g = g1 + (g2 - g1) * CGFloat(fraction)
        let b = b1 + (b2 - b1) * CGFloat(fraction)
        let a = a1 + (a2 - a1) * CGFloat(fraction)
        
        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
    
    // MARK: - Segment Color Generation
    private func segmentColor(for index: Int) -> Color {
        let fraction = Double(index) / Double(totalSegments - 1)
        
        let c1 = Color(hex: "#FFA07A") // Light Peach/Pink
        let c2 = Color(hex: "#FF9500") // Orange
        let c3 = Color(hex: "#FF3B30") // Red
        
        if fraction < 0.5 {
            return interpolateColor(from: c1, to: c2, fraction: fraction * 2.0)
        } else {
            return interpolateColor(from: c2, to: c3, fraction: (fraction - 0.5) * 2.0)
        }
    }
}
