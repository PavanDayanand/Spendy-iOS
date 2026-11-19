//
//  BudgetView.swift
//  Spendy
//
//  Native iOS Apple Standard Design Budget Screen
//

import SwiftUI

struct BudgetView: View {
    @Environment(ExpenseStore.self) private var store
    
    
    @State private var showEditBudgetSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var selectedCategoryForSheet: Category? = nil
    @State private var isCalculatorExpanded: Bool = false
    
    private var hasActiveBudget: Bool { store.budget.isActive && store.budget.amount > 0 }

    private var cycleDateRangeString: String {
        let start = store.budgetCycleStart()
        let end = store.budgetCycleEnd()
        let startStr = SpendyDateFormatterCache.monthDay.string(from: start)
        let endStr = SpendyDateFormatterCache.monthDay.string(from: Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end)
        return "\(startStr) – \(endStr)"
    }
    
    var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()
            
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if !hasActiveBudget {
                            // Empty State View
                            emptyStateView
                        } else {
                            // Active Budget Content
                            activeBudgetContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            if hasActiveBudget {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Budget Options", systemImage: "ellipsis") {
                        Button("Edit Budget", systemImage: "pencil") { showEditBudgetSheet = true }
                            .accessibilityIdentifier("budget-edit")
                        Button("Delete Budget", systemImage: "trash", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .accessibilityIdentifier("budget-delete")
                    }
                    .accessibilityIdentifier("budget-options")
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: $showEditBudgetSheet) {
            EditBudgetSheet(isEditing: hasActiveBudget)
        }
        .alert("Delete Budget?", isPresented: $showDeleteConfirmation) {
            Button("Delete Budget", role: .destructive) {
                HapticsManager.shared.trigger(.medium)
                withAnimation(AppMotion.fluidSpring) {
                    store.deleteBudget()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove your current budget limit.")
        }
        .navigationDestination(item: $selectedCategoryForSheet) { category in
            CategoryAnalyticsSheet(category: category)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        SpendyPlainEmptyState(
            title: "No budget yet",
            message: "Choose a spending limit and see what’s left as you go.",
            icon: "gauge.with.dots.needle.33percent",
            actionTitle: "Set budget"
        ) {
            showEditBudgetSheet = true
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Active Budget Content
    private var budgetInsightMoments: [InsightMoment] {
        guard store.insightsEnabled else { return [] }
        let facts = store.budgetInsightFacts()
        return InsightDecisionEngine.shared.evaluate(
            facts: facts,
            surface: .budget,
            currencySymbol: store.currencySymbol
        )
    }
    

    private var budgetPacingContext: String {
        let pace: String
        switch store.budgetPacingState {
        case .onTrack: pace = "On track"
        case .overPace(let difference): pace = "\(difference)% above pace"
        case .underPace(let difference): pace = "\(difference)% below pace"
        case .exceeded: pace = "Budget exceeded"
        }
        let days = store.budgetDaysLeft
        return "\(pace) · \(days) \(days == 1 ? "day" : "days") remaining"
    }

    private var activeBudgetContent: some View {
        VStack(spacing: 20) {
            // Main Analytics-Style Circular Ring Budget Card
            let target = store.budgetTargetAmount(for: store.budget.period)
            let spent = store.budgetCycleExpenses
            
            BudgetGaugeView(
                spent: spent,
                target: target,
                currencySymbol: store.currencySymbol,
                periodTitle: store.budget.period == .weekly ? "Weekly" : "Monthly",
                dateRangeString: cycleDateRangeString
            )
            
            let usefulInsights = budgetInsightMoments.filter { !$0.isInsufficientData }
            VStack(alignment: .leading, spacing: 8) {
                if !usefulInsights.isEmpty {
                    SpendyInsightSummary(moments: usefulInsights) { destination in
                        if case .category(let id) = destination {
                            selectedCategoryForSheet = store.categories.first { $0.id == id }
                        }
                    }
                }
                Text(budgetPacingContext)
                    .font(.footnote)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("budget-insight-context")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            budgetSummaryRows(target: target, spent: spent)

            Button {
                withAnimation(AppMotion.fluidSpring) {
                    isCalculatorExpanded.toggle()
                }
                HapticsManager.shared.trigger(.selection)
            } label: {
                HStack {
                    Text("Plan daily spending")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    Spacer()
                    Image(systemName: isCalculatorExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCalculatorExpanded ? "Hide budget calculator" : "Show budget calculator")

            if isCalculatorExpanded {
                WhatIfPlannerView()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func budgetSummaryRows(target: Double, spent: Double) -> some View {
        let isOverBudget = spent > target
        let remaining = abs(target - spent)

        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isOverBudget ? "Over budget" : "Left this cycle")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text("of \(target.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                Spacer(minLength: 8)
                Text(remaining.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .spendyNumberFont(size: 23, weight: .bold, tracking: -0.5)
                    .foregroundStyle(isOverBudget ? SpendyColors.warningOrange : SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.vertical, 14)

            Divider().overlay(SpendyColors.separator)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Daily pace")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                Spacer(minLength: 8)
                Text(store.safeDailyAllowance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .spendyNumberFont(size: 23, weight: .bold, tracking: -0.5)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 4)
    }
}
