//
//  DashboardView.swift
//  Spendy
//
//  Clean Minimal Home Dashboard:
//  - Top Bar: Profile Avatar (Left) + Top Action Toggles (Stats, Currency, Privacy, Budget)
//  - Account Dropdown Selector (Below Top Toggles)
//  - Hero Spend Section: Monthly Spend Card + On-Screen 6-Month Bar Chart with Interactive Scrubbing
//  - Interactive Bottom Transactions Drawer with high-performance drag
//

import SwiftUI
import TipKit

// MARK: - Bar Chart Data Point
struct MinimalBarPoint: Identifiable, Equatable {
    let id: String
    let label: String
    let amount: Double
}

// MARK: - Spend Trend Point (Shared with SparklineView)
struct SpendTrendPoint: Identifiable, Equatable {
    let id: Int
    let label: String
    let amount: Double
}

// MARK: - On-Screen Hero Spend Bar Chart Component with Interactive Scrubbing
struct HeroSpendBarChart: View {
    @GestureState private var isHoldingPreview = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let dataPoints: [MinimalBarPoint]
    @Binding var scrubbedPoint: MinimalBarPoint?
    @Binding var isScrubbing: Bool
    var barColor: Color = SpendyColors.textPrimary
    var showsLine: Bool = false
    var barTopCornerRadius: CGFloat? = nil
    var softensPastBars: Bool = false
    var gridColor: Color = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.12),
        dark: UIColor(white: 1.0, alpha: 0.18)
    ))
    
    public init(
        dataPoints: [MinimalBarPoint],
        scrubbedPoint: Binding<MinimalBarPoint?> = .constant(nil),
        isScrubbing: Binding<Bool> = .constant(false),
        barColor: Color = SpendyColors.textPrimary,
        showsLine: Bool = false,
        barTopCornerRadius: CGFloat? = nil,
        softensPastBars: Bool = false
    ) {
        self.dataPoints = dataPoints
        self._scrubbedPoint = scrubbedPoint
        self._isScrubbing = isScrubbing
        self.barColor = barColor
        self.showsLine = showsLine
        self.barTopCornerRadius = barTopCornerRadius
        self.softensPastBars = softensPastBars
    }
    
    private var maxAmount: Double {
        let maxVal = dataPoints.map(\.amount).max() ?? 0
        if maxVal <= 0 { return 300_000 }
        let magnitude = pow(10, floor(log10(maxVal)))
        let normalized = maxVal / magnitude
        let step: Double
        if normalized <= 1.2 { step = 1.5 }
        else if normalized <= 2.5 { step = 3.0 }
        else if normalized <= 5.0 { step = 6.0 }
        else { step = 10.0 }
        return step * magnitude
    }
    
    private var yAxisLevels: [Double] {
        let maxVal = maxAmount
        return [maxVal, maxVal * (2.0 / 3.0), maxVal * (1.0 / 3.0), 0]
    }
    
    private func barLayout(chartWidth: CGFloat) -> (barWidth: CGFloat, spacing: CGFloat, cornerRadius: CGFloat) {
        let count = CGFloat(max(1, dataPoints.count))
        if softensPastBars && !showsLine {
            // Keep each bar centered under its month while opening up the gaps.
            let columnWidth = chartWidth / count
            let barWidth = min(26, columnWidth * 0.55)
            return (barWidth, columnWidth - barWidth, min(barTopCornerRadius ?? 1, barWidth / 2))
        }
        let spacing: CGFloat
        if count >= 10 {
            spacing = 3
        } else if count >= 6 {
            spacing = 6
        } else {
            spacing = max(4, chartWidth * 0.03)
        }
        let barWidth = min(48, max(4, (chartWidth - spacing * (count + 1)) / count))
        let cornerRadius = min(barTopCornerRadius ?? 1, barWidth / 2)
        return (barWidth, spacing, cornerRadius)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let chartWidth = max(10, geo.size.width - 65) // Reserve 65pt for Y-axis labels on right
                let chartHeight = geo.size.height
                let layout = barLayout(chartWidth: chartWidth)
                let barWidth = layout.barWidth
                let spacing = layout.spacing
                let cornerRadius = layout.cornerRadius
                
                ZStack(alignment: .topLeading) {
                    // 1. Horizontal Grid Lines & Right-aligned Y-Axis Labels
                    ForEach(Array(yAxisLevels.enumerated()), id: \.offset) { index, level in
                        HStack(spacing: 8) {
                            Rectangle().fill(gridColor).frame(height: 0.8)
                            Text(formatAxisNumber(level))
                                .font(.system(size: 10, weight: .regular, design: .default))
                                .monospacedDigit()
                                .foregroundStyle(SpendyColors.textSecondary)
                                .frame(width: 50, alignment: .leading)
                        }
                        .frame(width: geo.size.width)
                        .position(x: geo.size.width / 2,
                                  y: chartHeight * CGFloat(index) / CGFloat(yAxisLevels.count - 1))
                    }

                    // Both views use the same scale, month positions, and scrubbing.
                    if showsLine {
                        spendingLine(width: chartWidth, height: chartHeight)
                    } else {
                        HStack(spacing: spacing) {
                            Spacer(minLength: 0)

                            ForEach(dataPoints) { point in
                                let isSelected = scrubbedPoint?.id == point.id
                                let isAnySelected = scrubbedPoint != nil
                                let ratio = maxAmount > 0 ? CGFloat(min(1.0, max(0.0, point.amount / maxAmount))) : 0.0
                                let barH = point.amount > 0 ? max(4, ratio * (chartHeight - 4)) : 0

                                VStack {
                                    Spacer(minLength: 0)

                                    UnevenRoundedRectangle(
                                        topLeadingRadius: min(cornerRadius, barH / 2),
                                        bottomLeadingRadius: barTopCornerRadius == nil ? cornerRadius : 0,
                                        bottomTrailingRadius: barTopCornerRadius == nil ? cornerRadius : 0,
                                        topTrailingRadius: min(cornerRadius, barH / 2),
                                        style: .continuous
                                    )
                                        .fill(barColor)
                                        .frame(width: barWidth, height: barH)
                                        .scaleEffect(isSelected ? 1.06 : 1.0, anchor: .bottom)
                                        .opacity(isAnySelected
                                            ? (isSelected ? 1.0 : 0.30)
                                            : (softensPastBars && point.id != dataPoints.last?.id ? 0.45 : 1.0))
                                }
                                .frame(width: barWidth, height: chartHeight)
                                .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isSelected)
                                .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isAnySelected)
                            }

                            Spacer(minLength: 0)
                        }
                        .frame(width: chartWidth, height: chartHeight)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    LongPressGesture(minimumDuration: 0.2, maximumDistance: 12)
                        .sequenced(before: DragGesture(minimumDistance: 0))
                        .updating($isHoldingPreview) { value, state, _ in
                            if case .second(true, _) = value { state = true }
                        }
                        .onChanged { value in
                            guard case .second(true, let drag?) = value else { return }
                            isScrubbing = true
                            if let closest = closestPoint(to: drag.location.x, chartWidth: chartWidth),
                               closest.id != scrubbedPoint?.id {
                                HapticsManager.shared.trigger(.selection)
                                scrubbedPoint = closest
                            }
                        }
                        .onEnded { _ in
                            isScrubbing = false
                            scrubbedPoint = nil
                        }
                )
                .onChange(of: isHoldingPreview) { _, holding in
                    if !holding {
                        isScrubbing = false
                        scrubbedPoint = nil
                    }
                }
                .accessibilityHint("Hold and slide to preview spending. Release to return to the total.")
            }
            .frame(height: 150)
            
            // 3. X-Axis Labels Row (Matching Chart Width)
            HStack(spacing: 0) {
                ForEach(dataPoints) { point in
                    let isSelected = scrubbedPoint?.id == point.id
                    Text(point.label)
                        .font(.system(size: 12, weight: isSelected ? .bold : .semibold, design: isSelected ? .monospaced : .default))
                        .monospacedDigit()
                        .foregroundStyle(
                            isSelected ? SpendyColors.textPrimary : (scrubbedPoint != nil ? SpendyColors.textTertiary : SpendyColors.textSecondary)
                        )
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
            }
            .padding(.trailing, 65) // Align with chart area
            .padding(.top, 4)
        }
    }
    
    private func spendingLine(width: CGFloat, height: CGFloat) -> some View {
        let layout = barLayout(chartWidth: width)
        let totalWidth = CGFloat(dataPoints.count) * layout.barWidth + CGFloat(max(0, dataPoints.count - 1)) * layout.spacing
        let startX = (width - totalWidth) / 2 + layout.barWidth / 2
        let coordinates = dataPoints.enumerated().map { index, point in
            CGPoint(
                x: startX + CGFloat(index) * (layout.barWidth + layout.spacing),
                y: height - CGFloat(min(1, max(0, point.amount / maxAmount))) * (height - 4)
            )
        }
        let curve = Path { path in
            guard let first = coordinates.first else { return }
            path.move(to: first)
            for index in 1..<coordinates.count {
                let previous = coordinates[index - 1]
                let current = coordinates[index]
                let midX = (previous.x + current.x) / 2
                path.addCurve(to: current,
                              control1: CGPoint(x: midX, y: previous.y),
                              control2: CGPoint(x: midX, y: current.y))
            }
        }
        return ZStack(alignment: .topLeading) {
            Path { path in
                guard let first = coordinates.first, let last = coordinates.last else { return }
                path.addPath(curve)
                path.addLine(to: CGPoint(x: last.x, y: height))
                path.addLine(to: CGPoint(x: first.x, y: height))
                path.closeSubpath()
            }
            .fill(barColor.opacity(0.05))
            curve.stroke(barColor, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
                if scrubbedPoint?.id == point.id || (scrubbedPoint == nil && index == dataPoints.count - 1) {
                    Circle()
                        .fill(SpendyColors.appBackground)
                        .overlay(Circle().stroke(barColor, lineWidth: 2))
                        .frame(width: 8, height: 8)
                        .position(coordinates[index])
                }
            }
        }
        .frame(width: width, height: height)
    }

    private func closestPoint(to locationX: CGFloat, chartWidth: CGFloat) -> MinimalBarPoint? {
        guard !dataPoints.isEmpty else { return nil }
        let layout = barLayout(chartWidth: chartWidth)
        let barWidth = layout.barWidth
        let spacing = layout.spacing
        
        let totalWidth = CGFloat(dataPoints.count) * barWidth + CGFloat(max(0, dataPoints.count - 1)) * spacing
        let startX = (chartWidth - totalWidth) / 2 + barWidth / 2
        var closest: MinimalBarPoint? = nil
        var minDistance: CGFloat = .infinity
        
        for (index, point) in dataPoints.enumerated() {
            let barCenterX = startX + CGFloat(index) * (barWidth + spacing)
            let distance = abs(locationX - barCenterX)
            if distance < minDistance {
                minDistance = distance
                closest = point
            }
        }
        return closest
    }
    
    private func formatAxisNumber(_ num: Double) -> String {
        if num <= 0 { return "0" }
        if num >= 1_000_000 {
            let m = num / 1_000_000
            return m.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(m))M" : String(format: "%.1fM", m)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: num)) ?? "\(Int(num))"
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.spendyTipsAllowed) private var tipsAllowed
    @Environment(ExpenseStore.self) private var store
    @Environment(QuickActionManager.self) private var quickActionManager
    @Binding var showAddTransaction: Bool
    var selectedTab: Binding<AppTab>? = nil
    var isSheetExpandedBinding: Binding<Bool>? = nil
    var isSubpageActiveBinding: Binding<Bool>? = nil
    
    // Sheets & Navigation State
    @State private var showSettings: Bool = false
    @State private var homeTipGroup = TipGroup(.firstAvailable) {
        HomeAnalyticsTip()
        HomeInsightTip()
    }
    @State private var settingsInitialDestination: SettingsDestination? = nil
    @State private var showAnalyticsView: Bool = false
    @State private var showCurrencyConverter: Bool = false
    @State private var showBudgetHub: Bool = false
    @State private var showSubscriptionsHub: Bool = false
    @State private var initialSubscriptionIdForHub: String? = nil
    @State private var showAccounts: Bool = false
    @State private var pendingTransactionEdit: Transaction? = nil
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var selectedCategoryForSheet: Category? = nil
    @State private var categorySpendingScope: SpendingScope? = nil
    @State private var selectedAccountForSheet: Account? = nil
    
    @State private var analyticsNavigationHeader = AnalyticsNavigationHeaderState()
    @Namespace private var topControlsNamespace
    
    // Filter, Privacy & Expand State
    @State private var selectedAccountId: String = "all"
    @State private var homeSummaryHeight: CGFloat = 0
    @State private var hideBalance: Bool = false
    @State private var showAllTransactions: Bool = false
    @State private var transactionFiltersExpanded = false
    @State private var showEditBudgetSheet: Bool = false
    @State private var analyticsInitialDate: Date? = nil
    
    // MARK: - Interactive Split Dashboard Drawer State
    @State private var internalSheetExpanded: Bool = false
    
    private var isSubpageActive: Bool {
        showBudgetHub ||
        showAccounts ||
        showAllTransactions ||
        showSubscriptionsHub ||
        showAnalyticsView ||
        selectedCategoryForSheet != nil ||
        selectedAccountForSheet != nil
    }
    
    private var isSheetExpanded: Bool {
        isSheetExpandedBinding?.wrappedValue ?? internalSheetExpanded
    }
    
    private func setExpandedState(_ expanded: Bool) {
        if let binding = isSheetExpandedBinding {
            binding.wrappedValue = expanded
        }
        internalSheetExpanded = expanded
    }
    @State private var drawerFilterCategoryId: String? = nil
    @State private var drawerFilterAccountId: String? = nil
    @State private var drawerFilterType: TransactionType? = nil
    
    private var hasActiveFilters: Bool {
        drawerFilterCategoryId != nil || drawerFilterAccountId != nil || drawerFilterType != nil
    }
    
    private func clearDrawerFilters() {
        drawerFilterCategoryId = nil
        drawerFilterAccountId = nil
        drawerFilterType = nil
    }
    
    private var drawerCategoryButtonLabel: String {
        if let catId = drawerFilterCategoryId, let cat = store.categories.first(where: { $0.id == catId }) {
            return cat.label
        }
        return "Categories"
    }
    
    private var drawerAccountButtonLabel: String {
        if let accId = drawerFilterAccountId, let acc = store.accounts.first(where: { $0.id == accId }) {
            return acc.label
        }
        return "Accounts"
    }
    
    private var drawerTypeButtonLabel: String {
        switch drawerFilterType {
        case .expense: return "Expenses"
        case .income: return "Income"
        case .transfer: return "Transfers"
        case .none: return "All Types"
        }
    }
    
    // MARK: - Dynamic Filtered Transactions
    private var displayedTransactions: [Transaction] {
        var txs = store.filteredTransactions(for: selectedAccountId)
        
        if let catId = drawerFilterCategoryId {
            txs = txs.filter { $0.type != .transfer && $0.categoryId == catId }
        }
        
        if let accId = drawerFilterAccountId {
            txs = txs.filter { $0.accountId == accId || $0.toAccountId == accId }
        }
        
        if let type = drawerFilterType {
            txs = txs.filter { $0.type == type }
        }
        
        return txs.sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Date Grouped Tuples: (DateTitle, GroupNetTotal, [Transaction])
    private var drawerGroupedTransactions: [(String, Double, [Transaction])] {
        let calendar = Calendar.current
        var groups: [String: [Transaction]] = [:]
        var order: [String] = []
        
        for tx in displayedTransactions {
            let key: String
            if calendar.isDateInToday(tx.date) {
                key = "Today"
            } else if calendar.isDateInYesterday(tx.date) {
                key = "Yesterday"
            } else {
                key = SpendyDateFormatterCache.dayMonth.string(from: tx.date)
            }
            
            if groups[key] == nil {
                order.append(key)
            }
            groups[key, default: []].append(tx)
        }
        
        return order.map { key in
            let txs = groups[key] ?? []
            let netTotal = txs.reduce(0.0) { sum, tx in
                switch tx.type {
                case .expense: return sum - tx.amount
                case .income: return sum + tx.amount
                case .transfer: return sum
                }
            }
            return (key, netTotal, txs)
        }
    }
    
    private func formattedGroupNetTotal(_ net: Double) -> String {
        if hideBalance { return "••••" }
        let sym = store.currencySymbol
        let absFormatted = abs(net).formattedCurrency(symbol: sym)
        if net > 0 {
            return "+\(absFormatted)"
        } else if net < 0 {
            return "-\(absFormatted)"
        } else {
            return absFormatted
        }
    }
    
    private var selectedAccountLabel: String {
        if selectedAccountId == "all" { return "All Accounts" }
        return store.accounts.first(where: { $0.id == selectedAccountId })?.label ?? "Account"
    }
    
    private var selectedAccountSymbol: String {
        if selectedAccountId == "all" { return "wallet.pass.fill" }
        return store.accounts.first(where: { $0.id == selectedAccountId })?.sfSymbol ?? "creditcard.fill"
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let totalHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
                let topInset = geometry.safeAreaInsets.top
                let bottomInset = geometry.safeAreaInsets.bottom
                
                ZStack(alignment: .topLeading) {
                    SpendyColors.appBackground
                        .ignoresSafeArea()
                    
                    // The summary can scroll independently at larger text sizes.
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            accountDropdownSelector
                            heroSpendBarSection
                                .padding(.top, 2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { homeSummaryHeight = $0 + topInset + 58 }
                    }
                    .safeAreaBar(edge: .top, spacing: 0) {
                        homeHeaderPlaceholder
                            .padding(.horizontal, 20)
                            .padding(.top, topInset + 4)
                            .padding(.bottom, 10)
                    }
                    .scrollEdgeEffectStyle(.soft, for: .top)
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollDisabled(homeSummaryHeight <= restingDrawerOffset(totalHeight: totalHeight, bottomInset: bottomInset) - 8)
                    .frame(height: max(0, restingDrawerOffset(totalHeight: totalHeight, bottomInset: bottomInset) - 8), alignment: .top)
                    .accessibilityIdentifier("home-spending-canvas")

                    // 2. Interactive Bottom Transactions Drawer (Solid Opaque Surface)
                    recentTransactionsDrawer(
                        totalHeight: totalHeight,
                        topInset: topInset,
                        bottomInset: bottomInset
                    )
                }
                .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings, onDismiss: {
                settingsInitialDestination = nil
            }) {
                SettingsView(initialDestination: settingsInitialDestination)
                    .presentationBackground(SpendyColors.settingsBackground)
                    .presentationDragIndicator(.hidden)
            }
            .fullScreenCover(isPresented: $showEditBudgetSheet) {
                EditBudgetSheet(isEditing: store.budget.isActive)
            }
            .sheet(isPresented: $showCurrencyConverter) {
                FloatingCurrencyConverterView(isPresented: $showCurrencyConverter)
            }
            .fullScreenCover(item: $editingTransaction) { tx in
                AddTransactionView(transactionToEdit: tx)
            }
            .sheet(item: $inspectingTransaction, onDismiss: {
                editingTransaction = pendingTransactionEdit
                pendingTransactionEdit = nil
            }) { tx in
                TransactionDetailSheet(transaction: tx) { txToEdit in
                    pendingTransactionEdit = txToEdit
                    inspectingTransaction = nil
                }
            }
            .navigationDestination(isPresented: $showAnalyticsView) {
                AnalyticsView(
                    selectedTab: selectedTab,
                    topControlsNamespace: topControlsNamespace,
                    sharedNavigationHeader: analyticsNavigationHeader,
                    initialAccountID: selectedAccountId,
                    initialDate: analyticsInitialDate
                )
            }
            .navigationDestination(isPresented: $showBudgetHub) {
                BudgetView(topControlsNamespace: topControlsNamespace,
                    sharedNavigationHeader: analyticsNavigationHeader)
            }
            .navigationDestination(isPresented: $showSubscriptionsHub) {
                SubscriptionsView(
                    isPushed: true,
                    initialSelectedSubscriptionId: initialSubscriptionIdForHub,
                    topControlsNamespace: topControlsNamespace,
                    sharedNavigationHeader: analyticsNavigationHeader
                )
            }
            .navigationDestination(isPresented: $showAccounts) {
                AccountsView(topControlsNamespace: topControlsNamespace,
                    sharedNavigationHeader: analyticsNavigationHeader)
            }
            .navigationDestination(isPresented: $showAllTransactions) {
                AllTransactionsView(
                    usesSharedHeader: true,
                    areFiltersExpanded: transactionFiltersExpanded,
                    topControlsNamespace: topControlsNamespace
                )
            }
            .navigationDestination(item: $selectedCategoryForSheet) { category in
                CategoryAnalyticsSheet(
                    category: category,
                    spendingScope: categorySpendingScope,
                    topControlsNamespace: topControlsNamespace,
                    sharedNavigationHeader: analyticsNavigationHeader,
                    backButtonMorphID: "topControl_left",
                    periodControlMorphID: "accountDropdownCapsule"
                )
            }
            .navigationDestination(item: $selectedAccountForSheet) { account in
                AccountAnalyticsSheet(
                    account: account,
                    topControlsNamespace: topControlsNamespace,
                    sharedNavigationHeader: analyticsNavigationHeader,
                    backButtonMorphID: "topControl_left",
                    periodControlMorphID: "accountDropdownCapsule"
                )
            }
            .onChange(of: isSubpageActive) { _, active in
                withAnimation(reduceMotion ? nil : AppMotion.fluidSpring) {
                    isSubpageActiveBinding?.wrappedValue = active
                }
            }
            .onChange(of: quickActionManager.shouldOpenBudget) { _, shouldOpen in
                if shouldOpen {
                    showBudgetHub = true
                    quickActionManager.shouldOpenBudget = false
                }
            }
            .onChange(of: quickActionManager.requestedSubscriptionId) { _, id in
                if let id {
                    initialSubscriptionIdForHub = id
                    showSubscriptionsHub = true
                    quickActionManager.requestedSubscriptionId = nil
                }
            }
            .onChange(of: quickActionManager.requestedCategoryId) { _, id in
                if let id, let category = store.categories.first(where: { $0.id == id }) {
                    selectedCategoryForSheet = category
                    quickActionManager.requestedCategoryId = nil
                }
            }
            .onAppear {
                if let id = quickActionManager.requestedSubscriptionId {
                    initialSubscriptionIdForHub = id
                    showSubscriptionsHub = true
                    quickActionManager.requestedSubscriptionId = nil
                }
                isSubpageActiveBinding?.wrappedValue = isSubpageActive
                if quickActionManager.shouldOpenBudget {
                    showBudgetHub = true
                    quickActionManager.shouldOpenBudget = false
                }
                if let id = quickActionManager.requestedCategoryId,
                   let category = store.categories.first(where: { $0.id == id }) {
                    selectedCategoryForSheet = category
                    quickActionManager.requestedCategoryId = nil
                }
            }
        }
        .overlay(alignment: .top) {
            if isSharedHeaderVisible || isDetailHeaderVisible {
                sharedNavigationHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }
        }
        .onChange(of: showAnalyticsView) { _, showing in
            if !showing { analyticsNavigationHeader.isVisible = false }
        }
        .onChange(of: selectedCategoryForSheet?.id) { _, id in
            if id == nil { categorySpendingScope = nil }
        }
        .onChange(of: showAllTransactions) { _, _ in
            transactionFiltersExpanded = false
        }
        .onChange(of: store.transactions.contains(where: { $0.type == .expense }), initial: true) { _, hasSpending in
            HomeAnalyticsTip.hasSpending = hasSpending
        }
    }

    // TipKit stays inside the stack's presentation context; the visible chrome lives above it.
    private var homeHeaderPlaceholder: some View {
        HStack(spacing: 0) {
            Spacer()
            Color.clear
                .frame(width: 44, height: 44)
                .popoverTip(tipsAllowed && store.hasCompletedOnboarding && !showSettings && !isSubpageActive && !isSheetExpanded
                    ? homeTipGroup.currentTip as? HomeAnalyticsTip : nil)
            Color.clear.frame(width: 45, height: 44)
        }
        .accessibilityHidden(true)
    }

    private var isSharedHeaderVisible: Bool {
        !showAnalyticsView && !showBudgetHub && !showSubscriptionsHub && !showAccounts
            && selectedCategoryForSheet == nil && selectedAccountForSheet == nil
            && (showAllTransactions || !isSheetExpanded)
    }

    private var isDetailHeaderVisible: Bool {
        analyticsNavigationHeader.isVisible &&
            (showAnalyticsView || showAccounts || showBudgetHub || showSubscriptionsHub ||
                selectedCategoryForSheet != nil || selectedAccountForSheet != nil)
    }

    // The same container survives Home, Transactions, and Analytics navigation.
    private var sharedNavigationHeader: some View {
        HomeNavigationHeader(
            detailHeader: isDetailHeaderVisible ? analyticsNavigationHeader : nil,
            isShowingTransactions: showAllTransactions,
            filtersExpanded: $transactionFiltersExpanded,
            hideBalance: $hideBalance,
            namespace: topControlsNamespace,
            onBack: { showAllTransactions = false },
            onSettings: {
                settingsInitialDestination = nil
                showSettings = true
            },
            onAnalytics: {
                let selection = $showAnalyticsView
                analyticsNavigationHeader.show(title: "Analytics", onBack: { selection.wrappedValue = false })
                analyticsInitialDate = nil
                showAnalyticsView = true
                HomeAnalyticsTip().invalidate(reason: .actionPerformed)
            },
            onBudget: {
                let selection = $showBudgetHub
                analyticsNavigationHeader.show(title: "Budget", onBack: { selection.wrappedValue = false })
                showBudgetHub = true
            },
            onConverter: { showCurrencyConverter = true }
        )
    }

    // MARK: - 2. Account Selector Dropdown Menu Chip
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
                    
                    Divider()
                    
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        let selection = $showAccounts
                        analyticsNavigationHeader.show(title: "Accounts", onBack: { selection.wrappedValue = false })
                        showAccounts = true
                    }) {
                        Label("Manage Accounts...", systemImage: "creditcard")
                    }
                    .accessibilityIdentifier("home-manage-accounts")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedAccountSymbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.primaryBlue)
                        
                        Text(selectedAccountLabel)
                            .font(.system(size: 13.5, weight: .bold, design: .default))
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
                
                Spacer()
            }
        }
    }
    
    // MARK: - 3. Hero Spend Section with On-Screen Month Bar Chart
    private var heroSpendBarSection: some View {
        HomeSpendingSummary(transactions: store.transactions, categories: store.categories,
            accountID: selectedAccountId, accountLabel: selectedAccountLabel,
            currencySymbol: store.currencySymbol, amountsHidden: hideBalance,
            insightsEnabled: store.insightsEnabled,
            tipGroup: homeTipGroup,
            onInsight: { destination, date in
                switch destination {
                case .category(let id):
                    let snapshot = SpendingChartSnapshot(transactions: store.transactions,
                        accountID: selectedAccountId, period: .month, anchor: date, referenceDate: Date())
                    categorySpendingScope = SpendingScope(start: snapshot.start, end: snapshot.end,
                        referenceDate: snapshot.referenceDate,
                        accountIDs: selectedAccountId == "all" ? nil : [selectedAccountId],
                        transactionType: .expense)
                    selectedCategoryForSheet = store.categories.first { $0.id == id }
                case .budget: showBudgetHub = true
                case .subscriptions: initialSubscriptionIdForHub = nil; showSubscriptionsHub = true
                case .subscriptionDetail(let id): initialSubscriptionIdForHub = id; showSubscriptionsHub = true
                case .transaction(let id): inspectingTransaction = store.transactions.first { $0.id == id }
                case .analytics: analyticsInitialDate = date; showAnalyticsView = true
                }
            }) { date in
                analyticsInitialDate = date
                showAnalyticsView = true
            }
            .environment(\.spendyTipsAllowed, tipsAllowed && !isSubpageActive && !showSettings)
    }

    // MARK: - 4. Interactive Bottom Transactions Drawer
    private func recentTransactionsDrawer(totalHeight: CGFloat, topInset: CGFloat, bottomInset: CGFloat) -> some View {
        let transactions = displayedTransactions
        let recentIDs = Set(transactions.prefix(3).map(\.id))
        let groups = drawerGroupedTransactions.compactMap { title, net, transactions -> (String, Double, [Transaction])? in
            let visible = isSheetExpanded ? transactions : transactions.filter { recentIDs.contains($0.id) }
            return visible.isEmpty ? nil : (title, net, visible)
        }
        return HomeActivityDrawer(
            totalHeight: totalHeight, topInset: topInset, bottomInset: bottomInset,
            isExpanded: Binding(get: { isSheetExpanded }, set: { setExpandedState($0) })
        ) { expansion, drag in
            let pinnedHeader = VStack(spacing: 0) {
                // A stable header keeps its identity and spacing throughout a drag.
                VStack(spacing: 0) {
                    Capsule()
                        .fill(SpendyColors.textTertiary)
                        .frame(width: 32, height: 4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                        .contentShape(Rectangle())
                        .onTapGesture { toggleActivityDrawer() }
                        .accessibilityHidden(true)

                    HStack(spacing: 12) {
                        Button { toggleActivityDrawer() } label: {
                            Text("Recent activity")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .foregroundStyle(SpendyColors.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isSheetExpanded ? "Collapse recent activity" : "Expand recent activity")
                        .accessibilityValue("\(transactions.count) transactions")

                        Button {
                            HapticsManager.shared.trigger(.selection)
                            showAllTransactions = true
                        } label: {
                            Text("See all")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("See all transactions")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
                }
                .contentShape(Rectangle())
                .highPriorityGesture(drag)

                // Keep the horizontal filters outside the drawer's vertical drag gesture.
                drawerFilterBar
                    .padding(.bottom, 12)
                    .frame(height: 56 * expansion, alignment: .top)
                    .clipped()
                    .opacity(expansion)
                    .allowsHitTesting(isSheetExpanded)
                    .accessibilityHidden(!isSheetExpanded)
            
            }

            return ZStack(alignment: .top) {
                // Activity scrolls behind the pinned controls and floating dock.
                ScrollView(showsIndicators: isSheetExpanded) {
                    if transactions.isEmpty {
                        emptyRecentActivityView
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(groups, id: \.0) { groupTitle, groupNet, txs in
                                VStack(alignment: .leading, spacing: 4 * expansion) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(groupTitle.uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(SpendyColors.textTertiary)
                                            .tracking(1.2)
                                    
                                        Spacer()
                                    
                                        Text(formattedGroupNetTotal(groupNet))
                                            .spendyNumberFont(size: 13, weight: .semibold, tracking: -0.2)
                                            .foregroundStyle(SpendyColors.textSecondary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 12)
                                    .padding(.bottom, 4)
                                    .frame(height: 30 * expansion, alignment: .bottom)
                                    .clipped()
                                    .opacity(expansion)
                                    .accessibilityHidden(!isSheetExpanded)

                                    ForEach(Array(txs.enumerated()), id: \.element.id) { index, tx in
                                        transactionRow(tx)
                                    
                                        if index < txs.count - 1 {
                                            Rectangle()
                                                .fill(SpendyColors.separator.opacity(0.6))
                                                .frame(height: 0.5 * expansion)
                                                .opacity(expansion)
                                                .padding(.leading, 64)
                                                .padding(.trailing, 16)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .safeAreaPadding(.top, 72 + 56 * expansion)
                .safeAreaPadding(.bottom, bottomInset + 78)
                .scrollDisabled(!isSheetExpanded)
                .frame(maxHeight: .infinity, alignment: .top)
                .accessibilityIdentifier("homeActivityViewport")

                pinnedHeader
            }
        }
    }

    // MARK: - Drawer Horizontal Filter Bar
    private var drawerFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 1. [Categories] Menu
                Menu {
                    Button("All Categories") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterCategoryId = nil
                        }
                    }
                    Divider()
                    ForEach(store.categories) { cat in
                        Button(cat.label) {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                drawerFilterCategoryId = cat.id
                            }
                        }
                    }
                } label: {
                    let isCatSelected = drawerFilterCategoryId != nil
                    HStack(spacing: 8) {
                        Image(systemName: isCatSelected ? (store.category(for: drawerFilterCategoryId ?? "").sfSymbol) : "circle.grid.2x2")
                            .font(.system(size: 14, weight: .semibold))
                        Text(drawerCategoryButtonLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isCatSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textTertiary)
                    }
                    .foregroundStyle(isCatSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .nativeLiquidGlassCapsule(isInteractive: true, tint: isCatSelected ? SpendyColors.elevatedControlFill : nil)
                }
                .buttonStyle(.plain)
                
                // 2. [Accounts] Menu
                Menu {
                    Button("All Accounts") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterAccountId = nil
                        }
                    }
                    Divider()
                    ForEach(store.accounts) { acc in
                        Button(acc.label) {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                drawerFilterAccountId = acc.id
                            }
                        }
                    }
                } label: {
                    let isAccSelected = drawerFilterAccountId != nil
                    HStack(spacing: 8) {
                        Image(systemName: isAccSelected ? (store.account(for: drawerFilterAccountId ?? "").sfSymbol.isEmpty ? "building.columns" : store.account(for: drawerFilterAccountId ?? "").sfSymbol) : "building.columns")
                            .font(.system(size: 14, weight: .semibold))
                        Text(drawerAccountButtonLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isAccSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textTertiary)
                    }
                    .foregroundStyle(isAccSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .nativeLiquidGlassCapsule(isInteractive: true, tint: isAccSelected ? SpendyColors.elevatedControlFill : nil)
                }
                .buttonStyle(.plain)
                
                // 3. [Type] Menu (Expenses, Income, Transfers)
                Menu {
                    Button("All Types") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterType = nil
                        }
                    }
                    Button("Expenses") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterType = .expense
                        }
                    }
                    Button("Income") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterType = .income
                        }
                    }
                    Button("Transfers") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterType = .transfer
                        }
                    }
                } label: {
                    let isTypeSelected = drawerFilterType != nil
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                        Text(drawerTypeButtonLabel)
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isTypeSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textTertiary)
                    }
                    .foregroundStyle(isTypeSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .nativeLiquidGlassCapsule(isInteractive: true, tint: isTypeSelected ? SpendyColors.elevatedControlFill : nil)
                }
                .buttonStyle(.plain)

                if hasActiveFilters {
                    Button {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(AppMotion.fluidSpring) { clearDrawerFilters() }
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear transaction filters")
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 20)
        }
        .accessibilityIdentifier("transactionFilters")
    }
    
    private func toggleActivityDrawer() {
        HapticsManager.shared.trigger(.selection)
        withAnimation(reduceMotion ? nil : AppMotion.fluidSpring) {
            setExpandedState(!isSheetExpanded)
        }
    }

    private func restingDrawerOffset(totalHeight: CGFloat, bottomInset: CGFloat) -> CGFloat {
        // Header + three 60-point rows + a small gap + the existing dock and safe area.
        let compactHeight: CGFloat = 72 + 3 * 60 + 42 + 56 + bottomInset
        return max(totalHeight * 0.55, totalHeight - compactHeight)
    }

    // MARK: - Transaction Row Item (Matches Exact Visual Design)
    private func transactionRow(_ tx: Transaction) -> some View {
        let cat = store.displayCategory(for: tx)
        let acc = store.account(for: tx.accountId)
        
        return Button(action: {
            HapticsManager.shared.trigger(.light)
            inspectingTransaction = tx
        }) {
            HStack(spacing: 12) {
                // Category Icon Badge matching exact reference design
                SpendyIconBadge(
                    sfSymbol: cat.sfSymbol,
                    color: cat.color,
                    size: .medium,
                    style: .circle,
                    monogramName: cat.label
                )
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.displayTitle(for: tx))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(tx.type == .transfer ? store.transferAccountRoute(for: tx) : acc.label)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        if tx.type != .transfer, let notes = tx.notes, !notes.isEmpty {
                            Text("• \(notes)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(SpendyColors.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Amount Value
                if hideBalance {
                    Text("••••")
                        .accessibilityLabel("Amount hidden")
                        .spendyNumberFont(size: 16, weight: .semibold, tracking: -0.2)
                        .foregroundStyle(SpendyColors.textSecondary)
                } else {
                    let formatted = tx.amount.formattedCurrency(symbol: store.currencySymbol)
                    Text(tx.type == .income ? "+\(formatted)" : formatted)
                        .spendyNumberFont(size: 16, weight: .semibold, tracking: -0.2)
                        .foregroundStyle(rowAmountColor(tx))
                        .accessibilityLabel("\(tx.type.title) amount, \(formatted)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home-activity-transaction-\(tx.id)")
    }
    
    private func rowAmountColor(_ tx: Transaction) -> Color {
        switch tx.type {
        case .expense:
            return SpendyColors.textPrimary
        case .income:
            return SpendyColors.incomeGreen
        case .transfer:
            return SpendyColors.textSecondary
        }
    }
    
    // MARK: - Empty State View
    private var emptyRecentActivityView: some View {
        SpendyPlainEmptyState(
            title: hasActiveFilters ? "No matching transactions" : "Your spending starts here",
            message: hasActiveFilters
                ? "Try clearing your filters to see more transactions."
                : "Add a transaction to see where your money goes.",
            icon: hasActiveFilters ? "line.3.horizontal.decrease" : "receipt",
            actionTitle: hasActiveFilters ? "Reset Filters" : "Add transaction"
        ) {
            if hasActiveFilters {
                withAnimation(AppMotion.snappySpring) {
                    clearDrawerFilters()
                }
            } else {
                showAddTransaction = true
            }
        }
    }
}

// MARK: - Profile Pill Press Style
private struct ProfilePillPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
