//
//  BudgetView.swift
//  Spendy
//
//  Native iOS Budget Tracking and Category Limits Screen
//

import SwiftUI

struct BudgetView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var showEditMonthlyBudget: Bool = false
    @State private var editingBudgetAmount: String = ""
    @State private var editingCategoryId: String? = nil
    @State private var editingCategoryLimit: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // Header
                        HStack {
                            Text("Budget")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        // Monthly Hero Budget Card
                        monthlyBudgetCard
                        
                        // Category Budget Limits Section
                        categoryBudgetsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditMonthlyBudget) {
                editMonthlyBudgetSheet
            }
            .sheet(isPresented: Binding(
                get: { editingCategoryId != nil },
                set: { if !$0 { editingCategoryId = nil } }
            )) {
                editCategoryBudgetSheet
            }
        }
    }
    
    // MARK: - Monthly Budget Hero Card
    private var monthlyBudgetCard: some View {
        let limit = store.budget.monthlyBudget
        let spent = store.monthlyExpense
        let remaining = max(0, limit - spent)
        let progress = limit > 0 ? min(1.0, spent / limit) : 0.0
        
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())
        let totalDays = range?.count ?? 30
        let currentDay = calendar.component(.day, from: Date())
        let daysLeft = max(1, totalDays - currentDay + 1)
        let dailyAllowance = remaining / Double(daysLeft)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MONTHLY SPEND LIMIT")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.white.opacity(0.45))
                    
                    Text(remaining.formattedCurrency(symbol: store.currencySymbol))
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Remaining of \(limit.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
                
                Spacer()
                
                Button(action: {
                    editingBudgetAmount = String(format: "%.0f", store.budget.monthlyBudget)
                    HapticsManager.shared.trigger(.light)
                    showEditMonthlyBudget = true
                }) {
                    Text("Edit")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.primaryBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }
            }
            
            // Progress Bar
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(progress > 0.9 ? SpendyColors.expenseRed : SpendyColors.incomeGreen)
                        .frame(width: proxy.size.width * CGFloat(progress), height: 8)
                }
            }
            .frame(height: 8)
            
            Divider().overlay(Color.white.opacity(0.06))
            
            // Daily Allowance Footnote
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: SFIcons.calendar)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(daysLeft) days remaining")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Text("\(dailyAllowance.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) / day safe")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.incomeGreen)
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
    
    // MARK: - Category Budgets Section
    private var categoryBudgetsSection: some View {
        let expenseCategories = store.categories.filter { $0.type == .expense }
        let currentTxs = store.currentMonthTransactions.filter { $0.type == .expense }
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CATEGORY BUDGETS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                ForEach(expenseCategories) { cat in
                    let limit = store.budget.categoryBudgets[cat.id] ?? 0.0
                    let spent = currentTxs.filter { $0.categoryId == cat.id }.reduce(0.0) { $0 + $1.amount }
                    let progress = limit > 0 ? min(1.0, spent / limit) : 0.0
                    
                    Button(action: {
                        editingCategoryId = cat.id
                        editingCategoryLimit = String(format: "%.0f", limit)
                        HapticsManager.shared.trigger(.light)
                    }) {
                        VStack(spacing: 10) {
                            HStack(spacing: 12) {
                                CategoryIconBadge(
                                    sfSymbol: cat.sfSymbol,
                                    tintColor: cat.color,
                                    size: .small
                                )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cat.label)
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundStyle(.white)
                                    
                                    if limit > 0 {
                                        Text("\(spent.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) of \(limit.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.45))
                                    } else {
                                        Text("No limit set")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.35))
                                    }
                                }
                                
                                Spacer()
                                
                                if limit > 0 {
                                    Text(String(format: "%.0f%%", progress * 100))
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(progress > 0.9 ? SpendyColors.expenseRed : .white)
                                } else {
                                    Image(systemName: SFIcons.edit)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                            }
                            
                            if limit > 0 {
                                GeometryReader { proxy in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.06))
                                            .frame(height: 5)
                                        
                                        Capsule()
                                            .fill(progress > 0.9 ? SpendyColors.expenseRed : cat.color)
                                            .frame(width: proxy.size.width * CGFloat(progress), height: 5)
                                    }
                                }
                                .frame(height: 5)
                            }
                        }
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SpendyColors.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Edit Monthly Budget Sheet
    private var editMonthlyBudgetSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Set Monthly Budget")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    
                    TextField("Amount (\(store.currencySymbol))", text: $editingBudgetAmount)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(SpendyColors.cardBackground)
                        }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditMonthlyBudget = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amt = Double(editingBudgetAmount), amt > 0 {
                            store.updateMonthlyBudget(amt)
                        }
                        showEditMonthlyBudget = false
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
    }
    
    // MARK: - Edit Category Budget Sheet
    private var editCategoryBudgetSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let catId = editingCategoryId {
                        let cat = store.category(for: catId)
                        Text("Budget for \(cat.label)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    TextField("Limit (\(store.currencySymbol))", text: $editingCategoryLimit)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(SpendyColors.cardBackground)
                        }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingCategoryId = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let catId = editingCategoryId, let amt = Double(editingCategoryLimit) {
                            store.updateCategoryBudget(categoryId: catId, limit: amt)
                        }
                        editingCategoryId = nil
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
    }
}
