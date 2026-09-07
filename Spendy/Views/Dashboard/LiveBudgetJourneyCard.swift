//
//  LiveBudgetJourneyCard.swift
//  Spendy
//
//  Glanceable Segmented Capsule Arc Gauge Budget Card for Home Screen
//  Features:
//  - Clean, borderless, high-signal glanceable 2-column design
//  - Left: Period/Days eyebrow, pacing headline, daily allowance & remaining balance
//  - Right: Miniature segmented capsule arc gauge (consistent with BudgetGaugeView)
//  - Dynamic color-shifting progress fills (Peach -> Orange -> Red)
//

import SwiftUI

struct LiveBudgetJourneyCard: View {
    @Environment(ExpenseStore.self) private var store
    var hideBalance: Bool = false
    var onViewDetails: () -> Void
    
    // MARK: - Computed Properties
    
    private var budgetTarget: Double {
        store.budgetTargetAmount(for: store.budget.period)
    }
    
    private var spent: Double {
        store.budgetCycleExpenses
    }
    
    private var remaining: Double {
        max(0.0, budgetTarget - spent)
    }
    
    private var isBudgetActive: Bool {
        store.budget.isActive && budgetTarget > 0
    }
    
    private var progress: Double {
        guard isBudgetActive, budgetTarget > 0 else { return 0.0 }
        return min(1.0, max(0.0, spent / budgetTarget))
    }
    
    private var pacingState: ExpenseStore.BudgetPacingState {
        store.budgetPacingState
    }
    
    private var isOverPace: Bool {
        if case .overPace = pacingState { return true }
        return false
    }
    
    private var eyebrowText: String {
        if !isBudgetActive {
            return "Monthly Budget"
        }
        let daysLeft = store.budgetDaysLeft
        let periodName = store.budget.period.rawValue
        return "\(periodName) Budget · \(daysLeft) \(daysLeft == 1 ? "day" : "days") left"
    }
    
    private var eyebrowColor: Color {
        if SpendyColors.isMonoMode {
            return SpendyColors.textSecondary
        }
        switch pacingState {
        case .onTrack, .underPace:
            return Color(hex: "#38BDF8") // Vibrant sky cyan matching reference mockup
        case .overPace:
            return SpendyColors.warningOrange
        case .exceeded:
            return SpendyColors.expenseRed
        }
    }
    
    private var statusHeadline: String {
        if !isBudgetActive {
            return "Monthly Budget"
        }
        switch pacingState {
        case .onTrack:
            return "Safe daily pace · On track"
        case .underPace:
            return "Under pace · Spend safely"
        case .overPace:
            return "Daily burn · Over pace"
        case .exceeded:
            return "Budget limit exceeded"
        }
    }
    
    private var allowanceFormatted: String {
        if !isBudgetActive {
            return "Set Target"
        }
        if hideBalance {
            return "••••"
        }
        return store.safeDailyAllowance.formattedCurrency(symbol: store.currencySymbol, decimals: 0)
    }
    
    private var remainingSubtitle: String {
        if !isBudgetActive {
            return "Tap to plan limit"
        }
        if hideBalance {
            return "•••• remaining"
        }
        return "\(remaining.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) remaining"
    }

    // MARK: - Body
    
    var body: some View {
        if !isBudgetActive {
            SpendyEmptyCardView(
                message: "Add a few more transactions so we can suggest a more accurate category limit.",
                actionTitle: "Set budget limit",
                isEnclosedInCard: true
            ) {
                onViewDetails()
            }
        } else {
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                onViewDetails()
            }) {
                HStack(alignment: .center, spacing: 14) {
                    // Left Column: Eyebrow + Headline + Subtitle (Data-Rich Glanceable Hierarchy)
                    VStack(alignment: .leading, spacing: 6) {
                        // 1. Eyebrow: Period + Days Remaining in Accent Cyan / Pacing Tint
                        Text(eyebrowText)
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(eyebrowColor)
                            .lineLimit(1)
                        
                        // 2. Headline: Pacing State Status (Editorial bold text)
                        Text(statusHeadline)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        
                        // 3. Subtitle: Daily Allowance + Remaining Balance
                        HStack(spacing: 5) {
                            Text("\(allowanceFormatted)/day")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(SpendyColors.textSecondary)
                            
                            Text("•")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(SpendyColors.textTertiary)
                            
                            Text(remainingSubtitle)
                                .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                                .monospacedDigit()
                                .foregroundStyle(SpendyColors.textSecondary)
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
                    
                    Spacer(minLength: 4)
                    
                    // Right Column: Mini Segmented Capsule Arc Gauge (Matching Budget Sheet)
                    SegmentedBudgetGaugeMini(
                        progress: progress,
                        hideBalance: hideBalance
                    )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .background {
                    cardGlassBackground
                }
            }
            .buttonStyle(LiveCardButtonStyle())
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(statusHeadline), \(allowanceFormatted) per day, \(remainingSubtitle), \(Int(round(progress * 100))) percent progress")
        }
    }
    
    // MARK: - Card Glass Background (Clean & Borderless)
    
    private var cardGlassBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        SpendyColors.cardBackground,
                        SpendyColors.cardBackground.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .spendyCardLift()
    }
}

// MARK: - Button Style

private struct LiveCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.76), value: configuration.isPressed)
    }
}

// MARK: - Mini Segmented Budget Gauge (Consistent with BudgetGaugeView)

private struct SegmentedBudgetGaugeMini: View {
    let progress: Double
    let hideBalance: Bool
    
    @State private var animatedFilledSegments: Int = 0
    
    private let totalSegments = 13
    private let radius: CGFloat = 38.0
    private let segmentWidth: CGFloat = 3.5
    private let segmentHeight: CGFloat = 11.0
    
    private var percentageText: String {
        if hideBalance { return "••%" }
        let clamped = min(1.0, max(0.0, progress))
        return "\(Int(round(clamped * 100)))%"
    }
    
    private var filledSegments: Int {
        guard progress > 0 else { return 0 }
        let clamped = min(1.0, max(0.0, progress))
        return Int(round(clamped * Double(totalSegments)))
    }
    
    var body: some View {
        ZStack {
            // Container to define bounds
            Color.clear
                .frame(width: radius * 2 + 20, height: radius * 1.35 + 10)
            
            // Segmented Capsule Arc (200 degrees from 190° down to -10°)
            ForEach(0..<totalSegments, id: \.self) { index in
                let angleDegrees = 190.0 - Double(index) * (200.0 / Double(totalSegments - 1))
                let angleRadians = angleDegrees * .pi / 180.0
                let x = radius * cos(angleRadians)
                let y = -radius * sin(angleRadians)
                let isFilled = index < animatedFilledSegments
                
                Capsule()
                    .fill(
                        isFilled
                            ? segmentColor(for: index)
                            : Color(uiColor: .dynamic(light: UIColor(white: 0.0, alpha: 0.08), dark: UIColor(white: 1.0, alpha: 0.12)))
                    )
                    .frame(width: segmentWidth, height: segmentHeight)
                    .scaleEffect(isFilled ? 1.08 : 0.94)
                    .shadow(color: isFilled ? segmentColor(for: index).opacity(0.45) : .clear, radius: 3, x: 0, y: 1)
                    .rotationEffect(.degrees(90.0 - angleDegrees))
                    .offset(x: x, y: y + radius * 0.18)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.72)
                        .delay(Double(index) * 0.025),
                        value: animatedFilledSegments
                    )
            }
            
            // Centered Metrics inside the arc
            VStack(spacing: 1.5) {
                Text(percentageText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(SpendyColors.textPrimary)
                    .contentTransition(.numericText())
                
                Text("Progress")
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            .offset(y: radius * 0.18)
        }
        .frame(width: radius * 2 + 20, height: radius * 1.35 + 10)
        .onAppear {
            animatedFilledSegments = 0
            withAnimation(.easeOut(duration: 0.7).delay(0.08)) {
                animatedFilledSegments = filledSegments
            }
        }
        .onChange(of: filledSegments) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                animatedFilledSegments = newValue
            }
        }
    }
    
    // MARK: - Color Interpolation Helper (Matching BudgetGaugeView)
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
    
    // MARK: - Segment Color Generation (Matching BudgetGaugeView Peach -> Orange -> Red)
    private func segmentColor(for index: Int) -> Color {
        if SpendyColors.isMonoMode {
            return SpendyColors.textPrimary
        }
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
