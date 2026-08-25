//
//  BalanceCardView.swift
//  Spendy
//
//  Hero Card with Balance Privacy Eye Toggle and Monthly Summary
//

import SwiftUI

struct BalanceCardView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var isBalanceHidden: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("TOTAL NET BALANCE")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.0)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        // Privacy Eye Button (Liquid Glass)
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                isBalanceHidden.toggle()
                            }
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            Image(systemName: isBalanceHidden ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(isBalanceHidden ? SpendyColors.warningOrange : .white.opacity(0.6))
                                .padding(6)
                        }
                        .buttonStyle(.glass)
                    }
                    
                    if isBalanceHidden {
                        Text("\(store.currencySymbol) • • • • • •")
                            .font(.system(size: 38, weight: .bold))
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(.white)
                    } else {
                        Text(store.totalBalance.formattedCurrency(symbol: store.currencySymbol))
                            .font(.system(size: 38, weight: .bold).monospacedDigit())
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }
                }
                
                Spacer()
                
                // Period Badge
                Text(Date().formattedMonthYear)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    }
            }
            
            Divider()
                .overlay(Color.white.opacity(0.08))
            
            // Income & Expense Stats Row
            HStack(spacing: 12) {
                // Income Pill
                HStack(spacing: 10) {
                    SpendyIconBadge(
                        sfSymbol: SFIcons.income,
                        color: SpendyColors.incomeGreen,
                        size: .small,
                        style: .circle
                    )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Income")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                        
                        Text(isBalanceHidden ? "••••" : store.monthlyIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(SpendyColors.cardBackgroundSecondary)
                }
                
                // Expense Pill
                HStack(spacing: 10) {
                    SpendyIconBadge(
                        sfSymbol: SFIcons.expense,
                        color: SpendyColors.expenseRed,
                        size: .small,
                        style: .circle
                    )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Expenses")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                        
                        Text(isBalanceHidden ? "••••" : store.monthlyExpense.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(SpendyColors.cardBackgroundSecondary)
                }
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
}
