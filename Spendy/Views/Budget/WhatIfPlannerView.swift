//
//  WhatIfPlannerView.swift
//  Spendy
//
//  Interactive Budget Calculator / What-If Planner with Apple Design Surface
//

import SwiftUI

struct WhatIfPlannerView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var customDailySpend: Double = 500.0
    
    private var sliderMax: Double {
        let target = store.budgetTargetAmount(for: store.budget.period)
        let days = max(1, store.budgetDaysLeft)
        return max(2000.0, (target / Double(days)) * 2.5)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Daily spend")
                    .font(AppTypography.subheadlineSemibold)
                    .foregroundStyle(SpendyColors.textSecondary)
                Spacer()
                Text(customDailySpend.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .spendyNumberFont(size: 17, weight: .bold, tracking: -0.5)
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            
            // Custom Tick Slider with Snapping & Tick-crossing Haptics
            CustomSpendSlider(
                value: $customDailySpend,
                maxRange: sliderMax,
                currencySymbol: store.currencySymbol
            )
            
            Divider().overlay(SpendyColors.separator)
            
            // Stats Row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected expenses")
                        .font(AppTypography.captionMedium)
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    let projectedExp = store.customProjectedExpenses(dailySpend: customDailySpend)
                    Text(projectedExp.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 17, weight: .bold, tracking: -0.5)
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Cycle-end balance")
                        .font(AppTypography.captionMedium)
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    let endBalance = store.customProjectedEndBalance(dailySpend: customDailySpend)
                    Text(endBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 17, weight: .bold, tracking: -0.5)
                        .foregroundStyle(endBalance < 0 ? SpendyColors.expenseRed : SpendyColors.incomeGreen)
                }
            }
        }
        .padding(.horizontal, 4)
        .onAppear {
            let initial = store.safeDailyAllowance > 0 ? store.safeDailyAllowance : 500.0
            customDailySpend = (initial / 50).rounded() * 50
        }
    }
}

// MARK: - Custom Spend Slider Component
private struct CustomSpendSlider: View {
    @Binding var value: Double
    let maxRange: Double
    let currencySymbol: String
    
    private let totalTicks = 9
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let thumbSize: CGFloat = 26
            let fraction = maxRange > 0 ? value / maxRange : 0
            let thumbX = fraction * width
            
            VStack(alignment: .leading, spacing: 6) {
                // Slider track and thumb
                ZStack(alignment: .leading) {
                    // Unfilled Background Track
                    Capsule()
                        .fill(Color(uiColor: .dynamic(light: UIColor(white: 0.0, alpha: 0.06), dark: UIColor(white: 1.0, alpha: 0.12))))
                        .frame(height: 5)
                    
                    // Active Filled Track (Gradient)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#FF9500"), Color(hex: "#FF2D55")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(0, thumbX), height: 5)
                    
                    // Thumb
                    Circle()
                        .fill(SpendyColors.primaryBlue) // Dynamic monochrome (white in dark, black in light)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1.5)
                        .offset(x: max(0, min(width - thumbSize, thumbX - thumbSize / 2)))
                }
                .frame(height: thumbSize)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let locationX = gesture.location.x
                            let rawFraction = min(1.0, max(0.0, locationX / width))
                            let rawValue = rawFraction * maxRange
                            
                            // Snapping to nearest 50
                            let snappedValue = (rawValue / 50.0).rounded() * 50.0
                            let finalValue = min(maxRange, max(0.0, snappedValue))
                            
                            if finalValue != value {
                                // Notched selection haptics
                                let oldNotch = Int(round((value / maxRange) * Double(totalTicks - 1)))
                                let newNotch = Int(round((finalValue / maxRange) * Double(totalTicks - 1)))
                                if oldNotch != newNotch {
                                    HapticsManager.shared.trigger(.selection)
                                }
                                value = finalValue
                            }
                        }
                )
                
                // Tick Marks
                ZStack(alignment: .leading) {
                    ForEach(0..<totalTicks, id: \.self) { index in
                        let tickFraction = Double(index) / Double(totalTicks - 1)
                        let xOffset = tickFraction * (width - 1.5)
                        
                        Rectangle()
                            .fill(SpendyColors.separator)
                            .frame(width: 1.5, height: 5)
                            .offset(x: xOffset)
                    }
                }
                .frame(height: 5)
                .padding(.top, 2)
                
                // Labels below ticks
                HStack {
                    Text(0.0.formattedCurrency(symbol: currencySymbol, decimals: 0))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Spacer()
                    
                    let midValue = maxRange / 2
                    Text(midValue.formattedCurrency(symbol: currencySymbol, decimals: 0))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Spacer()
                    
                    Text(maxRange.formattedCurrency(symbol: currencySymbol, decimals: 0))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .padding(.top, 4)
            }
        }
        .frame(height: 64)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily spend limit")
        .accessibilityValue("\(Int(value)) \(currencySymbol)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(maxRange, value + 50)
                HapticsManager.shared.trigger(.selection)
            case .decrement:
                value = max(0, value - 50)
                HapticsManager.shared.trigger(.selection)
            @unknown default:
                break
            }
        }
    }
}
