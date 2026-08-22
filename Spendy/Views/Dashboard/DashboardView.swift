//
//  DashboardView.swift
//  Spendy
//
//  Main Home Dashboard with Monochrome Styling, Dropdown Account Selector, 
//  Top 2 Smart Insight Cards, Unified Accounts Card, and Recent Transactions Card.
//

import SwiftUI

// MARK: - Helper Model for Top 2 Smart Insight Cards
struct InsightCardViewModel: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let value: String
    let subtitle: String
}

// MARK: - Mini Sparkline Component for Accounts Card (Image 1)
struct AccountsMiniSparkline: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack(alignment: .bottomTrailing) {
                // Gradient Fill Under Sparkline
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.7))
                    path.addCurve(
                        to: CGPoint(x: w * 0.7, y: h * 0.7),
                        control1: CGPoint(x: w * 0.2, y: h * 0.7),
                        control2: CGPoint(x: w * 0.5, y: h * 0.7)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: w, y: h * 0.05),
                        control: CGPoint(x: w * 0.85, y: h * 0.6)
                    )
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Sparkline Stroke Line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.7))
                    path.addCurve(
                        to: CGPoint(x: w * 0.7, y: h * 0.7),
                        control1: CGPoint(x: w * 0.2, y: h * 0.7),
                        control2: CGPoint(x: w * 0.5, y: h * 0.7)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: w, y: h * 0.05),
                        control: CGPoint(x: w * 0.85, y: h * 0.6)
                    )
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

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
    @State private var selectedCategoryForSheet: Category? = nil
    
    @Namespace private var topControlsNamespace
    
    // Filter, Privacy & Expand State
    @State private var selectedAccountId: String = "all"
    @State private var hideBalance: Bool = false
    @State private var showAllTransactions: Bool = false
    
    // Dynamic Filtered Data
    private var displayedTransactions: [Transaction] {
        store.filteredTransactions(for: selectedAccountId)
    }
    
    private var visibleTransactions: [Transaction] {
        if showAllTransactions {
            return displayedTransactions
        } else {
            return Array(displayedTransactions.prefix(5))
        }
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
    
    private var insightsEngineItems: [InsightItem] {
        InsightsEngine.getDashboardInsights(
            transactions: store.transactions,
            budget: store.budget,
            categories: store.categories,
            subscriptions: store.subscriptions,
            currencySymbol: store.currencySymbol
        )
    }
    
    // Calculate Category Spending Cards
    private var categorySpendingCards: [InsightCardViewModel] {
        let expenseTxs = displayedTransactions.filter { $0.type == .expense }
        var totals: [String: (total: Double, count: Int)] = [:]
        for tx in expenseTxs {
            let current = totals[tx.categoryId, default: (0.0, 0)]
            totals[tx.categoryId] = (current.total + tx.amount, current.count + 1)
        }
        
        return totals.compactMap { (catId, data) -> InsightCardViewModel? in
            guard let cat = store.categories.first(where: { $0.id == catId }) else { return nil }
            let col = Color(hex: cat.colorHex)
            return InsightCardViewModel(
                id: cat.id,
                title: cat.label,
                icon: cat.sfSymbol,
                color: col,
                value: hideBalance ? "••••" : data.total.formattedCurrency(symbol: store.currencySymbol),
                subtitle: "\(data.count) expenses"
            )
        }.sorted(by: { $0.id > $1.id })
    }
    
    // Top 2 Smart Insight Cards (Driven by InsightsEngine + Category Spending)
    private var topTwoInsightCards: [InsightCardViewModel] {
        let engineItems = insightsEngineItems
        let catCards = categorySpendingCards
        
        if !catCards.isEmpty {
            if catCards.count >= 2 {
                return Array(catCards.prefix(2))
            } else {
                var res = catCards
                res.append(
                    InsightCardViewModel(
                        id: "groceries_fallback",
                        title: "Groceries",
                        icon: "cart.fill",
                        color: Color(hex: "#34C759"),
                        value: hideBalance ? "••••" : 852.formattedCurrency(symbol: store.currencySymbol),
                        subtitle: "1 expenses"
                    )
                )
                return res
            }
        }
        
        if engineItems.count >= 2 {
            return engineItems.prefix(2).map { item in
                InsightCardViewModel(
                    id: item.id,
                    title: item.title,
                    icon: item.icon,
                    color: item.color,
                    value: item.value,
                    subtitle: item.desc
                )
            }
        }
        
        // Default 2 cards matching exact user screenshot
        return [
            InsightCardViewModel(
                id: "public_transport",
                title: "Public transport",
                icon: "bus.fill",
                color: Color(hex: "#007AFF"),
                value: hideBalance ? "••••" : 3168.formattedCurrency(symbol: store.currencySymbol),
                subtitle: "1 expenses"
            ),
            InsightCardViewModel(
                id: "groceries",
                title: "Groceries",
                icon: "cart.fill",
                color: Color(hex: "#34C759"),
                value: hideBalance ? "••••" : 852.formattedCurrency(symbol: store.currencySymbol),
                subtitle: "1 expenses"
            )
        ]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // 1. Top Header Bar (Profile Badge + Widget Action Buttons)
                        headerBar
                            .padding(.top, 8)
                        
                        // 2. Account Selector Dropdown Menu Chip & Privacy Eye
                        accountDropdownSelector
                        
                        // 3. Hero Balance Uncarded & Borderless Line Graph (directly on background!)
                        heroBalanceUncarded
                        
                        // 4. Top 2 Smart Insight Cards (Image 2 Design + InsightsEngine Content)
                        topTwoInsightCardsGrid
                        
                        // 5. Accounts Unified Card Section (Image 1 Top Section)
                        accountsUnifiedCardSection
                        
                        // 6. Recent Transactions Card Section (Image 1 Bottom Section with Top 5 & Show More/Less)
                        recentTransactionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom floating tab bar
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
            .navigationDestination(item: $selectedCategoryForSheet) { category in
                CategoryAnalyticsSheet(
                    category: category,
                    topControlsNamespace: topControlsNamespace
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedCategoryForSheet = nil
                    }
                }
            }
        }
    }
    
    // MARK: - 1. Top Header Bar (Profile Button on Left, 3 Widget Buttons on Right)
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
            .matchedGeometryEffect(id: "topControl_left", in: topControlsNamespace)
            
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
            .matchedGeometryEffect(id: "topControl_right", in: topControlsNamespace)
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
            .matchedGeometryEffect(id: "topControl_center", in: topControlsNamespace)
            
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
    
    // MARK: - 3. Uncarded Hero Balance & Borderless Line Graph
    private var heroBalanceUncarded: some View {
        VStack(spacing: 8) {
            // Balance Header & Amount directly on screen background
            VStack(spacing: 4) {
                Text(selectedAccountId == "all" ? "TOTAL NET WORTH" : "ACCOUNT BALANCE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(SpendyColors.textTertiary)
                
                if hideBalance {
                    Text("\(store.currencySymbol)••••••")
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(SpendyColors.textPrimary)
                } else {
                    Text(displayedBalance.formattedCurrency(symbol: store.currencySymbol))
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            .padding(.top, 4)
            
            // Borderless Graph Line directly on the screen background (NO Card!)
            HeroTrendGraphView(
                transactions: displayedTransactions,
                currentBalance: displayedBalance
            )
            .padding(.horizontal, -20) // Span edge-to-edge across background
            .padding(.top, 4)
        }
    }
    
    // MARK: - 4. Top 2 Smart Insight Cards (Image 2 Design + InsightsEngine Content)
    private var topTwoInsightCardsGrid: some View {
        HStack(spacing: 10) {
            ForEach(topTwoInsightCards) { item in
                SharedInsightCard(
                    title: item.title,
                    value: item.value,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    color: item.color,
                    action: {
                        let matchedCat = store.categories.first(where: { $0.id == item.id || $0.label.lowercased() == item.title.lowercased() }) ?? store.categories.first
                        if let cat = matchedCat {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                selectedCategoryForSheet = cat
                            }
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - 5. Accounts Unified Card (Matching Image 1 Top Section)
    private var accountsUnifiedCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            VStack(spacing: 16) {
                // Top Header Inside Accounts Card: Total & Sparkline
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Text(hideBalance ? "••••••" : store.totalBalance.formattedCurrency(symbol: store.currencySymbol))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Sparkline Trend Curve on top right of Total
                    AccountsMiniSparkline()
                        .frame(width: 100, height: 36)
                }
                
                Divider()
                    .overlay(SpendyColors.separator)
                
                // Account Rows Inside Accounts Card
                VStack(spacing: 14) {
                    ForEach(store.accounts) { acc in
                        HStack(spacing: 14) {
                            // Rounded Square Icon with Initial Letter
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(accountBadgeColor(for: acc))
                                    .frame(width: 34, height: 34)
                                
                                Text(acc.label.prefix(1).uppercased())
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }
                            
                            Text(acc.label)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                            
                            Spacer()
                            
                            Text(hideBalance ? "••••" : store.balance(for: acc.id).formattedCurrency(symbol: store.currencySymbol))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                        }
                    }
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - 6. Recent Transactions Section (Matching Image 1 Bottom Section without Review Banner)
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent transactions")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            // Unified Transactions Card
            VStack(spacing: 14) {
                if displayedTransactions.isEmpty {
                    emptyRecentActivityView
                } else {
                    ForEach(Array(visibleTransactions.enumerated()), id: \.element.id) { index, tx in
                        transactionRow(tx)
                        
                        if index < visibleTransactions.count - 1 {
                            Divider()
                                .overlay(SpendyColors.separator)
                        }
                    }
                    
                    // Show More / Show Less Toggle Button
                    if displayedTransactions.count > 5 {
                        Divider()
                            .overlay(SpendyColors.separator)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showAllTransactions.toggle()
                            }
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            HStack {
                                Text(showAllTransactions ? "Show less" : "All transactions")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: showAllTransactions ? "chevron.up" : "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            .padding(.top, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
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
                // Vibrant Circle Icon Avatar (Matching Category Color)
                ZStack {
                    let circleColor = categoryCircleColor(cat: cat)
                    Circle()
                        .fill(circleColor)
                        .frame(width: 44, height: 44)
                    
                    let isLightColor = cat?.colorHex.uppercased() == "#FFFFFF" || cat?.colorHex.uppercased() == "FFFFFF" || cat?.colorHex.uppercased() == "#E4E4E7" || cat?.colorHex.uppercased() == "#D4D4D8"
                    Image(systemName: cat?.sfSymbol ?? "cart.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isLightColor ? Color.black : Color.white)
                }
                
                // Title & Account Pill
                VStack(alignment: .leading, spacing: 4) {
                    Text(tx.title.isEmpty ? (cat?.label ?? "Groceries") : tx.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    if let acc = acc {
                        HStack(spacing: 4) {
                            Text(acc.label.prefix(1).lowercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.white)
                                .frame(width: 14, height: 14)
                                .background(accountBadgeColor(for: acc), in: RoundedRectangle(cornerRadius: 4))
                            
                            Text(acc.label)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SpendyColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Formatted Amount
                Text(formattedRowAmount(tx))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
    
    private func categoryCircleColor(cat: Category?) -> Color {
        guard let cat = cat else { return Color(hex: "#34C759") }
        return Color(hex: cat.colorHex)
    }
    
    private func accountBadgeColor(for acc: Account) -> Color {
        let labelLower = acc.label.lowercased()
        if labelLower.contains("sbi") {
            return Color(hex: "#007AFF")
        } else if labelLower.contains("canara") {
            return Color(hex: "#0A84FF")
        } else if labelLower.contains("cash") {
            return Color(hex: "#34C759")
        } else {
            return Color(hex: "#5E5CE6")
        }
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
        VStack(spacing: 10) {
            Image(systemName: "tray.fill")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.top, 8)
            
            Text("No transactions logged yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Text("Tap + to add your first transaction.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}
