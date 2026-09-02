//
//  LiveBudgetJourneyCard.swift
//  Spendy
//
//  Glanceable Liquid Glass Budget Card for Home Screen
//  Features:
//  - Clean, borderless, high-signal glanceable design
//  - White semantic typography (no purple text)
//  - 1-Split Segmented Progress Track (80% Safe Zone + 20% Buffer Zone with physical gap)
//  - Dynamic color-shifting progress fills (Green -> Amber -> Red)
//  - Prominent daily allowance & total remaining balance
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
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            onViewDetails()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // 1. Top Row: Status Headline + Days Remaining (Clean White & Secondary)
                HStack(alignment: .center) {
                    Text(statusHeadline)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    if isBudgetActive {
                        let daysLeft = store.budgetDaysLeft
                        Text("\(daysLeft) \(daysLeft == 1 ? "day" : "days") left")
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                }
                
                // 2. Center: 1-Split Segmented Progress Track (80% Safe Zone + 20% Buffer Zone)
                if isBudgetActive {
                    segmentedProgressTrack
                }
                
                // 3. Bottom Row: Big Daily Allowance + Remaining Balance
                HStack(alignment: .firstTextBaseline) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(allowanceFormatted)
                            .spendyNumberFont(size: 21, weight: .bold, tracking: -0.5)
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        if isBudgetActive {
                            Text("/day")
                                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                                .foregroundStyle(SpendyColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(remainingSubtitle)
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(SpendyColors.textSecondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background {
                cardGlassBackground
            }
        }
        .buttonStyle(LiveCardButtonStyle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(statusHeadline), \(allowanceFormatted) per day, \(remainingSubtitle)")
    }
    
    // MARK: - Segmented Progress Track (1 Split with physical gap)
    
    private var segmentedProgressTrack: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let totalWidth = geo.size.width
            let availableWidth = max(0, totalWidth - spacing)
            let segment1Width = availableWidth * 0.80 // 80% Safe zone
            let segment2Width = availableWidth * 0.20 // 20% Buffer zone
            let trackHeight: CGFloat = 6
            
            // Segment 1 progress: fills from 0.0 to 1.0 (representing 0% to 80% total budget)
            let seg1Progress = min(1.0, progress / 0.80)
            let seg1FillWidth = segment1Width * CGFloat(seg1Progress)
            
            // Segment 2 progress: fills from 0.0 to 1.0 (representing 80% to 100% total budget)
            let seg2Progress = progress > 0.80 ? min(1.0, (progress - 0.80) / 0.20) : 0.0
            let seg2FillWidth = segment2Width * CGFloat(seg2Progress)
            
            let seg1Color: Color = isOverPace ? Color(hex: "#FF9F0A") : Color(hex: "#30D158")
            let seg2Color: Color = progress >= 1.0 ? Color(hex: "#FF453A") : Color(hex: "#FF9F0A")
            
            HStack(spacing: spacing) {
                // Segment 1: Safe 80% Zone
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: segment1Width, height: trackHeight)
                    
                    if seg1FillWidth > 0 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        seg1Color.opacity(0.75),
                                        seg1Color
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(trackHeight, min(segment1Width, seg1FillWidth)), height: trackHeight)
                            .shadow(color: seg1Color.opacity(0.4), radius: 4, y: 1)
                    }
                }
                
                // Segment 2: Buffer 20% Zone (Split & Continue)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: segment2Width, height: trackHeight)
                    
                    if seg2FillWidth > 0 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        seg2Color.opacity(0.75),
                                        seg2Color
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(trackHeight, min(segment2Width, seg2FillWidth)), height: trackHeight)
                            .shadow(color: seg2Color.opacity(0.4), radius: 4, y: 1)
                    }
                }
            }
        }
        .frame(height: 6)
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
            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 5)
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
