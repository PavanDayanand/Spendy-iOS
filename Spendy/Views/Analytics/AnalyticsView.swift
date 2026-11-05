//
//  AnalyticsView.swift
//  Spendy
//
//  Multi-Chart Financial Analytics Hub with Timeframe Granularities (Day/Week/Month/Year),
//  Single Scrollable Page Layout, Animated Chart Entrance Transitions ("Come to Life"),
//  Categories vs Accounts Toggles, Cashflow/Savings Rate Metrics, & Calibrated Pacing Charts.
//

import SwiftUI
import Charts

// MARK: - Time Granularity
enum TimeGranularity: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var id: String { rawValue }
}

// MARK: - Analytics Grouping Mode
enum AnalyticsGroupingMode: String, CaseIterable, Identifiable {
    case categories = "Categories"
    case accounts = "Accounts"
    
    var id: String { rawValue }
}


// MARK: - Breakdown Item Model (Category or Account)
struct AnalyticsBreakdownItem: Identifiable {
    let id: String
    let label: String
    let sfSymbol: String
    let colorHex: String
    let txCount: Int
    let amount: Double
    let percentage: Double
}

private struct ComparisonInterval: Identifiable {
    let index: Int
    let label: String
    let current: Double
    let previous: Double
    var id: Int { index }
    var difference: Double { current - previous }
}

private enum AnalyticsTonalColors {
    static let outer = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 15.0 / 255.0, alpha: 1)
            : .white
    })

    static let inset = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 25.0 / 255.0, alpha: 1)
            : UIColor(red: 245.0 / 255.0, green: 246.0 / 255.0, blue: 248.0 / 255.0, alpha: 1)
    })

    static let outline = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .clear
            : UIColor(white: 0, alpha: 0.10)
    })
}

private struct AnalyticsPanelStyle: ViewModifier {
    var verticalPadding: CGFloat = 20
    var horizontalPadding: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AnalyticsTonalColors.outer)
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(AnalyticsTonalColors.outline, lineWidth: 0.5)
                    }
            }
    }
}

struct AnalyticsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption2) private var comparisonChartHeight = 140.0
    var selectedTab: Binding<AppTab>? = nil
    var topControlsNamespace: Namespace.ID? = nil
    var sharedNavigationHeader: AnalyticsNavigationHeaderState? = nil
    var onDismiss: (() -> Void)? = nil
    var isSubpageActiveBinding: Binding<Bool>? = nil
    
    var initialAccountID: String = "all"
    var initialDate: Date? = nil
    @State private var appliedInitialScope = false
    @State private var selectedSpendingBucketID: String?
    @State private var selectedComparisonInterval: String?
    @State private var showsDirectInsights = false
    @State private var showsSpendingBreakdown = false
    @State private var pendingSpendingInsight: InsightDestination?
    @State private var referenceDate = Date()

    private var spendingSnapshot: SpendingChartSnapshot {
        SpendingChartSnapshot(transactions: store.transactions, accountID: selectedAccountId,
            period: SpendingChartPeriod(rawValue: granularity.rawValue.lowercased()) ?? .month,
            anchor: selectedDate, referenceDate: referenceDate, transactionType: transactionType)
    }

    // View Filters & Navigation State
    private var quickActions: QuickActionManager { QuickActionManager.shared }
    @State private var groupingMode: AnalyticsGroupingMode = .categories
    @State private var granularity: TimeGranularity = .month
    @State private var selectedDate: Date = Date()
    @State private var showMonthPicker: Bool = false
    @State private var selectedAccountId: String = "all"
    @State private var transactionType: TransactionType = .expense
    private var isIncome: Bool { transactionType == .income }
    private var selectedBreakdownItems: [AnalyticsBreakdownItem] { isIncome ? incomeBreakdownItems : spendingBreakdownItems }
    
    // Interactive Selected Chart Items
    @State private var selectedCategoryForSheet: Category? = nil
    @State private var isBreakdownExpanded = false
    @State private var selectedAccountForSheet: Account? = nil
    @State private var showSubscriptionSheet: Bool = false
    @State private var selectedSubscriptionIdForDetail: String? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var pendingTransactionEdit: Transaction? = nil
    @State private var inspectingTransaction: Transaction? = nil
    @State private var showEditBudgetSheet: Bool = false
    @State private var showBudgetHub = false
    @State private var showAddTransaction: Bool = false
    
    @Namespace private var analyticsTransitions
    @Namespace private var analyticsControlsNamespace
    
    private var isSubpageActive: Bool {
        showsSpendingBreakdown || showSubscriptionSheet || showBudgetHub ||
        selectedAccountForSheet != nil ||
        selectedCategoryForSheet != nil
    }
    
    private let calendar = Calendar.current
    
    // Computed helpers for account dropdown
    private var selectedAccountLabel: String {
        if selectedAccountId == "all" { return "All Accounts" }
        return store.accounts.first(where: { $0.id == selectedAccountId })?.label ?? "Account"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            SpendyColors.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 18, pinnedViews: [.sectionHeaders]) {
                    if sharedNavigationHeader == nil || (topControlsNamespace == nil && onDismiss == nil) {
                        headerBar
                            .padding(.horizontal, 20)
                            .padding(.top, topControlsNamespace != nil ? 4 : 10)
                    }

                    Section {
                        VStack(spacing: 16) {
                            spendingRhythmCard.modifier(AnalyticsPanelStyle(verticalPadding: 4, horizontalPadding: 4))
                            spendingMixSection.modifier(AnalyticsPanelStyle(verticalPadding: 12))
                            periodComparisonCard.modifier(AnalyticsPanelStyle(verticalPadding: 4, horizontalPadding: 4))
                            AnalyticsBudgetSummary { showBudgetHub = true }
                                .modifier(AnalyticsPanelStyle(verticalPadding: 16))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    } header: {
                        compactHeader
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 12)
                    }
                }
                .padding(.bottom, 24)
            }
            .safeAreaBar(edge: .top, spacing: 0) {
                if sharedNavigationHeader != nil && (topControlsNamespace != nil || onDismiss != nil) {
                    // The persistent header remains in its parent overlay during navigation.
                    Color.clear.frame(height: 66).accessibilityHidden(true)
                }
            }
            .accessibilityIdentifier("analytics-scroll")
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
            .sheet(isPresented: $showsDirectInsights, onDismiss: {
                if let destination = pendingSpendingInsight {
                    pendingSpendingInsight = nil
                    openInsight(destination)
                }
            }) {
                SpendingChartInfoSheet(snapshot: spendingSnapshot, accountLabel: selectedAccountLabel,
                    currencySymbol: store.currencySymbol, insights: currentPeriodInsights, insightsOnly: true,
                    onSelectInsight: { destination in
                        pendingSpendingInsight = destination
                        showsDirectInsights = false
                    })
            }
            .navigationDestination(isPresented: $showsSpendingBreakdown) {
                SpendingBreakdownSheet(snapshot: spendingSnapshot, items: selectedBreakdownItems,
                    byCategory: groupingMode == .categories, accountLabel: selectedAccountLabel, accountID: selectedAccountId,
                    topControlsNamespace: analyticsControlsNamespace,
                    sharedNavigationHeader: sharedNavigationHeader)
            }
            .sheet(isPresented: $showMonthPicker) {
                datePickerSheet
            }
            .navigationDestination(isPresented: $showSubscriptionSheet) {
                SubscriptionsView(isPushed: true, initialSelectedSubscriptionId: selectedSubscriptionIdForDetail,
                    topControlsNamespace: analyticsControlsNamespace, sharedNavigationHeader: sharedNavigationHeader)
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
            .navigationDestination(isPresented: $showBudgetHub) {
                BudgetView(topControlsNamespace: analyticsControlsNamespace, sharedNavigationHeader: sharedNavigationHeader)
            }
            .fullScreenCover(isPresented: $showEditBudgetSheet) {
                EditBudgetSheet(isEditing: store.budget.isActive)
            }
            .navigationDestination(item: $selectedAccountForSheet) { account in
                AccountAnalyticsSheet(
                    account: account,
                    spendingScope: SpendingScope(start: spendingSnapshot.start, end: spendingSnapshot.end, referenceDate: referenceDate, transactionType: transactionType),
                    topControlsNamespace: analyticsControlsNamespace,
                    sharedNavigationHeader: sharedNavigationHeader
                )
            }
            .navigationDestination(item: $selectedCategoryForSheet) { category in
                CategoryAnalyticsSheet(
                    category: category,
                    spendingScope: SpendingScope(start: spendingSnapshot.start, end: spendingSnapshot.end,
                        referenceDate: referenceDate, accountIDs: selectedAccountId == "all" ? nil : [selectedAccountId], transactionType: transactionType),
                    topControlsNamespace: analyticsControlsNamespace,
                    sharedNavigationHeader: sharedNavigationHeader
                )
            }

            .onAppear {
                isSubpageActiveBinding?.wrappedValue = isSubpageActive
                referenceDate = Date()
                if !appliedInitialScope {
                    selectedAccountId = initialAccountID
                    if let initialDate { selectedDate = initialDate }
                    appliedInitialScope = true
                }
                openRequestedWeek()
                configureNavigationHeader()
            }
            .onChange(of: quickActions.requestedAnalyticsWeekDate) { _, _ in openRequestedWeek() }
            .onChange(of: isSubpageActive) { _, active in
                if !active {
                    configureNavigationHeader()
                }
                withAnimation(AppMotion.fluidSpring) {
                    isSubpageActiveBinding?.wrappedValue = active
                }
            }
            .onChange(of: store.transactions) { _, _ in referenceDate = Date() }
            .onChange(of: selectedDate) { _, _ in resetSelections() }
            .onChange(of: granularity) { _, _ in resetSelections() }
            .onChange(of: transactionType) { _, _ in resetSelections() }
            .onChange(of: selectedAccountId) { _, _ in resetSelections() }
            .navigationBarBackButtonHidden(true)
            .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private func configureNavigationHeader() {
        guard selectedCategoryForSheet == nil, selectedAccountForSheet == nil else { return }
        let backAction = onDismiss
        let dismissAction = dismiss
        sharedNavigationHeader?.show(title: "Analytics",
            isVisible: topControlsNamespace != nil || onDismiss != nil,
            onBack: {
                if let backAction { backAction() } else { dismissAction() }
            })
    }

    private func openRequestedWeek() {
        guard topControlsNamespace == nil, let date = quickActions.requestedAnalyticsWeekDate else { return }
        granularity = .week
        selectedDate = date
        quickActions.requestedAnalyticsWeekDate = nil
    }

    private var analyticsInsights: [InsightMoment] {
        guard store.insightsEnabled else { return [] }
        let bounds = currentPeriodBounds
        let unit: Calendar.Component = granularity == .day ? .day : granularity == .week ? .weekOfYear : granularity == .month ? .month : .year
        let previousDate = Calendar.current.date(byAdding: unit, value: -1, to: selectedDate) ?? selectedDate
        let previous = periodBounds(for: previousDate)
        let period: InsightPeriod = granularity == .week ? .week : granularity == .month ? .month : granularity == .year ? .year : .custom
        let context = AnalyticsInsightContext(scope: selectedAccountId == "all" ? .global : .account(id: selectedAccountId),
            period: period, startDate: bounds.start, endDate: bounds.end,
            baselineStartDate: previous.start, baselineEndDate: previous.end,
            referenceDate: referenceDate)
        let facts = InsightFactsExtractor.extractFacts(transactions: store.transactions, budget: store.budget,
            categories: store.categories, subscriptions: store.subscriptions, context: context)
        return InsightDecisionEngine.shared.evaluate(facts: facts, surface: .analytics, currencySymbol: store.currencySymbol)
            .filter { !$0.isInsufficientData }
    }

    private func openInsight(_ destination: InsightDestination) {
        switch destination {
        case .category(let id): selectedCategoryForSheet = store.categories.first { $0.id == id }
        case .budget: showBudgetHub = true
        case .subscriptions:
            selectedSubscriptionIdForDetail = nil
            showSubscriptionSheet = true
        case .subscriptionDetail(let id):
            selectedSubscriptionIdForDetail = id
            showSubscriptionSheet = true
        case .transaction(let id): inspectingTransaction = store.transactions.first { $0.id == id }
        case .analytics: break
        }
    }

    private var currentPeriodInsights: [InsightMoment] {
        if isIncome {
            let incomeMoments = analyticsInsights.filter { $0.family == .income }
            if !incomeMoments.isEmpty {
                return incomeMoments
            }
            let incomeTxs = filteredTransactions.filter { $0.type == .income }
            guard !incomeTxs.isEmpty else { return [] }
            let total = totalIncome
            let topCategory = incomeBreakdownItems.first
            let headline: String
            let supporting: String
            if let topCategory {
                headline = "\(topCategory.label) is your top income source"
                supporting = "\(topCategory.percentage.formatted(.number.precision(.fractionLength(0))))% (\(topCategory.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))) of total recorded income this period."
            } else {
                headline = "\(incomeTxs.count) income deposits recorded"
                supporting = "Total income recorded for this period is \(total.formattedCurrency(symbol: store.currencySymbol, decimals: 0))."
            }
            return [
                InsightMoment(
                    id: "income_overview_\(granularity.rawValue)_\(selectedAccountId)",
                    candidateId: "income_overview",
                    kind: .observation,
                    family: .income,
                    surface: .analytics,
                    period: granularity == .week ? .week : granularity == .month ? .month : granularity == .year ? .year : .custom,
                    headline: headline,
                    supportingText: supporting,
                    emphasis: [.currency(total)]
                )
            ]
        } else {
            return analyticsInsights
        }
    }

    // MARK: - Spending over time
    private var spendingRhythmCard: some View {
        let snapshot = spendingSnapshot
        let selected = snapshot.buckets.first { $0.id == selectedSpendingBucketID }
        return VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(selected.map { spendingPeriodLabel(snapshot, selected: $0) } ?? (isIncome ? "Income" : "Spending"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Spacer(minLength: 4)
                    if selected != nil {
                        Button {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(AppMotion.fluidSpring) {
                                selectedSpendingBucketID = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Reset")
                                    .font(.caption2.weight(.semibold))
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                            .foregroundStyle(SpendyColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear period selection")
                    }
                }
                Text((selected?.amount ?? snapshot.total).formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.largeTitle.bold().monospacedDigit())
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .accessibilityIdentifier("analytics-spending-total")
                    .accessibilityValue((selected?.amount ?? snapshot.total).formattedCurrency(symbol: store.currencySymbol, decimals: 2))
                if !snapshot.transactions.isEmpty {
                    SpendingChartPlot(buckets: snapshot.buckets, currencySymbol: store.currencySymbol,
                                      selectedID: $selectedSpendingBucketID, height: 140, transactionType: snapshot.transactionType)
                        .padding(.top, 8)
                } else {
                    SpendyPlainEmptyState(
                        title: isIncome ? "No income yet" : "No spending yet",
                        message: isIncome ? "Income for this period will appear here." : "Spending for this period will appear here.",
                        compact: true
                    )
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AnalyticsTonalColors.inset, in: RoundedRectangle(cornerRadius: 22))
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedSpendingBucketID != nil {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(AppMotion.fluidSpring) {
                        selectedSpendingBucketID = nil
                    }
                }
            }

            if store.insightsEnabled && !snapshot.transactions.isEmpty {
                Button { showsDirectInsights = true } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            SpendyInsightBrandMark(style: .kicker, showsPersonalization: false)
                            Text(currentPeriodInsights.first?.headline ?? (isIncome ? "Explore your recorded income" : "Explore your recorded spending"))
                                .font(.caption)
                                .foregroundStyle(SpendyColors.textSecondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isIncome ? "Open Income Insights" : "Open Spendy Insights")
                .accessibilityValue(currentPeriodInsights.first?.headline ?? (isIncome ? "Explore your recorded income" : "Explore your recorded spending"))
                .accessibilityIdentifier("open-spendy-insights")
                .padding(.top, 4)
                .padding(.horizontal, 10)
            }

        }
        .tint(SpendyColors.textPrimary)
    }

    private func spendingPeriodLabel(_ snapshot: SpendingChartSnapshot, selected: SpendingChartBucket?) -> String {
        if let selected {
            let date = selected.start.formatted(.dateTime.day().month(.abbreviated).year())
            if snapshot.period == .month {
                return "\(selected.label) \(selected.start.formatted(.dateTime.month(.abbreviated))) · \(selected.transactionCount) transactions\(selected.isInProgress ? " · To date" : "")"
            }
            return "\(date) · \(selected.transactionCount) transactions"
        }
        let start = snapshot.start.formatted(.dateTime.day().month(.abbreviated).year())
        let end = max(snapshot.start, snapshot.recordedEnd).formatted(.dateTime.day().month(.abbreviated).year())
        return "\(start) – \(end)" + (snapshot.isInProgress ? " · To date" : "")
    }

    private var periodComparisonCard: some View {
        let snapshot = spendingSnapshot
        let intervals = comparisonIntervals
        let highlighted = intervals.first(where: { $0.label == selectedComparisonInterval })
            ?? intervals.max(by: { abs($0.difference) < abs($1.difference) })
        let maximum = max(intervals.map { max($0.current, $0.previous) }.max() ?? 0, 1)
        let activeIntervals = intervals.filter { $0.current > 0 || $0.previous > 0 }

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(isIncome ? "Income compared" : "Spending compared")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                if snapshot.hasBaselineRecords && !snapshot.isFuture {
                    Text(comparisonHeadline)
                        .font(.title3.bold())
                        .foregroundStyle(SpendyColors.textPrimary)
                    Text(comparisonDifferenceText)
                        .font(.caption)
                        .foregroundStyle(SpendyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if snapshot.isFuture {
                SpendyPlainEmptyState(
                    title: "This period hasn't started",
                    message: "The comparison will appear when you have activity in this period.",
                    compact: true
                )
            } else if snapshot.hasBaselineRecords {
                VStack(alignment: .leading, spacing: 12) {
                    if activeIntervals.count > 1 {
                        (dynamicTypeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                            : AnyLayout(HStackLayout(spacing: 16))) {
                            comparisonKey(comparisonPeriodLabel(snapshot.start, period: snapshot.period), opacity: 1)
                            comparisonKey(comparisonPeriodLabel(snapshot.baselineStart, period: snapshot.period), opacity: 0.35)
                        }

                        Chart(intervals) { interval in
                            BarMark(
                                x: .value("Interval", interval.label),
                                y: .value("This period", interval.current)
                            )
                            .position(by: .value("Period", "This"))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
                            .accessibilityLabel("\(interval.label), this \(snapshot.period.rawValue)")
                            .accessibilityValue(interval.current.formattedCurrency(symbol: store.currencySymbol, decimals: 0))

                            BarMark(
                                x: .value("Interval", interval.label),
                                y: .value("Last period", interval.previous)
                            )
                            .position(by: .value("Period", "Last"))
                            .foregroundStyle(SpendyColors.textPrimary.opacity(0.35))
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
                            .accessibilityLabel("\(interval.label), last \(snapshot.period.rawValue)")
                            .accessibilityValue(interval.previous.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        }
                        .chartLegend(.hidden)
                        .chartXSelection(value: $selectedComparisonInterval)
                        .chartYScale(domain: 0...(maximum * 1.15))
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(SpendyColors.textSecondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                                    .foregroundStyle(SpendyColors.separator)
                                AxisValueLabel {
                                    if let amount = value.as(Double.self) {
                                        Text(formatAxisAmount(amount))
                                            .font(.caption2)
                                            .foregroundStyle(SpendyColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .frame(height: min(comparisonChartHeight, 210))
                    } else if let highlighted {
                        Text("Activity in \(comparisonIntervalName(highlighted))")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        HStack(spacing: 12) {
                            comparisonAmount(snapshot.start, snapshot.period, amount: highlighted.current)
                            comparisonAmount(snapshot.baselineStart, snapshot.period, amount: highlighted.previous)
                        }
                    }

                    if activeIntervals.count > 1, let highlighted {
                        Rectangle()
                            .fill(SpendyColors.separator)
                            .frame(height: 0.5)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(comparisonIntervalCaption(highlighted))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                            Spacer(minLength: 4)
                            Text(comparisonIntervalChange(highlighted))
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundStyle(SpendyColors.textPrimary)
                        }
                    }
                }
            } else {
                SpendyPlainEmptyState(
                    title: "No previous period yet",
                    message: "Once you have records in two periods, you'll see how they compare.",
                    compact: true
                )
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AnalyticsTonalColors.inset, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("analytics-period-comparison")
    }

    private func comparisonKey(_ label: String, opacity: Double) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(SpendyColors.textPrimary.opacity(opacity))
                .frame(width: 11, height: 11)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(SpendyColors.textSecondary)
        }
    }

    private func comparisonAmount(_ start: Date, _ period: SpendingChartPeriod, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(comparisonPeriodLabel(start, period: period))
                .font(.caption2.weight(.medium))
                .foregroundStyle(SpendyColors.textSecondary)
            Text(amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var spendingMixSection: some View {
        let allItems = selectedBreakdownItems
        let items = Array(allItems.prefix(3))
        let visibleItems = items

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(groupingMode == .categories ? (isIncome ? "Category income" : "Category spending") : (isIncome ? "Account income" : "Account spending"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                Spacer()
            }

            if items.isEmpty {
                SpendyPlainEmptyState(
                    title: isIncome ? "No income yet" : "No spending yet",
                    message: isIncome ? "Income by category will appear here." : "Spending by category will appear here.",
                    compact: true
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                        Button {
                            HapticsManager.shared.trigger(.selection)
                            if groupingMode == .categories {
                                selectedCategoryForSheet = store.categories.first { $0.id == item.id }
                            } else {
                                selectedAccountForSheet = store.accounts.first { $0.id == item.id }
                            }
                        } label: {
                            breakdownLegendRow(item, index: index)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Open \(groupingMode == .categories ? "category" : "account") analytics")
                        .accessibilityIdentifier("breakdown-\(item.id)")
                        .spendyNavigationSource(
                            groupingMode == .categories ? AppTransitionIDs.categoryCard(item.id) : AppTransitionIDs.accountCard(item.id),
                            in: analyticsTransitions)
                        if index < visibleItems.count - 1 {
                            Divider().overlay(SpendyColors.separator)
                        }
                    }
                }
            }
            if !allItems.isEmpty {
                Button { showsSpendingBreakdown = true } label: {
                    HStack {
                        Text("View all")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("expand-spending-breakdown")
            }
        }
    }

    private func breakdownLegendRow(_ item: AnalyticsBreakdownItem, index: Int) -> some View {
        HStack(spacing: 10) {
            SpendyIconBadge(sfSymbol: item.sfSymbol, color: SpendyColors.isMonoMode ? SpendyColors.textPrimary.opacity(1 - Double(index) * 0.12) : Color(hex: item.colorHex),
                size: .small, style: .circle, monogramName: item.label)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.label).font(.subheadline.weight(.medium))
                    .foregroundStyle(SpendyColors.textPrimary)
                Text("\(item.txCount) \(isIncome ? (item.txCount == 1 ? "income transaction" : "income transactions") : (item.txCount == 1 ? "expense" : "expenses"))")
                    .font(.caption).foregroundStyle(SpendyColors.textSecondary)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 3) {
                Text(item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                    .foregroundStyle(SpendyColors.textPrimary)
                Text("\(item.percentage.formatted(.number.precision(.fractionLength(0))))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            .lineLimit(1).minimumScaleFactor(0.75)
        }
        .padding(.vertical, 8)
        .frame(minHeight: 48)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.label), \(item.txCount) \(isIncome ? "income transactions" : "expenses"), \(item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 2)), \(item.percentage.formatted(.number.precision(.fractionLength(1)))) percent")
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(alignment: .center) {
            if topControlsNamespace != nil || onDismiss != nil {
                GlassCircleButton(
                    icon: "chevron.left",
                    size: 44,
                    iconSize: 15,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .selection,
                    accessibilityLabel: "Back",
                    morphID: "topControl_left",
                    namespace: topControlsNamespace
                ) {
                    if let onDismiss = onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                }
                
                Spacer()
                
                Text("Analytics")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Color.clear
                    .frame(width: 44, height: 44)
            } else {
                Text("Analytics")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
            }
        }
    }
    
    // MARK: - 1. Compact Header Row
    private var compactHeader: some View {
        SpendyGlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                // Left: Timeframe Granularity Selector (Apple Native Picker with Checkmarks)
                Menu {
                    Picker("Timeframe", selection: $granularity) {
                        ForEach(TimeGranularity.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                } label: {
                    GlassCircleIcon(
                        icon: "calendar",
                        size: 44,
                        iconSize: 16,
                        iconWeight: .bold,
                        foregroundColor: SpendyColors.textPrimary,
                        morphID: "calendarMenu",
                        namespace: analyticsControlsNamespace
                    )
                }
                .accessibilityLabel("Select Timeframe")
                
                Spacer()
                
                // Center: Period Navigation  ◀  Aug 2026  ▶
                HStack(spacing: 2) {
                    Button(action: { stepPeriod(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(width: 36, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        HapticsManager.shared.trigger(.light)
                        showMonthPicker = true
                    }) {
                        Text(formattedPillTitle)
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .contentTransition(.numericText())
                            .frame(height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { stepPeriod(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(width: 36, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
                .frame(height: 44)
                .nativeLiquidGlassCapsule(isInteractive: true)
                .glassMorphID("periodNavCapsule", in: analyticsControlsNamespace)
                
                Spacer()
                
                // Right: Settings Menu (Account Filter + Category/Account Grouping with Apple Native Pickers)
                let isFiltered = selectedAccountId != "all" || isIncome
                let filterCount = (selectedAccountId != "all" ? 1 : 0) + (isIncome ? 1 : 0)
                Menu {
                    Section("Transaction type") {
                        Picker("Transaction type", selection: $transactionType) {
                            Label("Expenses", systemImage: "arrow.up.right").tag(TransactionType.expense)
                            Label("Income", systemImage: "arrow.down.left").tag(TransactionType.income)
                        }
                    }
                    Section("Filter by Account") {
                        Picker("Account", selection: $selectedAccountId) {
                            Label("All Accounts", systemImage: "wallet.pass.fill")
                                .tag("all")
                            ForEach(store.accounts) { acc in
                                Label(acc.label, systemImage: acc.sfSymbol)
                                    .tag(acc.id)
                            }
                        }
                    }
                    
                    if selectedAccountId != "all" {
                        Button("Reset account filter") { selectedAccountId = "all" }
                    }
                    Section("Group Breakdown") {
                        Picker("Grouping", selection: $groupingMode) {
                            Label("Categories", systemImage: "square.grid.2x2.fill")
                                .tag(AnalyticsGroupingMode.categories)
                            Label("Accounts", systemImage: "building.columns.fill")
                                .tag(AnalyticsGroupingMode.accounts)
                        }
                    }
                    

                } label: {
                    GlassCircleIcon(
                        icon: "line.3.horizontal.decrease",
                        size: 44,
                        iconSize: 18,
                        iconWeight: .semibold,
                        tintColor: nil,
                        foregroundColor: SpendyColors.textPrimary,
                        morphID: "settingsMenu",
                        namespace: analyticsControlsNamespace
                    )
                }
                .overlay(alignment: .topTrailing) {
                    if isFiltered {
                        Text("\(filterCount)")
                            .font(.caption2.bold().monospacedDigit())
                            .foregroundStyle(SpendyColors.inverseText)
                            .padding(4)
                            .background(SpendyColors.textPrimary, in: Circle())
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel("Analytics filters")
                .accessibilityValue("\(isIncome ? "Income" : "Expenses"), \(selectedAccountLabel)")
                .accessibilityIdentifier("analytics-filters")
            }
        }
    }

    // MARK: - Date Picker Modal Sheet (Pure Native Liquid Glass)
    private var datePickerSheet: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    DatePicker(
                        "Choose Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(SpendyColors.primaryBlue)
                    .padding()
                    .nativeLiquidGlass(cornerRadius: 20, isInteractive: true)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Select Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showMonthPicker = false
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.primaryBlue)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
    
    // MARK: - Computed Properties & Period Math
    
    private var currentPeriodBounds: (start: Date, end: Date) {
        periodBounds(for: selectedDate)
    }

    private func periodBounds(for date: Date) -> (start: Date, end: Date) {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let period = SpendingChartPeriod(rawValue: granularity.rawValue.lowercased()) ?? .month
        let interval = calendar.dateInterval(of: period.component, for: date)!
        return (interval.start, Date(timeIntervalSinceReferenceDate: interval.end.timeIntervalSinceReferenceDate.nextDown))
    }

    private var filteredTransactions: [Transaction] {
        let snapshot = spendingSnapshot
        return store.filteredTransactions(for: selectedAccountId).filter {
            $0.date >= snapshot.start && $0.date < snapshot.end && $0.date <= referenceDate
        }
    }

    private var totalSpending: Double {
        spendingSnapshot.total
    }

    private var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
    }

    private var previousPeriodSnapshot: SpendingChartSnapshot {
        SpendingChartSnapshot(
            transactions: store.transactions,
            accountID: selectedAccountId,
            period: spendingSnapshot.period,
            anchor: spendingSnapshot.baselineStart,
            referenceDate: spendingSnapshot.baselineCutoff,
            transactionType: transactionType
        )
    }

    private var comparisonIntervals: [ComparisonInterval] {
        let previousBuckets = previousPeriodSnapshot.buckets
        return spendingSnapshot.buckets.enumerated().map { index, bucket in
            ComparisonInterval(
                index: index,
                label: bucket.label,
                current: bucket.amount,
                previous: index < previousBuckets.count ? previousBuckets[index].amount : 0
            )
        }
    }

    private func comparisonIntervalCaption(_ interval: ComparisonInterval) -> String {
        let name = comparisonIntervalName(interval)
        return selectedComparisonInterval == nil ? "Biggest change · \(name)" : name
    }

    private func comparisonIntervalName(_ interval: ComparisonInterval) -> String {
        let prefix: String
        switch spendingSnapshot.period {
        case .day: prefix = "\(interval.label)"
        case .week: prefix = "\(interval.label)"
        case .month: prefix = "Days \(interval.label)"
        case .year: prefix = "\(interval.label)"
        }
        return prefix
    }

    private func comparisonIntervalChange(_ interval: ComparisonInterval) -> String {
        let amount = abs(interval.difference).formattedCurrency(symbol: store.currencySymbol, decimals: 0)
        if abs(interval.difference) < 0.005 { return isIncome ? "Same income" : "Same spending" }
        return "\(amount) \(interval.difference < 0 ? "less" : "more")"
    }

    private func comparisonPeriodLabel(_ start: Date, period: SpendingChartPeriod) -> String {
        switch period {
        case .day:
            start.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        case .week:
            "Week of \(start.formatted(.dateTime.month(.abbreviated).day()))"
        case .month:
            start.formatted(.dateTime.month(.abbreviated).year())
        case .year:
            start.formatted(.dateTime.year())
        }
    }

    private var comparisonHeadline: String {
        let snapshot = spendingSnapshot
        guard snapshot.hasBaselineRecords else { return "No comparison yet" }
        guard snapshot.baselineTotal > 0 else {
            return snapshot.total == 0 ? "Same as previous" : "New activity this period"
        }
        let percentage = abs((snapshot.total - snapshot.baselineTotal) / snapshot.baselineTotal) * 100
        if percentage < 0.5 { return "About the same" }
        return "\(percentage.formatted(.number.precision(.fractionLength(0))))% \(snapshot.total > snapshot.baselineTotal ? "more" : "less")"
    }

    private var comparisonDifferenceText: String {
        let snapshot = spendingSnapshot
        let difference = snapshot.total - snapshot.baselineTotal
        let previousPeriod: String
        switch snapshot.period {
        case .day:
            previousPeriod = snapshot.isInProgress ? "the same time yesterday" : "the previous day"
        case .week, .month, .year:
            previousPeriod = snapshot.isInProgress
                ? "the same point last \(snapshot.period.rawValue)"
                : "the previous \(snapshot.period.rawValue)"
        }
        if abs(difference) < 0.005 { return "Same amount as \(previousPeriod)" }
        let amount = abs(difference).formattedCurrency(symbol: store.currencySymbol, decimals: 0)
        return "\(amount) \(difference < 0 ? "less" : "more") than \(previousPeriod)"
    }
    
    /// Spending breakdown grouped either by Category or Account
    private var spendingBreakdownItems: [AnalyticsBreakdownItem] {
        let expenseTxs = filteredTransactions.filter { $0.type == .expense }
        let total = totalSpending
        
        if groupingMode == .categories {
            let grouped = Dictionary(grouping: expenseTxs, by: { $0.categoryId })
            return grouped.map { catId, list in
                let cat = store.category(for: catId)
                let sum = list.reduce(0.0) { $0 + $1.amount }
                let pct = total > 0 ? (sum / total) * 100 : 0.0
                return AnalyticsBreakdownItem(
                    id: catId,
                    label: cat.label,
                    sfSymbol: cat.sfSymbol,
                    colorHex: cat.colorHex,
                    txCount: list.count,
                    amount: sum,
                    percentage: pct
                )
            }.sorted { $0.amount > $1.amount }
        } else {
            let grouped = Dictionary(grouping: expenseTxs, by: { $0.accountId })
            return grouped.map { accId, list in
                let acc = store.account(for: accId)
                let sum = list.reduce(0.0) { $0 + $1.amount }
                let pct = total > 0 ? (sum / total) * 100 : 0.0
                return AnalyticsBreakdownItem(
                    id: accId,
                    label: acc.label,
                    sfSymbol: acc.sfSymbol,
                    colorHex: acc.colorHex,
                    txCount: list.count,
                    amount: sum,
                    percentage: pct
                )
            }.sorted { $0.amount > $1.amount }
        }
    }
    
    /// Income breakdown grouped either by Category or Account
    private var incomeBreakdownItems: [AnalyticsBreakdownItem] {
        let incTxs = filteredTransactions.filter { $0.type == .income }
        let total = totalIncome
        
        if groupingMode == .categories {
            let grouped = Dictionary(grouping: incTxs, by: { $0.categoryId })
            return grouped.map { catId, list in
                let cat = store.category(for: catId)
                let sum = list.reduce(0.0) { $0 + $1.amount }
                let pct = total > 0 ? (sum / total) * 100 : 0.0
                return AnalyticsBreakdownItem(
                    id: catId,
                    label: cat.label,
                    sfSymbol: cat.sfSymbol,
                    colorHex: cat.colorHex,
                    txCount: list.count,
                    amount: sum,
                    percentage: pct
                )
            }.sorted { $0.amount > $1.amount }
        } else {
            let grouped = Dictionary(grouping: incTxs, by: { $0.accountId })
            return grouped.map { accId, list in
                let acc = store.account(for: accId)
                let sum = list.reduce(0.0) { $0 + $1.amount }
                let pct = total > 0 ? (sum / total) * 100 : 0.0
                return AnalyticsBreakdownItem(
                    id: accId,
                    label: acc.label,
                    sfSymbol: acc.sfSymbol,
                    colorHex: acc.colorHex,
                    txCount: list.count,
                    amount: sum,
                    percentage: pct
                )
            }.sorted { $0.amount > $1.amount }
        }
    }
    
    private var formattedPillTitle: String {
        switch granularity {
        case .day, .week:
            return SpendyDateFormatterCache.dayMonth.string(from: selectedDate)
        case .month:
            return SpendyDateFormatterCache.monthYearShort.string(from: selectedDate)
        case .year:
            return SpendyDateFormatterCache.year.string(from: selectedDate)
        }
    }
    
    private func stepPeriod(by delta: Int) {
        HapticsManager.shared.trigger(.selection)
        let component: Calendar.Component
        switch granularity {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        if let newDate = calendar.date(byAdding: component, value: delta, to: selectedDate) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedDate = newDate
            }
        }
    }
    
    private func formatAxisAmount(_ amount: Double) -> String {
        if amount == 0 { return "0" }
        let sym = store.currencySymbol
        if amount >= 100_000 {
            return "\(sym)\(Int(amount / 1000))k"
        } else if amount >= 1_000 {
            let val = amount / 1000
            let formatted = val.formatted(.number.precision(.fractionLength(val.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1)))
            return "\(sym)\(formatted)k"
        } else {
            return "\(sym)\(Int(amount))"
        }
    }
    
    

    
    private func resetSelections() {
        selectedSpendingBucketID = nil
        referenceDate = Date()
    }
}

#Preview {
    AnalyticsView()
        .environment(ExpenseStore())
        .preferredColorScheme(.dark)
}
