//
//  DashboardView.swift
//  Spendy
//
//  Main Home Dashboard with Monochrome Styling, Dropdown Account Selector, Insights Carousel, and Full React Parity
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
        InsightsEngine.getDashboardInsights(
            transactions: store.transactions,
            budget: store.budget,
            categories: store.categories,
            subscriptions: store.subscriptions,
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
    
    // MARK: - 1. Top Header Bar (Account Toggle on Left, Widgets on Right)
    private var headerBar: some View {
        HStack(alignment: .center) {
            // Profile / Account Button on Top-Left (Opens Settings)
            Button(action: {
                HapticsManager.shared.trigger(.light)
                showSettings = true
            }) {
                ZStack {
                    Circle()
                        .fill(SpendyColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, y: 2)
                    
                    Text(store.userName.prefix(1).uppercased().isEmpty ? "P" : String(store.userName.prefix(1).uppercased()))
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(SpendyColors.appBackground)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Account and Settings")
            
            Spacer()
            
            // Top Right Widget Action Buttons
            HStack(spacing: 10) {
                // Currency Converter Button
                GlassCircleButton(
                    icon: "arrow.left.arrow.right",
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: "Currency converter"
                ) {
                    showCurrencyConverter = true
                }
                
                // Subscription Widget Button
                GlassCircleButton(
                    icon: "calendar.badge.clock",
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: "Subscriptions"
                ) {
                    showSubscriptions = true
                }
                
                // Receipt Printer Button
                GlassCircleButton(
                    icon: "printer.fill",
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: "Monthly receipt printer"
                ) {
                    showReceiptPrinter = true
                }
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
                HStack(spacing: 7) {
                    Image(systemName: selectedAccountSymbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.primaryBlue)
                    
                    Text(selectedAccountLabel)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .padding(.horizontal, 14)
                .frame(height: 38)
                .nativeLiquidGlassCapsule(isInteractive: true)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Privacy Eye Toggle Button
            GlassCircleButton(
                icon: hideBalance ? "eye.slash.fill" : "eye.fill",
                size: 38,
                iconSize: 14,
                foregroundColor: SpendyColors.textSecondary,
                accessibilityLabel: hideBalance ? "Show balance" : "Hide balance"
            ) {
                withAnimation(.spring(response: 0.25)) {
                    hideBalance.toggle()
                }
            }
        }
    }
    
    // MARK: - 3. Hero Balance Card
    private var heroBalanceCard: some View {
        VStack(spacing: 16) {
            // Balance Header & Privacy Mask
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedAccountId == "all" ? "TOTAL NET WORTH" : "ACCOUNT BALANCE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(SpendyColors.textTertiary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if hideBalance {
                        Text("\(store.currencySymbol) ••••••")
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundStyle(SpendyColors.textPrimary)
                    } else {
                        Text(displayedBalance.formattedCurrency(symbol: store.currencySymbol))
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                    
                    Spacer()
                }
            }
            
            // Monthly Income & Expense Badges
            HStack(spacing: 12) {
                // Income Badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(SpendyColors.textPrimary.opacity(0.12))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "arrow.down.left")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                        }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Income")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Text(hideBalance ? "••••" : "+\(store.monthlyIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(SpendyColors.textPrimary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                
                // Expense Badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(SpendyColors.textPrimary.opacity(0.12))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                        }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Expenses")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Text(hideBalance ? "••••" : "-\(store.monthlyExpense.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(SpendyColors.textPrimary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - 4. Smart Insights Horizontal Carousel
    private var smartInsightsCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SMART INSIGHTS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(SpendyColors.textTertiary)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(insights) { item in
                        VStack(alignment: .leading, spacing: 0) {
                            // Eyebrow Header
                            Text(item.title.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.0)
                                .foregroundStyle(SpendyColors.textSecondary)
                                .padding(.bottom, 4)
                            
                            // Value
                            Text(item.value)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(item.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Spacer(minLength: 12)
                            
                            // Footer (Icon + Description)
                            HStack(alignment: .center, spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(item.color.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                        .shadow(color: item.color.opacity(0.2), radius: 10, x: 0, y: 0)
                                    
                                    Image(systemName: item.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(item.color)
                                }
                                
                                Text(item.desc)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(SpendyColors.textSecondary)
                                    .lineSpacing(2)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(14)
                        .frame(width: 180, height: 165, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(SpendyColors.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(SpendyColors.separator, lineWidth: 0.8)
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
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(SpendyColors.textTertiary)
                
                Spacer()
                
                if !displayedTransactions.isEmpty {
                    Text("\(displayedTransactions.count) items")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
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
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            inspectingTransaction = tx
        }) {
            HStack(spacing: 14) {
                // Category Icon Avatar (Monochrome)
                ZStack {
                    Circle()
                        .fill(cat?.colorHex == "#18181B" ? Color.black : Color(uiColor: .dynamic(light: UIColor(white: 0.85, alpha: 1), dark: UIColor(white: 0.2, alpha: 1))))
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: cat?.sfSymbol ?? "tag.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(cat?.colorHex == "#18181B" ? Color.white : SpendyColors.textPrimary)
                }
                
                // Title & Account
                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.title.isEmpty ? (cat?.label ?? "Transaction") : tx.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text("\(acc?.label ?? "Cash") • \(tx.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                
                Spacer()
                
                // Formatted Amount
                Text(formattedRowAmount(tx))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
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
    
    private var emptyRecentActivityView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.top, 14)
            
            Text("No transactions logged yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Text("Tap the + button below to add your first expense or income.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
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
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
}
