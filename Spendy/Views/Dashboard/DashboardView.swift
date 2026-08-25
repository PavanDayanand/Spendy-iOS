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
    var categoryId: String? = nil
    var family: String? = nil
}

// MARK: - Mini Sparkline Component for Accounts Card (Image 1)
struct AccountsMiniSparkline: View {
    var isPositive: Bool = true
    
    var effectiveColor: Color {
        isPositive ? Color(hex: "#30D158") : Color(hex: "#FF3B30")
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let col = effectiveColor
            
            ZStack(alignment: .bottomTrailing) {
                // Gradient Fill Under Sparkline
                Path { path in
                    if isPositive {
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
                    } else {
                        // Downward trend curve (drop to red)
                        path.move(to: CGPoint(x: 0, y: h * 0.1))
                        path.addCurve(
                            to: CGPoint(x: w * 0.6, y: h * 0.15),
                            control1: CGPoint(x: w * 0.2, y: h * 0.1),
                            control2: CGPoint(x: w * 0.4, y: h * 0.12)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: w, y: h * 0.85),
                            control: CGPoint(x: w * 0.8, y: h * 0.3)
                        )
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [col.opacity(0.35), col.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Sparkline Stroke Line
                Path { path in
                    if isPositive {
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
                    } else {
                        // Downward stroke path
                        path.move(to: CGPoint(x: 0, y: h * 0.1))
                        path.addCurve(
                            to: CGPoint(x: w * 0.6, y: h * 0.15),
                            control1: CGPoint(x: w * 0.2, y: h * 0.1),
                            control2: CGPoint(x: w * 0.4, y: h * 0.12)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: w, y: h * 0.85),
                            control: CGPoint(x: w * 0.8, y: h * 0.3)
                        )
                    }
                }
                .stroke(col, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .shadow(color: col.opacity(0.3), radius: 3, y: 1)
            }
        }
    }
}

struct DashboardView: View {
    @Environment(ExpenseStore.self) private var store
    @Binding var showAddTransaction: Bool
    var selectedTab: Binding<AppTab>? = nil
    
    // Sheets State
    @State private var showSettings: Bool = false
    @State private var settingsInitialDestination: SettingsDestination? = nil
    @State private var showCurrencyConverter: Bool = false
    @State private var showSubscriptions: Bool = false
    @State private var showFullSubscriptionSheet: Bool = false
    @State private var showReceiptPrinter: Bool = false
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var lastInspectedTransaction: Transaction? = nil
    @State private var selectedCategoryForSheet: Category? = nil
    @State private var selectedAccountForSheet: Account? = nil
    @State private var showAccountsHub: Bool = false
    
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
                subtitle: "\(data.count) \(data.count == 1 ? "expense" : "expenses")",
                categoryId: cat.id,
                family: "category"
            )
        }.sorted(by: { $0.id > $1.id })
    }
    
    // All Dashboard Smart Insight Cards (Driven by InsightsEngine + Category Spending + Real Dynamic Actions)
    private var allDashboardInsightCards: [InsightCardViewModel] {
        let engineItems = insightsEngineItems
        let catCards = categorySpendingCards
        
        var results: [InsightCardViewModel] = []
        
        // 1. Add top engine items first
        for item in engineItems {
            results.append(
                InsightCardViewModel(
                    id: item.id,
                    title: item.title,
                    icon: item.icon,
                    color: item.color,
                    value: item.value,
                    subtitle: item.desc,
                    categoryId: item.categoryId,
                    family: item.family
                )
            )
        }
        
        // 2. Add category spending cards
        for catCard in catCards {
            if results.count >= 6 { break }
            if !results.contains(where: { $0.id == catCard.id }) {
                results.append(catCard)
            }
        }
        
        // 3. Add Safe Daily Pacing Card if budget is active
        if store.budget.isActive && store.budgetTargetAmount(for: store.budget.period) > 0 {
            if !results.contains(where: { $0.id == "safe_daily" }) {
                results.append(
                    InsightCardViewModel(
                        id: "safe_daily",
                        title: "Safe Daily",
                        icon: "shield.lefthalf.filled",
                        color: Color(hex: "#30D158"),
                        value: hideBalance ? "••••" : store.safeDailyAllowance.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                        subtitle: "\(store.budgetDaysLeft) days remaining in cycle",
                        family: "budget"
                    )
                )
            }
        } else {
            // Prompt user to set a budget
            if !results.contains(where: { $0.id == "set_budget" }) {
                results.append(
                    InsightCardViewModel(
                        id: "set_budget",
                        title: "Budget Planner",
                        icon: "target",
                        color: SpendyColors.primaryBlue,
                        value: "Set Limit",
                        subtitle: "Plan your monthly budget & safe-to-spend allowance",
                        family: "budget"
                    )
                )
            }
        }
        
        // 4. If user has active recurring subscriptions
        if !upcomingExpenseSubs.isEmpty && !results.contains(where: { $0.id == "upcoming_subs" }) {
            let subTotal = upcomingExpenseSubs.reduce(0) { $0 + $1.amount }
            results.append(
                InsightCardViewModel(
                    id: "upcoming_subs",
                    title: "Recurring Bills",
                    icon: "calendar.badge.clock",
                    color: Color(hex: "#FF9500"),
                    value: hideBalance ? "••••" : subTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                    subtitle: "\(upcomingExpenseSubs.count) subscriptions due this billing cycle",
                    family: "subscription"
                )
            )
        }
        
        // 5. If user has fewer than 5 transactions, encourage logging to unlock full AI predictions
        if store.transactions.count < 5 && !results.contains(where: { $0.id == "unlock_ai" }) {
            let remainingToLog = max(1, 5 - store.transactions.count)
            results.append(
                InsightCardViewModel(
                    id: "unlock_ai",
                    title: "AI Forecasts",
                    icon: "sparkles",
                    color: Color(hex: "#BF5AF2"),
                    value: "Log 5 Expenses",
                    subtitle: "Log \(remainingToLog) more \(remainingToLog == 1 ? "expense" : "expenses") to unlock category trend predictions",
                    family: "onboarding"
                )
            )
        }
        
        return results
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Top Header Bar (Profile Badge + Widget Action Buttons)
                        headerBar
                            .padding(.top, 8)
                        
                        // 2. Account Selector Dropdown Menu Chip & Privacy Eye
                        accountDropdownSelector
                        
                        // 3. Hero Balance Uncarded & Borderless Line Graph (directly on background!)
                        heroBalanceUncarded
                        
                        // 4. Budget Health & Pacing Card (Placed directly under hero graph)
                        budgetHealthCard
                        
                        // 5. Compact Expenses & Income Summary Row (Real Monthly Spending vs Income)
                        compactExpensesAndIncomeRow
                        
                        // 6. Smart Insights Cards Section (Horizontal Scroll 5+ Rich Cards)
                        smartInsightsSection
                        
                        // 7. Accounts Unified Card Section
                        accountsUnifiedCardSection
                        
                        // 8. Recent Transactions Card Section
                        recentTransactionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom floating tab bar
                }
                
                if showCurrencyConverter {
                    // Dimmed background overlay that dismisses on tap
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            // Resign keyboard focus globally before dismissing
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                                showCurrencyConverter = false
                            }
                        }
                    
                    // Floating drawer from top
                    GeometryReader { geometry in
                        VStack {
                            FloatingCurrencyConverterView(isPresented: $showCurrencyConverter)
                                .padding(.horizontal, 16)
                                .padding(.top, geometry.safeAreaInsets.top + 60)
                            Spacer()
                        }
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom) // Prevents layout recalculations & double-animation lag when keyboard opens/closes
                    .ignoresSafeArea(edges: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                }
                
                if showSubscriptions {
                    // Dimmed background overlay that dismisses on tap
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                                showSubscriptions = false
                            }
                        }
                    
                    // Floating drawer from top
                    GeometryReader { geometry in
                        VStack {
                            FloatingSubscriptionsView(isPresented: $showSubscriptions)
                                .padding(.horizontal, 16)
                                .padding(.top, geometry.safeAreaInsets.top + 60)
                            Spacer()
                        }
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .ignoresSafeArea(edges: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings, onDismiss: {
                settingsInitialDestination = nil
            }) {
                SettingsView(initialDestination: settingsInitialDestination)
            }
            .sheet(isPresented: $showReceiptPrinter) {
                ReceiptPrinterSheet()
            }
            .sheet(isPresented: $showFullSubscriptionSheet) {
                SubscriptionWidgetSheet()
            }
            .sheet(item: $inspectingTransaction) { tx in
                TransactionDetailSheet(transaction: tx) { txToEdit in
                    lastInspectedTransaction = tx
                    inspectingTransaction = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        editingTransaction = txToEdit
                    }
                }
            }
            .sheet(item: $editingTransaction, onDismiss: {
                // Re-open detail sheet with fresh (possibly edited) transaction data
                if let last = lastInspectedTransaction {
                    let fresh = store.transactions.first(where: { $0.id == last.id }) ?? last
                    lastInspectedTransaction = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        inspectingTransaction = fresh
                    }
                }
            }) { tx in
                AddTransactionView(transactionToEdit: tx)
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
            .navigationDestination(item: $selectedAccountForSheet) { account in
                AccountAnalyticsSheet(
                    account: account,
                    topControlsNamespace: topControlsNamespace
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedAccountForSheet = nil
                    }
                }
            }
            .navigationDestination(isPresented: $showAccountsHub) {
                AccountsSettingsView()
            }
        }
    }
    
    // MARK: - 1. Top Header Bar (Profile Button on Left, 3 Widget Buttons on Right)
    private var headerBar: some View {
        HStack(alignment: .center) {
            // Profile / Account Button on Top-Left (Opens Settings)
            Button(action: {
                HapticsManager.shared.trigger(.light)
                settingsInitialDestination = nil
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
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        showCurrencyConverter = true
                    }
                }
                
                // Subscription Widget Button
                GlassCircleButton(
                    icon: "calendar.badge.clock",
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: "Subscriptions"
                ) {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        showSubscriptions = true
                    }
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
            // Balance Header & Amount directly on screen background with subtle ambient radial glow
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
    
    // MARK: - 4. Budget Health & Pacing Card (Clean Spendy Design)
    private var budgetHealthCard: some View {
        let budget = store.budget
        let target = store.budgetTargetAmount(for: budget.period)
        let spent = store.budgetCycleExpenses
        let isConfigured = budget.isActive && target > 0
        let percentSpent = isConfigured ? (spent / target) : 0.0
        let isExceeded = spent > target && isConfigured
        let remaining = max(0, target - spent)
        let overAmount = max(0, spent - target)
        
        // Dynamic Status Color
        let statusColor: Color = {
            if !isConfigured { return SpendyColors.primaryBlue }
            if isExceeded { return Color(hex: "#FF453A") }
            if percentSpent >= 0.85 { return Color(hex: "#FF9F0A") }
            return Color(hex: "#30D158")
        }()
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            if let selectedTab = selectedTab {
                selectedTab.wrappedValue = .budget
            }
        }) {
            HStack(spacing: 14) {
                // Circular Progress Gauge Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 3.8)
                        .frame(width: 44, height: 44)
                    
                    if isConfigured {
                        Circle()
                            .trim(from: 0.0, to: min(1.0, CGFloat(percentSpent)))
                            .stroke(
                                statusColor,
                                style: StrokeStyle(lineWidth: 3.8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 44, height: 44)
                            .shadow(color: statusColor.opacity(0.4), radius: 4)
                        
                        Text("\(Int(min(999, percentSpent * 100)))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    } else {
                        Image(systemName: "target")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(SpendyColors.primaryBlue)
                    }
                }
                
                // Text Column: Status & Allowance
                VStack(alignment: .leading, spacing: 3) {
                    if !isConfigured {
                        Text("Set Monthly Budget")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        Text("Track spending pacing and daily allowance")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                            .lineLimit(1)
                    } else if isExceeded {
                        Text("Budget exceeded by \(hideBalance ? "••••" : overAmount.formattedCurrency(symbol: store.currencySymbol))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(hex: "#FF453A"))
                        
                        Text("Spent \(hideBalance ? "••••" : spent.formattedCurrency(symbol: store.currencySymbol)) of \(target.formattedCurrency(symbol: store.currencySymbol)) limit")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .lineLimit(1)
                    } else {
                        Text("\(hideBalance ? "••••" : remaining.formattedCurrency(symbol: store.currencySymbol)) remaining")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        let daysLeft = store.budgetDaysLeft
                        let dailySafe = store.safeDailyAllowance
                        Text("Safe pace: \(hideBalance ? "••••" : dailySafe.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day · \(daysLeft)d left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(isExceeded ? Color(hex: "#FF453A").opacity(0.35) : SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(InsightSubCardButtonStyle())
    }
    
    // MARK: - Upcoming Expenses & Income Computations
    private var upcomingExpenseSubs: [Subscription] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)
        else { return [] }
        
        return store.subscriptions.filter { sub in
            guard sub.status == "active" || (!sub.isPaused && !sub.isCancelled) else { return false }
            let nextDue = sub.nextBillingDate
            return nextDue >= monthStart && nextDue <= endOfMonth
        }
    }
    
    private var currentMonthExpenseTxs: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return displayedTransactions.filter {
            $0.type == .expense &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
    }
    
    private var currentMonthExpenseTotal: Double {
        currentMonthExpenseTxs.reduce(0) { $0 + $1.amount }
    }
    
    private var expenseCategoryBadges: [(icon: String, color: Color)] {
        var totals: [String: Double] = [:]
        for tx in currentMonthExpenseTxs {
            totals[tx.categoryId, default: 0] += tx.amount
        }
        let sorted = totals.sorted(by: { $0.value > $1.value })
        return sorted.prefix(3).compactMap { (catId, _) in
            guard let cat = store.categories.first(where: { $0.id == catId }) else { return nil }
            return (cat.sfSymbol, Color(hex: cat.colorHex))
        }
    }
    
    private var currentMonthIncomeTxs: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return store.transactions.filter {
            $0.type == .income &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
    }
    
    // MARK: - 5. Compact Expenses & Income Summary Row (Balanced Real Spending vs Income)
    private var compactExpensesAndIncomeRow: some View {
        HStack(spacing: 10) {
            // Compact Expenses Card (Real Spent This Month)
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if let selectedTab = selectedTab {
                        selectedTab.wrappedValue = .analytics
                    }
                }
            }) {
                HStack(spacing: 10) {
                    let expenseBadges = expenseCategoryBadges
                    if !expenseBadges.isEmpty {
                        OverlappingBadgeCluster(
                            items: expenseBadges.prefix(3).map { info in
                                BadgeItem(icon: info.icon, color: info.color)
                            }
                        )
                    } else if !upcomingExpenseSubs.isEmpty {
                        OverlappingBadgeCluster(
                            items: upcomingExpenseSubs.prefix(3).map { sub in
                                BadgeItem(icon: sub.sfSymbol, color: sub.color)
                            }
                        )
                    } else {
                        SpendyIconBadge(
                            sfSymbol: "cart.fill",
                            color: Color(hex: "#FF453A"),
                            size: .small,
                            style: .circle
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expenses")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Text(hideBalance ? "••••" : currentMonthExpenseTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        
                        let subtitleText: String = {
                            if upcomingExpenseSubs.count > 0 {
                                return "\(currentMonthExpenseTxs.count) txs · \(upcomingExpenseSubs.count) due"
                            }
                            return "\(currentMonthExpenseTxs.count) this month"
                        }()
                        
                        Text(subtitleText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
            }
            .buttonStyle(InsightSubCardButtonStyle())
            
            // Compact Income Card
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if let selectedTab = selectedTab {
                        selectedTab.wrappedValue = .analytics
                    }
                }
            }) {
                HStack(spacing: 10) {
                    let incomeBadges = incomeIconInfos
                    if !incomeBadges.isEmpty {
                        OverlappingBadgeCluster(
                            items: incomeBadges.prefix(3).map { info in
                                BadgeItem(icon: info.icon, color: info.color)
                            }
                        )
                    } else {
                        SpendyIconBadge(
                            sfSymbol: "dollarsign.circle",
                            color: Color(hex: "#30D158"),
                            size: .small,
                            style: .circle
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Income")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        let incTotal = currentMonthIncomeTxs.reduce(0) { $0 + $1.amount }
                        Text(hideBalance ? "••••" : "+\(incTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(hex: "#30D158"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        
                        Text("\(currentMonthIncomeTxs.count) this month")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
            }
            .buttonStyle(InsightSubCardButtonStyle())
        }
    }
    
    // MARK: - 6. Smart Insights Section (Horizontal Scrollable 5+ Rich Cards)
    private var smartInsightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.primaryBlue)
                Text("Smart Insights")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(allDashboardInsightCards) { insight in
                        SharedInsightCard(
                            title: insight.title,
                            value: insight.value,
                            subtitle: insight.subtitle,
                            icon: insight.icon,
                            color: insight.color,
                            action: {
                                if let catId = insight.categoryId,
                                   let cat = store.categories.first(where: { $0.id == catId }) {
                                    selectedCategoryForSheet = cat
                                } else if insight.family == "budget" || insight.id == "set_budget" {
                                    if let selectedTab = selectedTab {
                                        selectedTab.wrappedValue = .budget
                                    }
                                } else if insight.family == "subscription" || insight.id == "upcoming_subs" {
                                    showFullSubscriptionSheet = true
                                } else if insight.family == "onboarding" || insight.id == "unlock_ai" {
                                    showAddTransaction = true
                                }
                            }
                        )
                        .frame(width: 175)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    /// Unique income category icons for the badge cluster
    private var incomeIconInfos: [(icon: String, color: Color)] {
        var seen = Set<String>()
        var results: [(icon: String, color: Color)] = []
        for tx in currentMonthIncomeTxs {
            guard !seen.contains(tx.categoryId) else { continue }
            seen.insert(tx.categoryId)
            let cat = store.categories.first(where: { $0.id == tx.categoryId })
            let icon = cat?.sfSymbol ?? "dollarsign.circle.fill"
            let color = Color(hex: cat?.colorHex ?? "#30D158")
            results.append((icon, color))
            if results.count >= 3 { break }
        }
        return results
    }
    
    // MARK: - 5. Accounts Unified Card Section
    private var accountsUnifiedCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Accounts Section Header (Opens Accounts Hub Full Page)
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                showAccountsHub = true
            }) {
                HStack {
                    Text("Accounts")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 14) {
                // Top Header Inside Accounts Card: Total & Sparkline (Opens Accounts Hub Full Page)
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    showAccountsHub = true
                }) {
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
                        
                        // Sparkline Trend Curve on top right of Total (Dynamic Green / Red based on Net Worth change)
                        let isPositiveTrend = store.netWorthChangePercentage >= 0
                        AccountsMiniSparkline(isPositive: isPositiveTrend)
                            .frame(width: 100, height: 36)
                    }
                }
                .buttonStyle(.plain)
                
                Divider()
                    .overlay(SpendyColors.separator)
                
                // Account Rows Inside Accounts Card (Opens Dedicated AccountAnalyticsSheet)
                VStack(spacing: 14) {
                    ForEach(store.accounts) { acc in
                        let bal = store.balance(for: acc.id)
                        
                        Button(action: {
                            HapticsManager.shared.trigger(.selection)
                            selectedAccountForSheet = acc
                        }) {
                            HStack(spacing: 14) {
                                // SpendyIconBadge using the account's actual icon and custom color
                                SpendyIconBadge(
                                    sfSymbol: acc.sfSymbol.isEmpty ? acc.type.defaultSymbol : acc.sfSymbol,
                                    color: acc.color,
                                    size: .medium,
                                    style: .circle
                                )
                                
                                Text(acc.label)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Spacer()
                                
                                Text(hideBalance ? "••••" : bal.formattedCurrency(symbol: store.currencySymbol))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                            }
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
    
    // MARK: - 6. Recent Transactions Section (Matching Image 1 Bottom Section without Review Banner)
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent transactions")
                .font(.system(size: 20, weight: .semibold))
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
        let subscription = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == tx.subscriptionId?.lowercased() })
        
        let iconSymbol = subscription?.sfSymbol ?? (cat?.sfSymbol ?? "cart.fill")
        let iconColor = subscription?.color ?? (cat?.color ?? Color(hex: "#34C759"))
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            inspectingTransaction = tx
        }) {
            HStack(spacing: 14) {
                // Circle Icon Avatar (Matching Category or Subscription Color)
                SpendyIconBadge(
                    sfSymbol: iconSymbol,
                    color: iconColor,
                    size: .medium,
                    style: .circle
                )
                
                // Title & Account Pill
                VStack(alignment: .leading, spacing: 4) {
                    Text(tx.title.isEmpty ? (cat?.label ?? "Expense") : tx.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    if let acc = acc {
                        HStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(acc.color)
                                    .frame(width: 14, height: 14)
                                Image(systemName: acc.sfSymbol.isEmpty ? acc.type.defaultSymbol : acc.sfSymbol)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
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

// MARK: - Insight Sub Card Button Style
private struct InsightSubCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
