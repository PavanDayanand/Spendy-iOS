import SwiftUI

/// The live, global budget remains independent of historical Analytics filters.
struct AnalyticsBudgetSummary: View {
    @Environment(ExpenseStore.self) private var store
    let onOpen: () -> Void

    var body: some View {
        let target = store.budgetTargetAmount(for: store.budget.period)
        let active = store.budget.isActive && target > 0
        let spent = store.budgetCycleExpenses
        let remaining = target - spent
        let period = store.budget.period == .weekly ? "Weekly" : "Monthly"

        Button(action: onOpen) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Current budget")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                    if active {
                        Text("\(abs(remaining).formattedCurrency(symbol: store.currencySymbol, decimals: 0)) \(remaining < 0 ? "over budget" : "left")")
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(SpendyColors.textPrimary)
                        Text("\(spent.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) of \(target.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) used")
                            .font(.caption)
                            .foregroundStyle(SpendyColors.textSecondary)
                        Text("\(period) · All accounts")
                            .font(.caption2)
                            .foregroundStyle(SpendyColors.textSecondary)
                    } else {
                        Text("Set a spending limit")
                            .font(.headline)
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                BudgetMiniGauge(progress: active ? spent / target : nil)
            }
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(active ? "Open your current budget" : "Set up your budget")
        .accessibilityIdentifier("analytics-budget-summary")
    }
}
