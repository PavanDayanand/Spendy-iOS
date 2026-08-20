//
//  DashboardView.swift
//  Spendy
//
//  Main Home Dashboard with Native Apple Liquid Glass, Dropdown Account Selector, Insights Carousel, and Full React Parity
//

import SwiftUI

struct DashboardView: View {
    @Environment(ExpenseStore.self) private var store
    @Binding var showAddTransaction: Bool
    
    // Sheets State
    @State private var showSettings: Bool = false
    @State private var showCurrencyConverter: Bool = false
    @State private var showSubscriptions: Bool = false
    @State private var showReceiptPrinter: Bool = false
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    
    // Filter & Privacy State
    @State private var selectedAccountId: String = "all"
    @State private var hideBalance: Bool = false
    
    // Dynamic Filtered Data
    private var displayedTransactions: [Transaction] {
        store.filteredTransactions(for: selectedAccountId)
    }
    
    private var displayedBalance: Double {
        store.filteredBalance(for: selectedAccountId)
    }
    
    private var selectedAccountLabel: String {
        if selectedAccountId == "all" { return "All Accounts" }
        return store.accounts.first(where: { $0.id == selectedAccountId })?.label ?? "Account"
    }
    
    private var selectedAccountSymbol: String {
        if selectedAccountId == "all" { return "wallet.pass.fill" }
        return store.accounts.first(where: { $0.id == selectedAccountId })?.sfSymbol ?? "creditcard.fill"
    }
    
    private var insights: [InsightItem] {
        InsightsEngine.generateInsights(
            transactions: store.transactions,
            categories: store.categories,
            budget: store.budget,
            currencySymbol: store.currencySymbol
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // 1. Top Header Bar (Logo + 4 Widget Buttons)
                        headerBar
                            .padding(.top, 8)
                        
                        // 2. Account Selector Dropdown Chip
                        accountDropdownSelector
                        
                        // 3. Hero Balance Card (Balance, Eye toggle, Income/Expense, Trend)
                        heroBalanceCard
                        
                        // 4. Smart Insights Carousel
                        if !insights.isEmpty {
                            smartInsightsCarousel
                        }
                        
                        // 5. Recent Activity Section
                        recentActivitySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom floating pill bar
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showCurrencyConverter) {
                CurrencyConverterSheet()
            }
            .sheet(isPresented: $showSubscriptions) {
                SubscriptionWidgetSheet()
            }
            .sheet(isPresented: $showReceiptPrinter) {
                ReceiptPrinterSheet()
            }
            .sheet(item: $inspectingTransaction) { tx in
                TransactionDetailSheet(transaction: tx) { txToEdit in
                    editingTransaction = txToEdit
                }
            }
            .sheet(item: $editingTransaction) { tx in
                AddTransactionView(transactionToEdit: tx)
            }
        }
    }
    
    // MARK: - 1. Top Header Bar (All 4 Buttons Visible)
    private var headerBar: some View {
        HStack(alignment: .center) {
            // Brand Logo & Title
            HStack(spacing: 10) {
                Image("SpendyLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Spendy")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Dashboard")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            
            Spacer()
            
            // Top 4 Widget Action Buttons
            HStack(spacing: 10) {
                // Receipt Printer Button
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showReceiptPrinter = true
                }) {
                    Image(systemName: "printer.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .nativeLiquidGlassCircle(isInteractive: true)
                }
                .buttonStyle(.plain)
                
                // Subscription Widget Button
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showSubscriptions = true
                }) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .nativeLiquidGlassCircle(isInteractive: true)
                }
                .buttonStyle(.plain)
                
                // Currency Converter Button
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showCurrencyConverter = true
                }) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .nativeLiquidGlassCircle(isInteractive: true)
                }
                .buttonStyle(.plain)
                
                // Profile Avatar Button (Opens Settings)
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showSettings = true
                }) {
                    ZStack {
                        Circle()
                            .fill(SpendyColors.primaryBlue)
                            .frame(width: 40, height: 40)
                            .shadow(color: SpendyColors.primaryBlue.opacity(0.4), radius: 6, y: 2)
                        
                        Text(store.userName.prefix(1).uppercased().isEmpty ? "P" : String(store.userName.prefix(1).uppercased()))
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - 2. Account Selector Dropdown Menu Chip
    private var accountDropdownSelector: some View {
        HStack {
            Menu {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) { selectedAccountId = "all" }
                    HapticsManager.shared.trigger(.selection)
                }) {
                    HStack {
                        Text("All Accounts")
                        if selectedAccountId == "all" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                ForEach(store.accounts) { acc in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { selectedAccountId = acc.id }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        HStack {
                            Text("\(acc.label) (\(store.balance(for: acc.id).formattedCurrency(symbol: store.currencySymbol)))")
                            if selectedAccountId == acc.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: selectedAccountSymbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.primaryBlue)
                    
                    Text(selectedAccountLabel)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .nativeLiquidGlassCapsule(isInteractive: true)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Privacy Eye Toggle Button
            Button(action: {
                withAnimation(.spring(response: 0.25)) {
                    hideBalance.toggle()
                }
                HapticsManager.shared.trigger(.light)
            }) {
                Image(systemName: hideBalance ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.70))
                    .frame(width: 36, height: 36)
                    .nativeLiquidGlassCircle(isInteractive: true)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 3. Hero Balance Card
    private var heroBalanceCard: some View {
        VStack(spacing: 16) {
            // Balance Header & Privacy Mask
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedAccountId == "all" ? "TOTAL NET WORTH" : "ACCOUNT BALANCE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.45))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if hideBalance {
                        Text("\(store.currencySymbol) ••••••")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Text(displayedBalance.formattedCurrency(symbol: store.currencySymbol))
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
            }
            
            // Monthly Income & Expense Badges
            HStack(spacing: 12) {
                // Income Badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(SpendyColors.incomeGreen.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "arrow.down.left")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SpendyColors.incomeGreen)
                        }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Income")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                        
                        Text(hideBalance ? "••••" : "+\(store.monthlyIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(SpendyColors.incomeGreen)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                
                // Expense Badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(SpendyColors.expenseRed.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SpendyColors.expenseRed)
                        }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Expenses")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                        
                        Text(hideBalance ? "••••" : "-\(store.monthlyExpense.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(SpendyColors.expenseRed)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - 4. Smart Insights Horizontal Carousel
    private var smartInsightsCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SMART INSIGHTS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.40))
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(insights) { item in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(item.tintColor.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: item.sfSymbol)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(item.tintColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text(item.description)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.60))
                                    .lineLimit(2)
                            }
                        }
                        .padding(14)
                        .frame(width: 280, alignment: .leading)
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
            }
        }
    }
    
    // MARK: - 5. Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT ACTIVITY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.40))
                
                Spacer()
                
                if !displayedTransactions.isEmpty {
                    Text("\(displayedTransactions.count) items")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.40))
                }
            }
            
            if displayedTransactions.isEmpty {
                emptyRecentActivityView
            } else {
                VStack(spacing: 8) {
                    ForEach(displayedTransactions) { tx in
                        transactionRow(tx)
                    }
                }
            }
        }
    }
    
    private func transactionRow(_ tx: Transaction) -> some View {
        let cat = store.categories.first(where: { $0.id == tx.categoryId })
        let acc = store.accounts.first(where: { $0.id == tx.accountId })
        let color = cat?.color ?? SpendyColors.primaryBlue
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            inspectingTransaction = tx
        }) {
            HStack(spacing: 14) {
                // Category Icon Avatar
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 42, height: 42)
                        .shadow(color: color.opacity(0.35), radius: 6, y: 2)
                    
                    Image(systemName: cat?.sfSymbol ?? "tag.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                // Title & Account
                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.title.isEmpty ? (cat?.label ?? "Transaction") : tx.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("\(acc?.label ?? "Cash") • \(tx.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.40))
                }
                
                Spacer()
                
                // Formatted Amount
                Text(formattedRowAmount(tx))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(rowAmountColor(tx))
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func formattedRowAmount(_ tx: Transaction) -> String {
        if hideBalance { return "••••" }
        let sym = store.currencySymbol
        switch tx.type {
        case .expense: return "-\(tx.amount.formattedCurrency(symbol: sym))"
        case .income: return "+\(tx.amount.formattedCurrency(symbol: sym))"
        case .transfer: return "\(tx.amount.formattedCurrency(symbol: sym))"
        }
    }
    
    private func rowAmountColor(_ tx: Transaction) -> Color {
        switch tx.type {
        case .expense: return .white
        case .income: return SpendyColors.incomeGreen
        case .transfer: return SpendyColors.transferBlue
        }
    }
    
    private var emptyRecentActivityView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.25))
                .padding(.top, 14)
            
            Text("No transactions logged yet")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Tap the + button below to add your first expense or income.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                }
        }
    }
}
