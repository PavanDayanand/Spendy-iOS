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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                Spacer()
                Text(customDailySpend.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            
            // Slider
            Slider(
                value: $customDailySpend,
                in: 0...sliderMax,
                step: 50
            )
            .tint(SpendyColors.primaryBlue)
            .onChange(of: customDailySpend) { _, _ in
                HapticsManager.shared.trigger(.selection)
            }
            
            Divider().overlay(SpendyColors.separator)
            
            // Stats Row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected expenses")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    let projectedExp = store.customProjectedExpenses(dailySpend: customDailySpend)
                    Text(projectedExp.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Cycle-end balance")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    let endBalance = store.customProjectedEndBalance(dailySpend: customDailySpend)
                    Text(endBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(endBalance < 0 ? SpendyColors.expenseRed : SpendyColors.incomeGreen)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
        .onAppear {
            let initial = store.leftToday > 0 ? store.leftToday : 500.0
            customDailySpend = (initial / 50).rounded() * 50
        }
    }
}
