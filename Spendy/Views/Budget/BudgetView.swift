//
//  BudgetView.swift
//  Spendy
//
//  Native iOS Apple Standard Design Budget Screen
//

import SwiftUI

struct BudgetView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var topControlsNamespace: Namespace.ID? = nil
    var sharedNavigationHeader: AnalyticsNavigationHeaderState? = nil
    var onDismiss: (() -> Void)? = nil
    
    @State private var showEditBudgetSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var selectedCategoryForSheet: Category? = nil
    @State private var isCalculatorExpanded: Bool = false
    
    private var hasActiveBudget: Bool { store.budget.isActive && store.budget.amount > 0 }

    private var cycleDateRangeString: String {
        let start = store.budgetCycleStart()
        let end = store.budgetCycleEnd()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: start)
        let endStr = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end)
        return "\(startStr) – \(endStr)"
    }
    
    var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()
            
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text("Budget")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .padding(.top, 8)
                            .accessibilityAddTraits(.isHeader)
                            .opacity(sharedNavigationHeader == nil ? 1 : 0)
                            .accessibilityHidden(sharedNavigationHeader != nil)
                        // Title Subtitle Range Chip
                        HStack {
                            Text(cycleDateRangeString)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(SpendyColors.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(SpendyColors.separator, in: Capsule())
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                        
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
                if sharedNavigationHeader == nil {
                    topHeaderBar.padding(.bottom, 6)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
            CategoryAnalyticsSheet(category: category, topControlsNamespace: topControlsNamespace,
                sharedNavigationHeader: sharedNavigationHeader)
        }
        .onAppear { configureNavigationHeader() }
        .onChange(of: selectedCategoryForSheet?.id) { _, _ in configureNavigationHeader() }
        .onChange(of: store.budget.isActive) { _, _ in configureNavigationHeader() }
    }

    private func configureNavigationHeader() {
        guard selectedCategoryForSheet == nil else { return }
        let backAction = onDismiss
        let dismissAction = dismiss
        let editor = $showEditBudgetSheet
        let deletion = $showDeleteConfirmation
        let items: [AnalyticsNavigationHeaderMenuItem] = hasActiveBudget ? [
            AnalyticsNavigationHeaderMenuItem(id: "budget-edit", title: "Edit Budget", systemImage: "pencil") {
                editor.wrappedValue = true
            },
            AnalyticsNavigationHeaderMenuItem(id: "budget-delete", title: "Delete Budget",
                systemImage: "trash", role: .destructive) { deletion.wrappedValue = true }
        ] : []
        sharedNavigationHeader?.show(title: "Budget", onBack: {
            if let backAction { backAction() } else { dismissAction() }
        }, menuItems: items, menuLabel: "Budget Options", menuIdentifier: "budget-options")
    }
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack {
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 15,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Back",
                morphID: "topControl_left",
                namespace: topControlsNamespace
            ) {
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }

            Spacer()

            Text("Budget")
                .hidden()
                .accessibilityHidden(true)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            if hasActiveBudget {
                actionButtons
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // MARK: - Sticky Action Buttons (Stay fixed at top right)
    private var actionButtons: some View {
        Menu {
            Button {
                showEditBudgetSheet = true
            } label: {
                Label("Edit Budget", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Budget", systemImage: "trash")
            }
        } label: {
            GlassCircleButton(
                icon: "ellipsis",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .light,
                accessibilityLabel: "Budget Options"
            ) { }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        SpendyPlainEmptyState(
            title: "No budget yet",
            message: "Set a limit to track your spending.",
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
    

    private var activeBudgetContent: some View {
        VStack(spacing: 20) {
            // Main Analytics-Style Circular Ring Budget Card
            let target = store.budgetTargetAmount(for: store.budget.period)
            let spent = store.budgetCycleExpenses
            
            BudgetGaugeView(
                spent: spent,
                target: target,
                currencySymbol: store.currencySymbol,
                daysLeft: store.budgetDaysLeft,
                periodTitle: store.budget.period == .weekly ? "Weekly" : "Monthly",
                dateRangeString: cycleDateRangeString,
                pacingInsightMessage: nil,
                pacingState: store.budgetPacingState
            )
            
            // Show the insight rail only when it has something useful to say.
            let usefulInsights = budgetInsightMoments.filter { !$0.isInsufficientData }
            if !usefulInsights.isEmpty {
                SpendyInsightSummary(moments: usefulInsights) { destination in
                    if case .category(let id) = destination {
                        selectedCategoryForSheet = store.categories.first { $0.id == id }
                    }
                }
            }

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
