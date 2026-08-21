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
    
    private var cycleDateRangeString: String {
        let start = store.budgetCycleStart()
        let end = store.budgetCycleEnd()
        let formatter = DateFormatter()
        if store.budget.period == .yearly {
            formatter.dateFormat = "yyyy"
            return formatter.string(from: start)
        } else {
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: start)
            let endStr = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end)
            return "\(startStr) – \(endStr)"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header Bar
                        headerBar
                        
                        if !store.budget.isActive || store.budget.amount <= 0 {
                            // Empty State View
                            emptyStateView
                        } else {
                            // Active Budget Content
                            activeBudgetContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditBudgetSheet) {
                EditBudgetSheet(isEditing: isEditingExisting)
            }
        }
    }
    
    // MARK: - Header Bar (Liquid Glass Edit & Delete buttons with Anchored Popover)
    private var headerBar: some View {
        HStack {
            Text("Budget")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            
            Spacer()
            
            if store.budget.isActive {
                HStack(spacing: 10) {
                    // Edit Liquid Glass Button
                    Button(action: {
                        HapticsManager.shared.trigger(.light)
                        isEditingExisting = true
                        showEditBudgetSheet = true
                    }) {
                        Image(systemName: SFIcons.edit)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .nativeLiquidGlassCircle(isInteractive: true)
                    }
                    .buttonStyle(.plain)
                    
                    // Delete Liquid Glass Button with Anchored Popover
                    Button(action: {
                        HapticsManager.shared.trigger(.medium)
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: SFIcons.trash)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(SpendyColors.expenseRed)
                            .frame(width: 38, height: 38)
                            .nativeLiquidGlassCircle(isInteractive: true)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showDeleteConfirmation, arrowEdge: .top) {
                        deleteConfirmationPopover
                            .presentationCompactAdaptation(.popover)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Delete Confirmation Popover (Anchored to Delete Button)
    private var deleteConfirmationPopover: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Delete Budget?")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("This will remove your current budget limit.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 8) {
                Button(action: {
                    HapticsManager.shared.trigger(.medium)
                    store.deleteBudget()
                    showDeleteConfirmation = false
                }) {
                    Text("Delete Budget")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(SpendyColors.expenseRed, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    showDeleteConfirmation = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 240)
        .background(SpendyColors.cardBackground)
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
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Create a budget to track your spending and stay on top of your finances.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                HapticsManager.shared.trigger(.medium)
                isEditingExisting = false
                showEditBudgetSheet = true
            }) {
                Text("Create budget")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(Color.white, in: Capsule())
            }
            .padding(.top, 4)
            
            Spacer()
        }
    }
    
    // MARK: - Active Budget Content (Apple Standard Layout)
    private var activeBudgetContent: some View {
        VStack(spacing: 20) {
            // Cycle Bounds & Live Pacing Status Subtitle
            HStack(spacing: 8) {
                Text(cycleDateRangeString)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08), in: Capsule())
                
                let pacing = store.budgetPacingState
                Text(pacing.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: pacing.colorHex))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: pacing.colorHex).opacity(0.15), in: Capsule())
                
                Spacer()
            }
            
            // 180° Arc Gauge Chart (Maximized Space)
            let target = store.budgetTargetAmount(for: store.budget.period)
            let spent = store.budgetCycleExpenses
            BudgetGaugeView(
                spent: spent,
                target: target,
                currencySymbol: store.currencySymbol
            )
            .padding(.vertical, 4)
            
            // Smart Pacing Insight Banner
            if let insightMsg = store.budgetPacingInsightMessage {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.primaryBlue)
                    
                    Text(insightMsg)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(2)
                    
                    Spacer()
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(SpendyColors.primaryBlue.opacity(0.25), lineWidth: 0.8)
                        }
                }
            }
            
            // Dual Stat Cards Row (Uniform Apple Card Styling)
            HStack(spacing: 14) {
                // Card 1: Left today
                VStack(alignment: .leading, spacing: 8) {
                    Text("Left today")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                    
                    Text(store.leftToday.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer().frame(height: 2)
                    
                    let isExceededToday = store.todayExpenses > (target / Double(max(1, store.budgetDaysLeft)))
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 5)
                        Capsule()
                            .fill(isExceededToday ? SpendyColors.expenseRed : SpendyColors.incomeGreen)
                            .frame(height: 5)
                    }
                    
                    Text(isExceededToday ? "Budget exceeded" : "Safe daily pace")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(isExceededToday ? SpendyColors.expenseRed : .white.opacity(0.45))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        }
                }
                
                // Card 2: Cycle Budget
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cycle Limit")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                    
                    Text(target.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer().frame(height: 2)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(store.budget.period == .yearly ? "Yearly Target" : "Monthly Target")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(SpendyColors.primaryBlue)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        }
                }
            }
            
            // What-If Budget Calculator
            VStack(alignment: .leading, spacing: 8) {
                Text("BUDGET CALCULATOR")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, 4)
                
                WhatIfPlannerView()
            }
        }
    }
}
