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
    
    @Namespace private var budgetControlsNamespace
    
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
            ZStack(alignment: .top) {
                // 1. Dynamic Canvas Background framing the centerpiece card
                store.canvasBackgroundColor
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        // 2. Detached Top Capsule Navbar (44x44 Circular Action Buttons)
                        topDetachedPillBar
                            .padding(.top, 4)
                        
                        // 3. Main Centerpiece Sheet Card
                        centerpieceWhiteCard
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditBudgetSheet) {
                EditBudgetSheet(isEditing: isEditingExisting)
            }
            .navigationDestination(item: $selectedCategoryForSheet) { category in
                CategoryAnalyticsSheet(
                    category: category,
                    topControlsNamespace: budgetControlsNamespace
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedCategoryForSheet = nil
                    }
                }
            }
        }
    }
    
    // MARK: - 1. Top Detached Capsule Navbar (44x44 Circular Buttons)
    private var topDetachedPillBar: some View {
        HStack(alignment: .center) {
            // Target Icon Badge (44x44 Circle)
            ZStack {
                Circle()
                    .fill(store.cardChipBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: "target")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(store.canvasBackgroundColor)
            }
            
            Spacer()
            
            // Top Right Action Buttons Group (Edit, Delete / Create)
            HStack(spacing: 8) {
                if store.budget.isActive && store.budget.amount > 0 {
                    // Edit Budget Button (44x44 Circle)
                    Button(action: {
                        HapticsManager.shared.trigger(.light)
                        isEditingExisting = true
                        showEditBudgetSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(store.cardChipBackground)
                                .frame(width: 44, height: 44)
                            Image(systemName: "pencil")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(store.cardChipText)
                        }
                    }
                    .buttonStyle(PressableSpringButtonStyle())
                    
                    // Delete Budget Button (44x44 Circle)
                    Button(action: {
                        HapticsManager.shared.trigger(.medium)
                        showDeleteConfirmation = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(store.cardChipBackground)
                                .frame(width: 44, height: 44)
                            Image(systemName: "trash.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(SpendyColors.expenseRed)
                        }
                    }
                    .buttonStyle(PressableSpringButtonStyle())
                    .popover(isPresented: $showDeleteConfirmation, arrowEdge: .top) {
                        deleteConfirmationPopover
                            .presentationCompactAdaptation(.popover)
                    }
                } else {
                    // Create Budget Button (44x44 Circle)
                    Button(action: {
                        HapticsManager.shared.trigger(.medium)
                        isEditingExisting = false
                        showEditBudgetSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(store.cardChipBackground)
                                .frame(width: 44, height: 44)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(store.cardChipText)
                        }
                    }
                    .buttonStyle(PressableSpringButtonStyle())
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(store.cardBackgroundColor)
                .overlay(
                    Capsule().stroke(store.cardBorderColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 3)
        }
    }
    
    // MARK: - 2. Main Centerpiece Sheet Card
    private var centerpieceWhiteCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Row inside Card: Title + Date Range Pill
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Budget")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(store.cardTextPrimary)
                }
                
                Spacer()
                
                Text(cycleDateRangeString)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(store.canvasBackgroundColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(store.cardChipBackground))
            }
            
            Divider()
                .overlay(store.cardDividerColor)
            
            if !store.budget.isActive || store.budget.amount <= 0 {
                // Empty State View
                emptyStateView
            } else {
                // Active Budget Content
                activeBudgetContent
            }
        }
        .padding(20)
        .padding(.bottom, 100) // Full clearance for bottom GlassTabBar
        .background {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(store.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .stroke(store.cardBorderColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 24, y: 8)
        }
    }
    
    // MARK: - Delete Confirmation Popover (Anchored to Delete Button)
    private var deleteConfirmationPopover: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Delete Budget?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Text("This will remove your current budget limit.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 8) {
                Button(action: {
                    HapticsManager.shared.trigger(.medium)
                    store.deleteBudget()
                    showDeleteConfirmation = false
                }) {
                    Text("Delete Budget")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(SpendyColors.expenseRed, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    showDeleteConfirmation = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(SpendyColors.separator, in: RoundedRectangle(cornerRadius: 12))
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
                    .foregroundStyle(Color(uiColor: .dynamic(light: .white, dark: .black)))
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
                        .font(.system(size: 24, weight: .heavy, design: .default).monospacedDigit())
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Spacer(minLength: 12)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Capsule()
                            .fill(isExceededToday ? SpendyColors.warningOrange : Color(hex: "#30D158"))
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
                        .font(.system(size: 24, weight: .heavy, design: .default).monospacedDigit())
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Spacer(minLength: 12)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Available to allocate:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Text(target.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .font(.system(size: 13, weight: .bold, design: .default).monospacedDigit())
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

// MARK: - Pressable Spring Button Style
private struct PressableSpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.70), value: configuration.isPressed)
    }
}
