//
//  DashboardView.swift
//  Spendy
//
//  Main Home Dashboard with Monochrome Styling, Dropdown Account Selector, 
//  Top 2 Smart Insight Cards, Unified Accounts Card, and Recent Transactions Card.
//

import SwiftUI

// MARK: - Helper Model for Smart Insight Cards (Max 5 Clean Cards on Home Dashboard)
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

// MARK: - Trend Graph Point
struct SpendTrendPoint: Identifiable, Equatable {
    let id: Int
    let label: String
    let amount: Double
}

// MARK: - Time Filter Enum (D, W, M)
enum DashboardTimeFilter: String, CaseIterable, Identifiable {
    case day = "D"
    case week = "W"
    case month = "M"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        }
    }
}

// MARK: - Inline Hero Spend Trend Curve Graph (Catmull-Rom Smooth Curve)
struct HeroSpendTrendGraph: View {
    let points: [SpendTrendPoint]
    var currencySymbol: String = "$"
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let floatPoints = points.map { CGFloat($0.amount) }
                let count = floatPoints.count
                
                if count >= 3 {
                    let maxVal = max(0.001, floatPoints.max() ?? 1.0)
                    let coords: [CGPoint] = floatPoints.enumerated().map { index, val in
                        let x = (CGFloat(index) / CGFloat(count - 1)) * w
                        let norm = val / maxVal
                        let y = h - (norm * (h - 16) + 8)
                        return CGPoint(x: x, y: y)
                    }
                    
                    let histCount = max(2, count - 2)
                    let histCoords = Array(coords.prefix(histCount))
                    let predCoords = Array(coords.suffix(from: histCount - 1))
                    
                    ZStack {
                        // 1. White Area Gradient Shade Fill Underneath Full Curve
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: h))
                            path.addLine(to: coords[0])
                            for i in 1..<coords.count {
                                let prev = coords[i - 1]
                                let cur = coords[i]
                                let midX = (prev.x + cur.x) / 2
                                path.addCurve(to: cur, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: cur.y))
                            }
                            path.addLine(to: CGPoint(x: coords.last!.x, y: h))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // 2. Solid Pure White Bezier Curve for Historical Points
                        Path { path in
                            path.move(to: histCoords[0])
                            for i in 1..<histCoords.count {
                                let prev = histCoords[i - 1]
                                let cur = histCoords[i]
                                let midX = (prev.x + cur.x) / 2
                                path.addCurve(to: cur, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: cur.y))
                            }
                        }
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .shadow(color: Color.white.opacity(0.4), radius: 4)
                        
                        // 3. Dotted / Dashed Prediction Line near the end (2-3 dots)
                        Path { path in
                            path.move(to: predCoords[0])
                            for i in 1..<predCoords.count {
                                let prev = predCoords[i - 1]
                                let cur = predCoords[i]
                                let midX = (prev.x + cur.x) / 2
                                path.addCurve(to: cur, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: cur.y))
                            }
                        }
                        .stroke(
                            Color.white.opacity(0.9),
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [3, 5])
                        )
                        .shadow(color: Color.white.opacity(0.3), radius: 3)
                        
                        // 4. Dotted Prediction Node Circles (2-3 dots at predicted points)
                        ForEach(Array(predCoords.suffix(from: 1).enumerated()), id: \.offset) { _, pt in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 5, height: 5)
                                .position(pt)
                                .shadow(color: Color.white, radius: 3)
                        }
                        
                        // 5. Final Prediction Tip Beacon Dot
                        if let lastPt = coords.last {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                                .position(lastPt)
                                .shadow(color: Color.white, radius: 5)
                        }
                    }
                }
            }
            .frame(height: 55)
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
    @State private var showSubscriptionsHub: Bool = false
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var lastInspectedTransaction: Transaction? = nil
    @State private var pendingEditTransaction: Transaction? = nil
    @State private var pendingInspectTransaction: Transaction? = nil
    @State private var selectedCategoryForSheet: Category? = nil
    @State private var selectedAccountForSheet: Account? = nil
    @State private var showAccountsHub: Bool = false
    @State private var showSmartInsightsSheet: Bool = false
    
    @Namespace private var topControlsNamespace
    
    // Filter, Privacy & Expand State
    @State private var selectedAccountId: String = "all"
    @State private var selectedTimeFilter: DashboardTimeFilter = .month
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
    
    // All Dashboard Smart Insight Cards (Max 5 Clean, Story-Driven Cards)
    private var allDashboardInsightCards: [InsightCardViewModel] {
        var cards: [InsightCardViewModel] = []
        let calendar = Calendar.current
        let now = Date()
        let totalExpense = currentMonthExpenseTotal
        let expTxs = currentMonthExpenseTxs
        
        // 1. Card 1: Top Category Velocity / Dominance
        if !expTxs.isEmpty {
            var catTotals: [String: (total: Double, count: Int)] = [:]
            for tx in expTxs {
                let cur = catTotals[tx.categoryId, default: (0.0, 0)]
                catTotals[tx.categoryId] = (cur.total + tx.amount, cur.count + 1)
            }
            if let topEntry = catTotals.max(by: { $0.value.total < $1.value.total }),
               let topCat = store.categories.first(where: { $0.id == topEntry.key }) {
                let catPct = totalExpense > 0 ? Int((topEntry.value.total / totalExpense) * 100) : 0
                cards.append(
                    InsightCardViewModel(
                        id: "top_category_\(topCat.id)",
                        title: topCat.label,
                        icon: topCat.sfSymbol,
                        color: Color(hex: topCat.colorHex),
                        value: hideBalance ? "••••" : topEntry.value.total.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                        subtitle: "\(topEntry.value.count) \(topEntry.value.count == 1 ? "expense" : "expenses") · \(catPct)% of spend",
                        categoryId: topCat.id,
                        family: "category"
                    )
                )
            }
        }
        
        // 2. Card 2: Safe Daily Pacing & Allowance
        if store.budget.isActive && store.budgetTargetAmount(for: store.budget.period) > 0 {
            let budgetTarget = store.budgetTargetAmount(for: store.budget.period)
            let spent = store.budgetCycleExpenses
            let isOver = spent > budgetTarget
            
            cards.append(
                InsightCardViewModel(
                    id: "safe_daily",
                    title: "Daily Allowance",
                    icon: isOver ? "exclamationmark.shield.fill" : "shield.lefthalf.filled",
                    color: isOver ? Color(hex: "#FF453A") : Color(hex: "#30D158"),
                    value: hideBalance ? "••••" : "\(store.safeDailyAllowance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day",
                    subtitle: isOver ? "Budget exceeded · Restrict daily spend" : "\(store.budgetDaysLeft) days remaining in cycle",
                    family: "budget"
                )
            )
        } else {
            cards.append(
                InsightCardViewModel(
                    id: "set_budget",
                    title: "Budget Planner",
                    icon: SFIcons.tabBudget,
                    color: SpendyColors.primaryBlue,
                    value: "Set Limit",
                    subtitle: "Plan your monthly limit & unlock safe daily allowance",
                    family: "budget"
                )
            )
        }
        
        // 3. Card 3: Peak Spending Day / Weekday Rhythm
        if expTxs.count >= 2 {
            var weekdayTotals: [Int: Double] = [:]
            for tx in expTxs {
                let wd = calendar.component(.weekday, from: tx.date) - 1 // 0 (Sun) to 6 (Sat)
                weekdayTotals[wd, default: 0] += tx.amount
            }
            if let topDayEntry = weekdayTotals.max(by: { $0.value < $1.value }) {
                let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                let topDayName = dayNames[topDayEntry.key]
                cards.append(
                    InsightCardViewModel(
                        id: "peak_spending_day",
                        title: "Peak Spend Day",
                        icon: "calendar.badge.clock",
                        color: Color(hex: "#BF5AF2"),
                        value: topDayName,
                        subtitle: "Highest spending day this month",
                        family: "analytics"
                    )
                )
            }
        }
        
        // 4. Card 4: Upcoming Recurring Bills / Countdown
        if !upcomingExpenseSubs.isEmpty {
            let sortedSubs = upcomingExpenseSubs.sorted(by: { $0.nextBillingDate < $1.nextBillingDate })
            if let nextSub = sortedSubs.first {
                let days = max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: nextSub.nextBillingDate)).day ?? 0)
                let daysText = days == 0 ? "Due today" : "Due in \(days)d"
                cards.append(
                    InsightCardViewModel(
                        id: "next_bill_\(nextSub.id.uuidString)",
                        title: "Next Bill",
                        icon: nextSub.sfSymbol,
                        color: nextSub.color,
                        value: hideBalance ? "••••" : nextSub.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                        subtitle: "\(nextSub.name) · \(daysText)",
                        family: "subscription"
                    )
                )
            }
        } else {
            cards.append(
                InsightCardViewModel(
                    id: "track_subs",
                    title: "Subscriptions",
                    icon: "calendar.badge.clock",
                    color: Color(hex: "#FF9500"),
                    value: "Add Bills",
                    subtitle: "Track Netflix, Spotify & renewal dates",
                    family: "subscription"
                )
            )
        }
        
        // 5. Card 5: Behavioral Highlight / Largest Purchase / AI Milestone
        if expTxs.count >= 3,
           let maxTx = expTxs.max(by: { $0.amount < $1.amount }),
           totalExpense > 0 && (maxTx.amount / totalExpense) >= 0.15 {
            let maxCat = store.categories.first(where: { $0.id == maxTx.categoryId })
            let txPct = Int((maxTx.amount / totalExpense) * 100)
            cards.append(
                InsightCardViewModel(
                    id: "largest_purchase",
                    title: "Largest Purchase",
                    icon: maxCat?.sfSymbol ?? "star.fill",
                    color: maxCat?.color ?? Color(hex: "#FF375F"),
                    value: hideBalance ? "••••" : maxTx.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                    subtitle: "\(maxTx.title.isEmpty ? (maxCat?.label ?? "Single expense") : maxTx.title) · \(txPct)% of month",
                    family: "analytics"
                )
            )
        } else if store.transactions.count < 5 {
            let remainingToLog = max(1, 5 - store.transactions.count)
            cards.append(
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
        } else {
            // General engine insight fallback
            if let firstEngine = insightsEngineItems.first {
                cards.append(
                    InsightCardViewModel(
                        id: firstEngine.id,
                        title: firstEngine.title,
                        icon: firstEngine.icon,
                        color: firstEngine.color,
                        value: firstEngine.value,
                        subtitle: firstEngine.desc,
                        categoryId: firstEngine.categoryId,
                        family: firstEngine.family
                    )
                )
            }
        }
        
        return Array(cards.prefix(5))
    }
    
    // Dynamic Filtered Spend Amount for Selected Timeframe (D / W / M)
    private var filteredSpendAmount: Double {
        let calendar = Calendar.current
        let now = Date()
        let expenses = displayedTransactions.filter { $0.type == .expense }
        
        switch selectedTimeFilter {
        case .day:
            return expenses.filter { calendar.isDateInToday($0.date) }.reduce(0) { $0 + $1.amount }
        case .week:
            let today = calendar.startOfDay(for: now)
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) else { return 0 }
            return expenses.filter { $0.date >= sevenDaysAgo && $0.date <= now }.reduce(0) { $0 + $1.amount }
        case .month:
            return currentMonthExpenseTotal
        }
    }
    
    // Main overall trend curve points across all transactions with 2-3 engine prediction points at the end
    private var allTimeTrendGraphPoints: [SpendTrendPoint] {
        let txs = displayedTransactions.sorted(by: { $0.date < $1.date })
        guard !txs.isEmpty else {
            return [
                SpendTrendPoint(id: 0, label: "Start", amount: 100),
                SpendTrendPoint(id: 1, label: "P1", amount: 250),
                SpendTrendPoint(id: 2, label: "P2", amount: 450),
                SpendTrendPoint(id: 3, label: "P3", amount: 620),
                SpendTrendPoint(id: 4, label: "Pred 1", amount: 710),
                SpendTrendPoint(id: 5, label: "Pred 2", amount: 800)
            ]
        }
        
        // Build smooth historical curve points across transaction history (5-6 historical points)
        let totalCount = txs.count
        let bucketSize = max(1, totalCount / 6)
        var points: [SpendTrendPoint] = []
        var runningSum: Double = 0
        
        for i in stride(from: 0, to: totalCount, by: bucketSize) {
            let slice = txs[i..<min(i + bucketSize, totalCount)]
            let sum = slice.reduce(0.0) { $0 + ($1.type == .expense ? $1.amount : -$1.amount) }
            runningSum += max(0, sum)
            points.append(SpendTrendPoint(id: points.count, label: "P\(points.count + 1)", amount: runningSum))
        }
        
        // Engine prediction: 2 to 3 dotted prediction points near the end based on user burn rate / forecast
        let forecastStep = projectedMonthEndTotal > 0 ? (projectedMonthEndTotal / 20.0) : (runningSum > 0 ? runningSum * 0.12 : 60)
        let lastAmt = points.last?.amount ?? runningSum
        
        points.append(SpendTrendPoint(id: points.count, label: "Pred 1", amount: lastAmt + forecastStep * 2))
        points.append(SpendTrendPoint(id: points.count, label: "Pred 2", amount: lastAmt + forecastStep * 5))
        
        return points
    }
    
    private var completedGoalPercentage: Int {
        let incTotal = currentMonthIncomeTxs.reduce(0) { $0 + $1.amount }
        let expTotal = currentMonthExpenseTotal
        guard incTotal > 0 else { return 41 }
        let savings = incTotal - expTotal
        return max(0, min(100, Int((savings / incTotal) * 100)))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // 1. Top Header Bar (Profile Badge + Widget Action Buttons)
                        headerBar
                            .padding(.top, 4)
                        
                        // 2. Account Selector Dropdown Menu Chip & Time Filter
                        accountDropdownSelector
                        
                        // 3. Hero Spend Section with Catmull-Rom Curve & Prediction Line
                        heroBalanceUncarded
                        
                        // 4. Redesigned Budget Card
                        budgetHealthCard
                        
                        // 5. Smart Insights Cards Section
                        smartInsightsSection
                        
                        // 5. Ultra-Compact Accounts Card Section
                        compactAccountsSection
                        
                        // 6. Recent Transactions Card Section
                        recentTransactionsSection
                    }
                    .padding(.horizontal, 16)
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
                
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings, onDismiss: {
                settingsInitialDestination = nil
            }) {
                SettingsView(initialDestination: settingsInitialDestination)
                    .presentationBackground(Color(hex: "#1C1C1E"))
                    .presentationDragIndicator(.hidden)
            }
            .sheet(item: $editingTransaction, onDismiss: {
                // Re-open detail sheet with fresh (possibly edited) transaction data
                if let last = lastInspectedTransaction {
                    let fresh = store.transactions.first(where: { $0.id == last.id }) ?? last
                    lastInspectedTransaction = nil
                    pendingInspectTransaction = fresh
                }
                
                if let pending = pendingInspectTransaction {
                    pendingInspectTransaction = nil
                    inspectingTransaction = pending
                }
            }) { tx in
                AddTransactionView(transactionToEdit: tx)
            }
            .navigationDestination(isPresented: $showSubscriptionsHub) {
                SubscriptionsView(topControlsNamespace: topControlsNamespace)
            }
            .sheet(item: $inspectingTransaction, onDismiss: {
                if let pending = pendingEditTransaction {
                    pendingEditTransaction = nil
                    editingTransaction = pending
                }
            }) { tx in
                TransactionDetailSheet(transaction: tx) { txToEdit in
                    lastInspectedTransaction = tx
                    pendingEditTransaction = txToEdit
                    inspectingTransaction = nil
                }
            }
            .navigationDestination(item: $selectedCategoryForSheet) { category in
                CategoryAnalyticsSheet(
                    category: category,
                    topControlsNamespace: topControlsNamespace,
                    backButtonMorphID: "currencyConverterButton",
                    editButtonMorphID: "subscriptionsButton",
                    periodControlMorphID: "accountDropdownCapsule"
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedCategoryForSheet = nil
                    }
                }
            }
            .navigationDestination(item: $selectedAccountForSheet) { account in
                AccountAnalyticsSheet(
                    account: account,
                    topControlsNamespace: topControlsNamespace,
                    backButtonMorphID: "currencyConverterButton",
                    editButtonMorphID: "subscriptionsButton",
                    periodControlMorphID: "accountDropdownCapsule"
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedAccountForSheet = nil
                    }
                }
            }
            .navigationDestination(isPresented: $showAccountsHub) {
                AccountsView(topControlsNamespace: topControlsNamespace)
            }
            .navigationDestination(isPresented: $showSmartInsightsSheet) {
                SmartInsightsSheet(topControlsNamespace: topControlsNamespace)
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
                    if let imgData = store.profileImageData, let uiImage = UIImage(data: imgData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                    } else if let symbol = store.profileIconSymbol, !symbol.isEmpty {
                        Circle()
                            .fill(Color(hex: store.profileColorHex ?? "#007AFF"))
                            .frame(width: 44, height: 44)
                            .shadow(color: Color(hex: store.profileColorHex ?? "#007AFF").opacity(0.35), radius: 4, y: 2)
                        
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: store.profileColorHex ?? "#007AFF"), SpendyColors.accentCyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.15), radius: 6, y: 2)
                        
                        Text(store.userName.prefix(1).uppercased().isEmpty ? "P" : String(store.userName.prefix(1).uppercased()))
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Account and Settings")
            .matchedGeometryEffect(id: "topControl_left", in: topControlsNamespace)
            
            Spacer()
            
            // Top Right Widget Action Buttons
            GlassButtonGroup(spacing: 10) {
                // Currency Converter Button
                GlassCircleButton(
                    icon: "arrow.left.arrow.right",
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: "Currency converter",
                    morphID: "currencyConverterButton",
                    namespace: topControlsNamespace
                ) {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        showCurrencyConverter = true
                    }
                }
                
                // Privacy Eye Toggle Button
                GlassCircleButton(
                    icon: hideBalance ? SFIcons.eyeSlash : SFIcons.eye,
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: hideBalance ? "Show balance" : "Hide balance",
                    morphID: "privacyEyeButton",
                    namespace: topControlsNamespace
                ) {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.25)) {
                        hideBalance.toggle()
                    }
                }
                
                // Subscriptions Hub Button
                GlassCircleButton(
                    icon: "repeat",
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: "Subscriptions",
                    morphID: "subscriptionsButton",
                    namespace: topControlsNamespace
                ) {
                    HapticsManager.shared.trigger(.selection)
                    showSubscriptionsHub = true
                }
            }
            .matchedGeometryEffect(id: "topControl_right", in: topControlsNamespace)
        }
    }
    
    // MARK: - 2. Account Selector Dropdown Menu Chip & Time Filter
    private var accountDropdownSelector: some View {
        SpendyGlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
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
                    HStack(spacing: 6) {
                        Image(systemName: selectedAccountSymbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.primaryBlue)
                        
                        Text(selectedAccountLabel)
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .nativeLiquidGlassCapsule(isInteractive: true)
                    .glassMorphID("accountDropdownCapsule", in: topControlsNamespace)
                }
                .buttonStyle(.plain)
                .matchedGeometryEffect(id: "topControl_center", in: topControlsNamespace)
                
                Spacer()
            }
        }
    }
    
    // MARK: - 3. Hero Spend Section with Main Account Trend Curve & Engine Prediction Line
    private var heroBalanceUncarded: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Text(selectedAccountId == "all" ? "Total spent in May" : "\(selectedAccountLabel) Total Spent")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(SpendyColors.textTertiary)
                
                SpendyAmountView(
                    amount: currentMonthExpenseTotal,
                    currencySymbol: store.currencySymbol,
                    mainSize: 42,
                    weight: .heavy,
                    tracking: -1.2,
                    isHidden: hideBalance,
                    showDecimals: true,
                    color: SpendyColors.textPrimary
                )
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                    Text("\(store.currencySymbol)649,48 vs last period")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(SpendyColors.textSecondary)
            }
            .padding(.top, 4)
            
            // Inline Main Account Graph with 2-3 Engine Prediction Dots near the end
            HeroSpendTrendGraph(points: allTimeTrendGraphPoints, currencySymbol: store.currencySymbol)
                .padding(.horizontal, -14)
                .padding(.top, 4)
        }
    }
    
    // MARK: - 4. Single Ultra-Compact Horizontal Glass Widget Carousel (Zero-Scroll Row)
    private var horizontalWidgetCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 1. Month-End Forecast Card
                forecastWidgetCard
                
                // 2. Budget Health Card
                compactBudgetWidgetCard
                
                // 3. Smart Bento Insight Card
                if let topInsight = allDashboardInsightCards.first {
                    bentoInsightWidgetCard(topInsight)
                }
                
                // 4. Apple Wallet Compact Accounts Stack Card
                compactAccountsWalletCard
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Widget 1: Month-End Forecast Card
    private var forecastWidgetCard: some View {
        let forecast = projectedMonthEndTotal
        let budgetTarget = store.budgetTargetAmount(for: store.budget.period)
        let isBudgetActive = store.budget.isActive && budgetTarget > 0
        let diff = budgetTarget - forecast
        let isUnder = diff >= 0
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 26, height: 26)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("MONTH-END FORECAST")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(SpendyColors.textTertiary)
                
                Spacer(minLength: 0)
            }
            
            Text(hideBalance ? "••••" : (forecast > 0 ? forecast.formattedCurrency(symbol: store.currencySymbol, decimals: 0) : currentMonthExpenseTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0)))
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
            
            Text(isBudgetActive ? (isUnder ? "Paced \(hideBalance ? "••••" : abs(diff).formattedCurrency(symbol: store.currencySymbol, decimals: 0)) under budget 🎯" : "Paced \(hideBalance ? "••••" : abs(diff).formattedCurrency(symbol: store.currencySymbol, decimals: 0)) over budget ⚠️") : "Based on your daily burn rate")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isBudgetActive ? (isUnder ? Color(hex: "#30D158") : Color(hex: "#FF453A")) : SpendyColors.textSecondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(width: 240, height: 104, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Widget 2: Compact Budget Health Card
    private var compactBudgetWidgetCard: some View {
        let budget = store.budget
        let target = store.budgetTargetAmount(for: budget.period)
        let spent = store.budgetCycleExpenses
        let isConfigured = budget.isActive && target > 0
        let percentSpent = isConfigured ? (spent / target) : 0.0
        let remaining = max(0, target - spent)
        
        let statusColor: Color = {
            if !isConfigured { return SpendyColors.primaryBlue }
            if spent > target { return Color(hex: "#FF453A") }
            if percentSpent >= 0.85 { return Color(hex: "#FF9F0A") }
            return Color(hex: "#30D158")
        }()
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            if let selectedTab = selectedTab {
                selectedTab.wrappedValue = .budget
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 3)
                            .frame(width: 24, height: 24)
                        if isConfigured {
                            Circle()
                                .trim(from: 0.0, to: min(1.0, CGFloat(percentSpent)))
                                .stroke(statusColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: SFIcons.tabBudget)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SpendyColors.primaryBlue)
                        }
                    }
                    
                    Text("BUDGET PACING")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Spacer(minLength: 0)
                }
                
                Text(isConfigured ? (hideBalance ? "••••" : "\(remaining.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) left") : "Set Budget")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                
                Text(isConfigured ? "Safe: \(hideBalance ? "••••" : store.safeDailyAllowance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day · \(store.budgetDaysLeft)d left" : "Track safe daily allowance")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(width: 230, height: 104, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Widget 3: Smart Bento Insight Card
    private func bentoInsightWidgetCard(_ insight: InsightCardViewModel) -> some View {
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            if let catId = insight.categoryId, let cat = store.categories.first(where: { $0.id == catId }) {
                selectedCategoryForSheet = cat
            } else if insight.family == "analytics" || insight.family == "budget" {
                if let selectedTab = selectedTab { selectedTab.wrappedValue = .analytics }
            } else {
                showAddTransaction = true
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    SpendyIconBadge(sfSymbol: insight.icon, color: insight.color, size: .small, style: .circle)
                    
                    Text(insight.title.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(SpendyColors.textTertiary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                }
                
                Text(insight.value)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                
                Text(insight.subtitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(width: 230, height: 104, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var totalNetWorthValue: Double {
        store.accounts.reduce(0) { $0 + store.balance(for: $1.id) }
    }
    
    private var projectedMonthEndTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        let day = max(1, calendar.component(.day, from: now))
        let totalDays = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let spentSoFar = currentMonthExpenseTotal
        guard spentSoFar > 0 else { return 0 }
        let dailyRate = spentSoFar / Double(day)
        return dailyRate * Double(totalDays)
    }
    
    // MARK: - Widget 4: Apple Wallet Compact Accounts Card
    private var compactAccountsWalletCard: some View {
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            showAccountsHub = true
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: -6) {
                        ForEach(Array(store.accounts.prefix(3).enumerated()), id: \.element.id) { idx, acc in
                            SpendyIconBadge(
                                sfSymbol: acc.sfSymbol.isEmpty ? acc.type.defaultSymbol : acc.sfSymbol,
                                color: acc.color,
                                size: .small,
                                style: .circle
                            )
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                        }
                    }
                    
                    Text("ACCOUNTS (\(store.accounts.count))")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Spacer(minLength: 0)
                }
                
                Text(hideBalance ? "••••" : totalNetWorthValue.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                
                Text("Net Worth Total · Tap to manage")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(width: 220, height: 104, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 4. Redesigned Premium Budget Health & Pacing Card
    private var budgetHealthCard: some View {
        let budget = store.budget
        let target = store.budgetTargetAmount(for: budget.period)
        let spent = store.budgetCycleExpenses
        let isConfigured = budget.isActive && target > 0
        let percentSpent = isConfigured ? (spent / target) : 0.26
        let isExceeded = spent > target && isConfigured
        let remaining = max(0, target - spent)
        
        let statusColor: Color = {
            if !isConfigured { return Color(hex: "#30D158") }
            if isExceeded { return Color(hex: "#FF453A") }
            if percentSpent >= 0.85 { return Color(hex: "#FF9F0A") }
            return Color(hex: "#30D158")
        }()
        
        let pctVal = Int(min(999, percentSpent * 100))
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            if let selectedTab = selectedTab {
                selectedTab.wrappedValue = .budget
            }
        }) {
            HStack(spacing: 16) {
                // Circular Progress Gauge Ring with Percentage inside (e.g. 26%)
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 4)
                        .frame(width: 48, height: 48)
                    
                    Circle()
                        .trim(from: 0.0, to: min(1.0, CGFloat(percentSpent)))
                        .stroke(
                            statusColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 48, height: 48)
                        .shadow(color: statusColor.opacity(0.5), radius: 4)
                    
                    Text("\(pctVal)%")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                // Status Text Column
                VStack(alignment: .leading, spacing: 3) {
                    Text(isConfigured ? "\(hideBalance ? "••••" : remaining.formattedCurrency(symbol: store.currencySymbol)) left in budget" : "\(hideBalance ? "••••" : "$5 872,06")} left in budget")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(isConfigured ? (isExceeded ? "Budget limit exceeded this period." : "Almost finished and well under budget.") : "Almost finished and well under budget.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                    
                    Text(isConfigured ? (isExceeded ? "Restrict spending." : "Strong control all the way through.") : "Strong control all the way through.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
            }
            .padding(16)
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
    
    // MARK: - 4. 3-Column Metric Breakdown Row (Expenses, Income, Savings Rate % - Uncarded on screen)
    private var threeColumnMetricsRow: some View {
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            if let selectedTab = selectedTab {
                selectedTab.wrappedValue = .analytics
            }
        }) {
            HStack(spacing: 0) {
                metricColumn(
                    value: currentMonthExpenseTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                    unit: "Expenses",
                    sublabel: "\(currentMonthExpenseTxs.count) txs"
                )
                
                Spacer()
                
                let incTotal = currentMonthIncomeTxs.reduce(0) { $0 + $1.amount }
                metricColumn(
                    value: "+\(incTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                    unit: "Income",
                    sublabel: "\(currentMonthIncomeTxs.count) txs",
                    isPositive: true
                )
                
                Spacer()
                
                metricColumn(
                    value: "\(completedGoalPercentage)%",
                    unit: "Savings Rate",
                    sublabel: "\(store.accounts.count) accounts"
                )
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func metricColumn(value: String, unit: String, sublabel: String, isPositive: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(hideBalance ? "••••" : value)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(isPositive ? Color(hex: "#30D158") : SpendyColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(unit)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Text(sublabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
        }
    }
    
    // MARK: - 6. Smart Insights Section (Max 5 Clean & Story-Driven Insight Cards)
    // MARK: - 6. Smart Insights Section (Only shown when enough transaction data exists)
    @ViewBuilder
    private var smartInsightsSection: some View {
        if displayedTransactions.count >= 3 && !allDashboardInsightCards.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Smart Insight")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        showSmartInsightsSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Text("View all")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(SpendyColors.textSecondary)
                    }
                    .buttonStyle(.plain)
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
                                    } else if insight.family == "subscription" || insight.id == "upcoming_subs" || insight.id.hasPrefix("next_bill_") || insight.id == "track_subs" {
                                        HapticsManager.shared.trigger(.selection)
                                        showSubscriptionsHub = true
                                    } else if insight.family == "onboarding" || insight.id == "unlock_ai" {
                                        showAddTransaction = true
                                    } else if insight.family == "analytics" {
                                        if let selectedTab = selectedTab {
                                            selectedTab.wrappedValue = .analytics
                                        }
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
    
    // MARK: - 5. Accounts Card Section
    private var compactAccountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            VStack(spacing: 14) {
                // Top Header Inside Accounts Card: Total & Sparkline (Opens Accounts Hub)
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    showAccountsHub = true
                }) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Net Worth")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                            
                            Text(hideBalance ? "••••••" : totalNetWorthValue.formattedCurrency(symbol: store.currencySymbol))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        let isPositiveTrend = store.netWorthChangePercentage >= 0
                        TrendSparkline(isPositive: isPositiveTrend)
                            .frame(width: 100, height: 36)
                    }
                }
                .buttonStyle(.plain)
                
                Divider()
                    .overlay(SpendyColors.separator)
                
                // Account Rows Inside Accounts Card
                VStack(spacing: 12) {
                    ForEach(store.accounts) { acc in
                        let bal = store.balance(for: acc.id)
                        
                        Button(action: {
                            HapticsManager.shared.trigger(.selection)
                            selectedAccountForSheet = acc
                        }) {
                            HStack(spacing: 14) {
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
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SpendyColors.primaryBlue.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(SpendyColors.primaryBlue)
            }
            .padding(.top, 4)
            
            VStack(spacing: 4) {
                Text("No transactions logged yet")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Text("Start tracking your daily expenses and income")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                showAddTransaction = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add Transaction")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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
