//
//  DashboardView.swift
//  Spendy
//
//  Main Home Dashboard with Native Apple Liquid Glass and Full React Feature Parity
//

import SwiftUI

struct DashboardView: View {
    @Environment(ExpenseStore.self) private var store
    @Binding var showAddTransaction: Bool
    
    @State private var showSettings: Bool = false
    @State private var transactionFilter: TransactionType? = nil
    @State private var selectedAccountFilterId: String? = nil
    @State private var inspectingTransaction: Transaction? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Top Header Bar with Profile Icon
                        headerBar
                            .padding(.top, 6)
                        
                        // Hero Net Worth & Monthly Balance Card
                        BalanceCardView()
                        
                        // Smart Spending Insight Banner (Parity with React insightsEngine)
                        smartInsightBanner
                        
                        // Accounts Carousel
                        accountsSection
                        
                        // Transaction Filter Pills
                        filterPillsRow
                        
                        // Recent Activity Section
                        recentActivitySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom floating bar
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $inspectingTransaction) { tx in
                TransactionDetailSheet(transaction: tx)
            }
        }
    }
    
    // MARK: - Top Header Bar
    private var headerBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Image("SpendyLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Spendy")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Dashboard")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Profile / Settings Button (Native Apple Liquid Glass)
            Button(action: {
                HapticsManager.shared.trigger(.light)
                showSettings = true
            }) {
                Image(systemName: SFIcons.profile)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
            }
            .buttonStyle(.glass)
        }
    }
    
    // MARK: - Smart Spending Insight Banner
    private var smartInsightBanner: some View {
        let savingsRate = store.monthlySavingsRate
        let daysLeft = max(1, 30 - Calendar.current.component(.day, from: Date()))
        let remaining = max(0, store.budget.monthlyBudget - store.monthlyExpense)
        let dailySafe = remaining / Double(daysLeft)
        
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SpendyColors.primaryBlue.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.primaryBlue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("SMART INSIGHT")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(SpendyColors.primaryBlue)
                
                if savingsRate > 0 {
                    Text("You've saved \(String(format: "%.0f%%", savingsRate)) of your income this month. Safe to spend \(dailySafe.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                } else {
                    Text("Budget remaining: \(remaining.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) across \(daysLeft) remaining days.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(SpendyColors.primaryBlue.opacity(0.2), lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Accounts Carousel
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ACCOUNTS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                
                Spacer()
                
                if selectedAccountFilterId != nil {
                    Button("Clear Filter") {
                        withAnimation(.spring(response: 0.25)) {
                            selectedAccountFilterId = nil
                        }
                        HapticsManager.shared.trigger(.selection)
                    }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.primaryBlue)
                }
            }
            .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.accounts) { account in
                        let balance = store.balance(for: account.id)
                        let isSelected = selectedAccountFilterId == account.id
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.25)) {
                                if selectedAccountFilterId == account.id {
                                    selectedAccountFilterId = nil
                                } else {
                                    selectedAccountFilterId = account.id
                                }
                            }
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    CategoryIconBadge(
                                        sfSymbol: account.sfSymbol,
                                        tintColor: account.color,
                                        size: .small
                                    )
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.label)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(isSelected ? .white : .white.opacity(0.65))
                                        .lineLimit(1)
                                    
                                    Text(balance.formattedCurrency(symbol: store.currencySymbol))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(width: 145)
                            .padding(14)
                            .background {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(isSelected ? account.color.opacity(0.2) : SpendyColors.cardBackground)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(isSelected ? account.color : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 0.8)
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    // MARK: - Filter Pills Row (Apple Native Liquid Glass)
    private var filterPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Filter
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        transactionFilter = nil
                    }
                    HapticsManager.shared.trigger(.selection)
                }) {
                    Text("All Activity")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(transactionFilter == nil ? .white : .white.opacity(0.6))
                        .nativeLiquidGlassPill(isSelected: transactionFilter == nil)
                }
                .buttonStyle(.plain)
                
                // Expense Filter
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        transactionFilter = .expense
                    }
                    HapticsManager.shared.trigger(.selection)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: SFIcons.expense)
                            .font(.system(size: 11, weight: .bold))
                        Text("Expenses")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(transactionFilter == .expense ? .white : .white.opacity(0.6))
                    .nativeLiquidGlassPill(isSelected: transactionFilter == .expense, tint: SpendyColors.expenseRed)
                }
                .buttonStyle(.plain)
                
                // Income Filter
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        transactionFilter = .income
                    }
                    HapticsManager.shared.trigger(.selection)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: SFIcons.income)
                            .font(.system(size: 11, weight: .bold))
                        Text("Income")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(transactionFilter == .income ? .white : .white.opacity(0.6))
                    .nativeLiquidGlassPill(isSelected: transactionFilter == .income, tint: SpendyColors.incomeGreen)
                }
                .buttonStyle(.plain)
                
                // Transfer Filter
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        transactionFilter = .transfer
                    }
                    HapticsManager.shared.trigger(.selection)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: SFIcons.transfer)
                            .font(.system(size: 11, weight: .bold))
                        Text("Transfers")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(transactionFilter == .transfer ? .white : .white.opacity(0.6))
                    .nativeLiquidGlassPill(isSelected: transactionFilter == .transfer, tint: SpendyColors.transferBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 2)
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(selectedAccountFilterId != nil ? "ACCOUNT TRANSACTIONS" : "RECENT TRANSACTIONS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                
                Spacer()
                
                Text("\(filteredTransactions.count) items")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 4)
            
            if filteredTransactions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: SFIcons.wallet)
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.white.opacity(0.3))
                    
                    Text("No transactions found")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredTransactions) { transaction in
                        Button(action: {
                            HapticsManager.shared.trigger(.light)
                            inspectingTransaction = transaction
                        }) {
                            TransactionRowView(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteTransaction(id: transaction.id)
                            } label: {
                                Label("Delete", systemImage: SFIcons.delete)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var filteredTransactions: [Transaction] {
        var list = store.recentTransactions
        if let accId = selectedAccountFilterId {
            list = list.filter { $0.accountId == accId || $0.toAccountId == accId }
        }
        if let filter = transactionFilter {
            list = list.filter { $0.type == filter }
        }
        return list
    }
}
