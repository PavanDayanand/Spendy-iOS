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
    @State private var isEditingExisting: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var selectedCategoryForSheet: Category? = nil
    
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
        NavigationStack {
            ZStack {
                LiquidMeshBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Title Header (Scrolls away with page)
                        titleHeader
                        
                        if !store.budget.isActive || store.budget.amount <= 0 {
                            // Empty State View
                            emptyStateView
                        } else {
                            // Active Budget Content
                            activeBudgetContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 140)
                }
            }
            .overlay(alignment: .topTrailing) {
                // Sticky Action Buttons (Stay fixed at top right)
                if store.budget.isActive {
                    actionButtons
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                        .zIndex(100)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showEditBudgetSheet) {
                EditBudgetSheet(isEditing: isEditingExisting)
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
    }

    
    // MARK: - Title Header (Scrolls away)
    private var titleHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Budget")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Spacer()
            }
            
            Text(cycleDateRangeString)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(SpendyColors.separator, in: Capsule())
        }
        .padding(.top, 8)
    }
    
    // MARK: - Sticky Action Buttons (Stay fixed at top right)
    private var actionButtons: some View {
        Menu {
            Button {
                isEditingExisting = true
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
        VStack(spacing: 20) {
            Spacer().frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(SpendyColors.primaryBlue.opacity(0.12))
                    .frame(width: 90, height: 90)
                
                Image(systemName: SFIcons.wallet)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(SpendyColors.primaryBlue)
            }
            
            VStack(spacing: 8) {
                Text("No budget set")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Text("Create a budget to track your spending and stay on top of your finances.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                HapticsManager.shared.trigger(.medium)
                isEditingExisting = false
                showEditBudgetSheet = true
            }) {
                Text("Create budget")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.inverseText)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(SpendyColors.primaryBlue, in: Capsule())
            }
            .padding(.top, 4)
            
            Spacer()
        }
    }
    
    // MARK: - Active Budget Content
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
                pacingInsightMessage: store.budgetPacingInsightMessage,
                pacingState: store.budgetPacingState
            )
            
            // Dual Stat Cards Row (Exact Same Size as Home Screen Insight Cards, NO ICONS)
            HStack(spacing: 10) {
                // Card 1: Left today
                let isExceededToday = store.todayExpenses > (target / Double(max(1, store.budgetDaysLeft)))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Left today")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    
                    Text(store.leftToday.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 24, weight: .heavy, tracking: -0.8)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Spacer(minLength: 12)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Capsule()
                            .fill(isExceededToday ? SpendyColors.warningOrange : SpendyColors.incomeGreen)
                            .frame(height: 6)
                        
                        Text(isExceededToday ? "Above daily target" : "Safe daily pace")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isExceededToday ? SpendyColors.warningOrange : SpendyColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: 185, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
                
                // Card 2: Budget
                VStack(alignment: .leading, spacing: 10) {
                    Text("Budget")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    
                    Text(target.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 24, weight: .heavy, tracking: -0.8)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Spacer(minLength: 12)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Available to allocate:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Text(target.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .spendyNumberFont(size: 13, weight: .bold, tracking: -0.3)
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: 185, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
            }
            
            // What-If Budget Calculator Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Budget Calculator")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .padding(.horizontal, 4)
                
                WhatIfPlannerView()
            }
        }
    }
}
