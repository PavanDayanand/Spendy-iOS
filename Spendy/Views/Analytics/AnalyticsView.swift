//
//  AnalyticsView.swift
//  Spendy
//
//  Native iOS Financial Analytics & Spending Breakdown
//

import SwiftUI

enum AnalyticsTimeRange: String, CaseIterable, Identifiable {
    case thisMonth = "This Month"
    case allTime = "All Time"
    
    var id: String { rawValue }
}

struct AnalyticsView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var selectedRange: AnalyticsTimeRange = .thisMonth
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // Top Header & Period Selector
                        headerSection
                        
                        // Summary Stats Grid
                        statsGrid
                        
                        // Category Spending Breakdown
                        categoryBreakdownSection
                        
                        // Account Allocation
                        accountAllocationSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Analytics")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.top, 8)
            
            GlassSegmentedPicker(
                selection: $selectedRange,
                items: AnalyticsTimeRange.allCases,
                titleFor: { $0.rawValue },
                activeTint: SpendyColors.primaryBlue
            )
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        let totalIncome = selectedRange == .thisMonth ? store.monthlyIncome : store.transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let totalExpense = selectedRange == .thisMonth ? store.monthlyExpense : store.transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let netSavings = totalIncome - totalExpense
        let savingsRate = totalIncome > 0 ? max(0, min(100, (netSavings / totalIncome) * 100)) : 0.0
        
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Total Income Card
                VStack(alignment: .leading, spacing: 6) {
                    Text("TOTAL INCOME")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.white.opacity(0.45))
                    
                    Text(totalIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(SpendyColors.incomeGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        }
                }
                
                // Total Expense Card
                VStack(alignment: .leading, spacing: 6) {
                    Text("TOTAL SPENT")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.white.opacity(0.45))
                    
                    Text(totalExpense.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        }
                }
            }
            
            // Savings Rate Banner Card
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SAVINGS RATE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.white.opacity(0.45))
                    
                    Text(String(format: "%.0f%% of income saved", savingsRate))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text(netSavings.formattedSignedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(netSavings >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - Category Breakdown Section
    private var categoryBreakdownSection: some View {
        let activeTransactions = selectedRange == .thisMonth ? store.currentMonthTransactions : store.transactions
        let expenseTransactions = activeTransactions.filter { $0.type == .expense }
        let totalExpense = expenseTransactions.reduce(0.0) { $0 + $1.amount }
        
        let grouped = Dictionary(grouping: expenseTransactions, by: { $0.categoryId })
        let categoryTotals = grouped.map { (catId, txs) -> (category: Category, total: Double, percentage: Double) in
            let total = txs.reduce(0.0) { $0 + $1.amount }
            let pct = totalExpense > 0 ? (total / totalExpense) * 100 : 0.0
            return (category: store.category(for: catId), total: total, percentage: pct)
        }.sorted { $0.total > $1.total }
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SPENDING BY CATEGORY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            if categoryTotals.isEmpty {
                Text("No expense transactions in this period.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(SpendyColors.cardBackground)
                    }
            } else {
                VStack(spacing: 8) {
                    ForEach(categoryTotals, id: \.category.id) { item in
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                CategoryIconBadge(
                                    sfSymbol: item.category.sfSymbol,
                                    tintColor: item.category.color,
                                    size: .small
                                )
                                
                                Text(item.category.label)
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text(item.total.formattedCurrency(symbol: store.currencySymbol))
                                        .font(.system(.body, design: .rounded, weight: .bold))
                                        .foregroundStyle(.white)
                                    
                                    Text(String(format: "%.1f%%", item.percentage))
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                            }
                            
                            // Visual Proportion Bar
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.06))
                                        .frame(height: 6)
                                    
                                    Capsule()
                                        .fill(item.category.color)
                                        .frame(width: proxy.size.width * CGFloat(min(1.0, item.percentage / 100.0)), height: 6)
                                }
                            }
                            .frame(height: 6)
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
                }
            }
        }
    }
    
    // MARK: - Account Allocation Section
    private var accountAllocationSection: some View {
        let totalNet = max(1.0, store.totalBalance)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACCOUNT BALANCES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(store.accounts) { acc in
                    let balance = store.balance(for: acc.id)
                    let pct = max(0, min(100, (balance / totalNet) * 100))
                    
                    HStack(spacing: 12) {
                        CategoryIconBadge(
                            sfSymbol: acc.sfSymbol,
                            tintColor: acc.color,
                            size: .small
                        )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(acc.label)
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text(String(format: "%.0f%% of total wealth", pct))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        
                        Spacer()
                        
                        Text(balance.formattedCurrency(symbol: store.currencySymbol))
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
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
            }
        }
    }
}
