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

// MARK: - Interval Data Model for Multi-Charts
struct PeriodIntervalData: Identifiable {
    let id: String
    let label: String
    let startDate: Date
    let endDate: Date
    let spendingAmount: Double
    let incomeAmount: Double
    
    init(label: String, startDate: Date, endDate: Date, spendingAmount: Double, incomeAmount: Double) {
        self.id = "\(label)-\(startDate.timeIntervalSince1970)"
        self.label = label
        self.startDate = startDate
        self.endDate = endDate
        self.spendingAmount = spendingAmount
        self.incomeAmount = incomeAmount
    }
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

private struct RecordedDay: Identifiable {
    let date: Date
    /// Nil means outside the recorded history or an unfinished day with no entry.
    let hasExpense: Bool?
    var id: Date { date }
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
    @State private var quickActions = QuickActionManager.shared
    @State private var groupingMode: AnalyticsGroupingMode = .categories
    @State private var granularity: TimeGranularity = .month
    @State private var selectedDate: Date = Date()
    @State private var showMonthPicker: Bool = false
    @State private var selectedAccountId: String = "all"
    @State private var transactionType: TransactionType = .expense
    private var isIncome: Bool { transactionType == .income }
    private var selectedBreakdownItems: [AnalyticsBreakdownItem] { isIncome ? incomeBreakdownItems : spendingBreakdownItems }
    
    // Chart State
    @State private var chartProgress: Double = 1.0
    
    // Interactive Selected Chart Items
    @State private var selectedCashflowLabel: String? = nil
    @State private var selectedSpendingLabel: String? = nil
    @State private var selectedIncomeLabel: String? = nil
    @State private var selectedCategorySectorId: String? = nil
    @State private var selectedIncomeSectorId: String? = nil
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
    
    // Collapsible List Expand States
    @State private var isSpendingListExpanded: Bool = false
    @State private var isIncomeListExpanded: Bool = false
    
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
                            analyticsKPIGrid
                            periodComparisonCard.modifier(AnalyticsPanelStyle(verticalPadding: 4, horizontalPadding: 4))
                            if !isIncome { recordedDaysSection }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                    } header: {
                        compactHeader
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 12)
                    }
                }
                .padding(.bottom, 140)
            }
            .safeAreaBar(edge: .top, spacing: 0) {
                if sharedNavigationHeader != nil && (topControlsNamespace != nil || onDismiss != nil) {
                    // The persistent header remains in its parent overlay during navigation.
                    Color.clear.frame(height: 66).accessibilityHidden(true)
                }
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
            .toolbar(.hidden, for: .navigationBar)
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
                    currencySymbol: store.currencySymbol, insights: analyticsInsights, insightsOnly: true,
                    onSelectInsight: { destination in
                        pendingSpendingInsight = destination
                        showsDirectInsights = false
                    })
            }
            .navigationDestination(isPresented: $showsSpendingBreakdown) {
                SpendingBreakdownSheet(snapshot: spendingSnapshot, items: selectedBreakdownItems,
                    byCategory: groupingMode == .categories, accountLabel: selectedAccountLabel, accountID: selectedAccountId,
                    topControlsNamespace: analyticsControlsNamespace)
            }
            .sheet(isPresented: $showMonthPicker) {
                datePickerSheet
            }
            .navigationDestination(isPresented: $showSubscriptionSheet) {
                SubscriptionsView(isPushed: true, initialSelectedSubscriptionId: selectedSubscriptionIdForDetail)
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
            .navigationDestination(isPresented: $showBudgetHub) { BudgetView() }
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
                chartProgress = 1.0
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
                if showsSpendingBreakdown || showSubscriptionSheet || showBudgetHub {
                    sharedNavigationHeader?.isVisible = false
                } else if !active {
                    configureNavigationHeader()
                }
                withAnimation(AppMotion.fluidSpring) {
                    isSubpageActiveBinding?.wrappedValue = active
                }
            }
            .onChange(of: store.transactions) { _, _ in referenceDate = Date() }
            .onChange(of: selectedDate) { _, _ in
                resetSelections()
                chartProgress = 1.0
            }
            .onChange(of: granularity) { _, _ in
                resetSelections()
                chartProgress = 1.0
            }
            .onChange(of: transactionType) { _, _ in resetSelections() }
            .onChange(of: selectedAccountId) { _, _ in
                resetSelections()
                chartProgress = 1.0
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
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
            .background(AnalyticsTonalColors.inset, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            if store.insightsEnabled && !isIncome && !snapshot.transactions.isEmpty {
                Button { showsDirectInsights = true } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            SpendyInsightBrandMark(style: .kicker, showsPersonalization: false)
                            Text(analyticsInsights.first?.headline ?? "Explore your recorded spending")
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
                .accessibilityLabel("Open Spendy Insights")
                .accessibilityValue(analyticsInsights.first?.headline ?? "Explore your recorded spending")
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

    private var analyticsKPIGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            analyticsKPI(
                title: averageMetricTitle,
                icon: "calendar.day.timeline.left",
                value: averageMetricValue.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                detail: averageComparisonDetail,
                identifier: "analytics-average-kpi"
            )
            analyticsKPI(
                title: "Transactions",
                icon: "arrow.left.arrow.right",
                value: "\(spendingSnapshot.transactions.count)",
                detail: transactionFrequencyDetail,
                identifier: "analytics-transactions-kpi"
            )
            analyticsKPI(
                title: isIncome ? "Largest income" : "Largest spend",
                icon: isIncome ? "arrow.down.left" : "arrow.up.right",
                value: largestTransaction?.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0) ?? "—",
                detail: largestTransaction?.title ?? "No records yet",
                identifier: "analytics-largest-kpi"
            )
            analyticsKPI(
                title: groupingMode == .categories ? "Top category" : "Top account",
                icon: groupingMode == .categories ? "square.grid.2x2" : "building.columns",
                value: leadingBreakdownItem.map { "\($0.percentage.formatted(.number.precision(.fractionLength(0))))%" } ?? "—",
                detail: leadingBreakdownItem?.label ?? "No records yet",
                identifier: "analytics-leading-kpi"
            )
        }
    }

    private func analyticsKPI(
        title: String,
        icon: String,
        value: String,
        detail: String,
        identifier: String
    ) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                        .accessibilityHidden(true)
                }
                Spacer(minLength: 0)
                Text(value)
                    .spendyNumberFont(size: 29, weight: .semibold, tracking: -0.7)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.52)
            }
            .padding(13)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(AnalyticsTonalColors.inset, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            HStack(spacing: 0) {
                Text(detail)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 37, alignment: .leading)
        }
        .padding(5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fit)
        .background(AnalyticsTonalColors.outer, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AnalyticsTonalColors.outline, lineWidth: 0.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(value), \(detail)")
        .accessibilityIdentifier(identifier)
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
                        HStack(spacing: 16) {
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
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                                    .foregroundStyle(SpendyColors.separator)
                                AxisValueLabel {
                                    if let amount = value.as(Double.self) {
                                        Text(formatAxisAmount(amount))
                                            .font(.system(size: 10))
                                            .foregroundStyle(SpendyColors.textTertiary)
                                    }
                                }
                            }
                        }
                        .frame(height: 140)
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

    private var recordedDaysSection: some View {
        let days = streakHeatmapDays
        let weeks = stride(from: 0, to: days.count, by: 6).map { start in
            Array(days[start..<min(start + 6, days.count)])
        }
        let tracked = days.compactMap(\.hasExpense)
        let recordedCount = tracked.filter { $0 }.count
        let bestRun = longestRecordedRun(in: days)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recorded activity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text("Date streak")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                Spacer()
                if !tracked.isEmpty {
                    HStack(spacing: 14) {
                        compactStreakMetric(value: bestRun, label: "best")
                        compactStreakMetric(value: recordedCount, label: "days")
                    }
                }
            }

            if tracked.isEmpty {
                SpendyPlainEmptyState(
                    title: "No activity to track yet",
                    message: "Your recorded spending days will appear here.",
                    compact: true
                )
            } else {
                HStack(alignment: .top, spacing: 7) {
                    VStack(spacing: 4) {
                        let weekdayLabels = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                        ForEach(weekdayLabels.indices, id: \.self) { index in
                            Text(weekdayLabels[index])
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(SpendyColors.textTertiary)
                                .frame(width: 60, height: 12, alignment: .leading)
                        }
                    }
                    HStack(spacing: 3) {
                        ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: 4) {
                                ForEach(week) { day in
                                    streakHeatmapMark(day)
                                        .accessibilityHidden(true)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(streakDateRange(days))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(SpendyColors.textTertiary)

                HStack(spacing: 16) {
                    Label("Recorded expense", systemImage: "square.fill")
                        .accessibilityIdentifier("streak-legend-recorded")
                    Label("No entry", systemImage: "square")
                }
                .font(.caption)
                .foregroundStyle(SpendyColors.textSecondary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Recorded expense date streak, Monday through Saturday")
        .accessibilityValue("Best run \(bestRun) \(bestRun == 1 ? "day" : "days"). \(recordedCount) recorded \(recordedCount == 1 ? "day" : "days") out of \(tracked.count) tracked days.")
        .accessibilityIdentifier("expense-date-streak")
        .modifier(AnalyticsPanelStyle(verticalPadding: 12))
    }

    private func compactStreakMetric(value: Int, label: String) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(SpendyColors.textPrimary)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(SpendyColors.textTertiary)
        }
    }

    private func streakHeatmapMark(_ day: RecordedDay) -> some View {
        let isRecorded = day.hasExpense == true
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(isRecorded ? SpendyColors.textPrimary : (day.hasExpense == nil ? SpendyColors.separator.opacity(0.55) : SpendyColors.cardBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(day.hasExpense == false ? SpendyColors.textTertiary : Color.clear, lineWidth: 0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 12)
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
            SpendyIconBadge(sfSymbol: item.sfSymbol, color: SpendyColors.textPrimary,
                size: .small, style: .circle, monogramName: item.label)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.label).font(.subheadline.weight(.medium))
                    .foregroundStyle(SpendyColors.textPrimary)
                Text("\(item.txCount) \(isIncome ? (item.txCount == 1 ? "income transaction" : "income transactions") : (item.txCount == 1 ? "expense" : "expenses"))")
                    .font(.caption).foregroundStyle(SpendyColors.textSecondary)
            }
            Spacer(minLength: 4)
            Text(item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                .font(.subheadline.weight(.semibold)).monospacedDigit()
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.75)
        }
        .padding(.vertical, 8)
        .frame(minHeight: 48)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.label), \(item.txCount) \(isIncome ? "income transactions" : "expenses"), \(item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 2))")
    }

    private var cashflowChartSection: some View {
        let net = totalIncome - totalSpending
        let retained = max(0, net)
        let keptShare = totalIncome > 0 ? min(1, retained / totalIncome) : 0

        return VStack(alignment: .leading, spacing: 17) {
            HStack {
                Text("Cash flow")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                Spacer()
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
            }

            if totalIncome > 0 || totalSpending > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(net >= 0 ? "+" : "−")\(abs(net).formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                        .spendyNumberFont(size: 34, weight: .bold, tracking: -1)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("Net this \(granularity.rawValue.lowercased())")
                        .font(.system(size: 12))
                        .foregroundStyle(SpendyColors.textSecondary)
                }

                if totalIncome > 0 {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text(net >= 0 ? "Kept from income" : "Spent beyond income")
                            Spacer()
                            Text(net >= 0 ? "\(Int((keptShare * 100).rounded()))%" : abs(net).formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)

                        GeometryReader { geometry in
                            Capsule()
                                .fill(SpendyColors.cardBackgroundSecondary)
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(SpendyColors.textPrimary)
                                        .frame(width: keptShare > 0 ? max(3, geometry.size.width * keptShare) : 0)
                                }
                        }
                        .frame(height: 12)
                    }
                    .accessibilityLabel("\(Int((keptShare * 100).rounded())) percent of income kept")
                    Text("Filled = income remaining after expenses · track = total recorded income")
                        .font(.caption).foregroundStyle(SpendyColors.textSecondary)
                } else {
                    Text("No income recorded in this period")
                        .font(.system(size: 11))
                        .foregroundStyle(SpendyColors.textSecondary)
                }

                Divider().overlay(SpendyColors.separator)

                HStack(spacing: 12) {
                    cashFlowValue(title: "Money in", amount: totalIncome, symbol: "arrow.down.left", prefix: "+")
                    Rectangle()
                        .fill(SpendyColors.separator)
                        .frame(width: 1, height: 45)
                    cashFlowValue(title: "Money out", amount: totalSpending, symbol: "arrow.up.right", prefix: "−")
                }
            } else {
                SpendyPlainEmptyState(
                    title: "No activity yet",
                    message: "Record income or spending to see cash flow.",
                    compact: true
                )
            }
        }
        .modifier(AnalyticsPanelStyle())
    }

    private func cashFlowValue(title: String, amount: Double, symbol: String, prefix: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11))
            }
            .foregroundStyle(SpendyColors.textSecondary)
            Text("\(prefix)\(amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func triggerEntranceAnimation() {
        chartProgress = 1.0
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



    // MARK: - Card 1: Cashflow Overview Card (Clean Gray & Green)
    private var cashflowOverviewCard: some View {
        let net = totalIncome - totalSpending
        let isPositive = net >= 0
        let intervals = intervalData
        let selectedInterval = intervals.first(where: { $0.label == selectedCashflowLabel })
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Cashflow")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text(net.formattedSignedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 34, weight: .heavy, tracking: -1.0)
                        .foregroundStyle(isPositive ? SpendyColors.incomeGreen : SpendyColors.textPrimary)
                }
                
                Spacer()
                
                if let sel = selectedInterval {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(sel.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        let selNet = sel.incomeAmount - sel.spendingAmount
                        Text(selNet.formattedSignedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .spendyNumberFont(size: 15, weight: .heavy, tracking: -0.4)
                            .foregroundStyle(selNet >= 0 ? SpendyColors.incomeGreen : SpendyColors.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(SpendyColors.cardBackground)
                            .overlay(Capsule().stroke(SpendyColors.separator, lineWidth: 0.8))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Soft top corners with a flat baseline for spending and income.
            Chart(intervals) { item in
                let isSelected = selectedCashflowLabel == item.label
                
                BarMark(
                    x: .value("Period", item.label),
                    y: .value("Spending", item.spendingAmount * chartProgress)
                )
                .foregroundStyle(SpendyColors.textPrimary.opacity(isSelected ? 0.65 : 0.35))
                .position(by: .value("Type", "Spending"))
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5))

                BarMark(
                    x: .value("Period", item.label),
                    y: .value("Income", item.incomeAmount * chartProgress)
                )
                .foregroundStyle(SpendyColors.incomeGreen.opacity(isSelected ? 1 : 0.9))
                .position(by: .value("Type", "Income"))
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5))

                if let selectedLabel = selectedCashflowLabel, selectedLabel == item.label {
                    RuleMark(x: .value("Selected", item.label))
                        .foregroundStyle(SpendyColors.separator.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .center) {
                            VStack(spacing: 2) {
                                Text("Spend: \(item.spendingAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                Text("Income: +\(item.incomeAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(SpendyColors.incomeGreen)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(SpendyColors.cardBackground)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8))
                            }
                        }
                }
            }
            .chartXSelection(value: $selectedCashflowLabel)
            .spendyHoldPreview(selection: $selectedCashflowLabel)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.8, dash: [4, 4]))
                        .foregroundStyle(SpendyColors.separator.opacity(0.6))
                    AxisValueLabel {
                        if let doubleVal = value.as(Double.self) {
                            Text(formatAxisAmount(doubleVal))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                    }
                }
            }
            .chartLegend(.hidden)
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 150)
            .padding(.vertical, 4)
            .onChange(of: selectedCashflowLabel) { _, _ in
                HapticsManager.shared.trigger(.selection)
            }
            
            Divider().background(SpendyColors.separator)
            
            // Legend Rows (Right-aligned numbers)
            VStack(spacing: 8) {
                HStack {
                    Circle().fill(Color(hex: "#8E8E93")).frame(width: 7, height: 7)
                    Text("Spending")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Spacer()
                    Text(totalSpending.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 14, weight: .heavy, tracking: -0.4)
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                HStack {
                    Circle().fill(SpendyColors.isMonoMode ? SpendyColors.textPrimary : Color(hex: "#30D158")).frame(width: 7, height: 7)
                    Text("Income")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Spacer()
                    Text("+" + totalIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 14, weight: .heavy, tracking: -0.4)
                        .foregroundStyle(SpendyColors.incomeGreen)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8))
        }
    }
     // MARK: - Card 2: Spending Breakdown Card (No Donut, Neutral Gray)
    private var spendingBreakdownCard: some View {
        let items = spendingBreakdownItems
        let intervals = intervalData
        let avgSpend = dailyAverageSpend
        let selectedInterval = intervals.first(where: { $0.label == selectedSpendingLabel })
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Spending")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text(totalSpending.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 34, weight: .heavy, tracking: -1.0)
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                Spacer()
                
                if let sel = selectedInterval {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(sel.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Text(sel.spendingAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .spendyNumberFont(size: 15, weight: .heavy, tracking: -0.4)
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(SpendyColors.cardBackground)
                            .overlay(Capsule().stroke(SpendyColors.separator, lineWidth: 0.8))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Native Swift Chart: Spending Line & Area Chart (Neutral Slate Gray)
            Chart {
                ForEach(intervals) { item in
                    LineMark(
                        x: .value("Period", item.label),
                        y: .value("Spending", item.spendingAmount * chartProgress)
                    )
                    .foregroundStyle(Color(hex: "#8E8E93"))
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .symbol {
                        Circle()
                            .fill(selectedSpendingLabel == item.label ? SpendyColors.textPrimary : SpendyColors.cardBackground)
                            .stroke(Color(hex: "#8E8E93"), lineWidth: 2)
                            .frame(width: selectedSpendingLabel == item.label ? 9 : 5, height: selectedSpendingLabel == item.label ? 9 : 5)
                    }
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Period", item.label),
                        y: .value("Spending", item.spendingAmount * chartProgress)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // Average Spending RuleMark
                if avgSpend > 0 {
                    RuleMark(y: .value("Average", avgSpend * chartProgress))
                        .foregroundStyle(SpendyColors.textTertiary.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("AVG \(formatAxisAmount(avgSpend))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(SpendyColors.textTertiary)
                                .padding(.horizontal, 4)
                        }
                }
                
                if let selectedLabel = selectedSpendingLabel, let sel = selectedInterval {
                    RuleMark(x: .value("Selected", selectedLabel))
                        .foregroundStyle(SpendyColors.textPrimary.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .annotation(position: .top, alignment: .center) {
                            Text(sel.spendingAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(SpendyColors.cardBackground)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8))
                                }
                        }
                }
            }
            .chartXSelection(value: $selectedSpendingLabel)
            .spendyHoldPreview(selection: $selectedSpendingLabel)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.8, dash: [4, 4]))
                        .foregroundStyle(SpendyColors.separator.opacity(0.6))
                    AxisValueLabel {
                        if let doubleVal = value.as(Double.self) {
                            Text(formatAxisAmount(doubleVal))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 130)
            .padding(.vertical, 4)
            .onChange(of: selectedSpendingLabel) { _, _ in
                HapticsManager.shared.trigger(.selection)
            }
            
            Divider().background(SpendyColors.separator)
            
            // Sub-header: Spending by Category / Account
            HStack {
                Text(groupingMode == .categories ? "Spending by Category" : "Spending by Account")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                if items.count > 4 {
                    Image(systemName: isSpendingListExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if items.count > 4 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isSpendingListExpanded.toggle()
                        HapticsManager.shared.trigger(.selection)
                    }
                }
            }
            .padding(.top, 4)
            
            // List of Category / Account Breakdown Rows
            if items.isEmpty {
                Text("No spending recorded in this period.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .padding(.vertical, 8)
            } else {
                let displayedItems = isSpendingListExpanded ? items : Array(items.prefix(4))
                VStack(spacing: 12) {
                    ForEach(displayedItems) { item in
                        HStack(spacing: 12) {
                            SpendyIconBadge(
                                sfSymbol: item.sfSymbol,
                                color: Color(hex: item.colorHex),
                                size: .medium,
                                style: .circle,
                                monogramName: item.label
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.label)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Text("\(item.txCount) \(item.txCount == 1 ? "expense" : "expenses")")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            
                            Spacer()
                            
                            Text(item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                .spendyNumberFont(size: 15, weight: .heavy, tracking: -0.4)
                                .foregroundStyle(SpendyColors.textPrimary)
                        }
                        .padding(.vertical, AppSpacing.xxs)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticsManager.shared.trigger(.selection)
                            if groupingMode == .categories {
                                let cat = store.categories.first(where: { $0.id == item.id }) ?? store.category(for: item.id)
                                selectedCategoryForSheet = cat
                            } else {
                                if let acc = store.accounts.first(where: { $0.id == item.id }) {
                                    selectedAccountForSheet = acc
                                }
                            }
                        }
                    }
                }
            }
        }

        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8))
        }
    }
    
    // MARK: - Card 3: Income Breakdown Card (No Donut, Green Accent)
    private var incomeBreakdownCard: some View {
        let items = incomeBreakdownItems
        let intervals = intervalData
        let avgIncome = totalIncome / Double(max(1, intervals.count))
        let selectedInterval = intervals.first(where: { $0.label == selectedIncomeLabel })
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Income")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text("+" + totalIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 34, weight: .heavy, tracking: -1.0)
                        .foregroundStyle(SpendyColors.incomeGreen)
                }
                
                Spacer()
                
                if let sel = selectedInterval {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(sel.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Text("+" + sel.incomeAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .spendyNumberFont(size: 15, weight: .heavy, tracking: -0.4)
                            .foregroundStyle(SpendyColors.incomeGreen)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(SpendyColors.cardBackground)
                            .overlay(Capsule().stroke(SpendyColors.separator, lineWidth: 0.8))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Native Swift Chart: Income Line Chart
            let incomeLineColor = SpendyColors.isMonoMode ? SpendyColors.textPrimary : Color(hex: "#30D158")
            Chart {
                ForEach(intervals) { item in
                    LineMark(
                        x: .value("Period", item.label),
                        y: .value("Income", item.incomeAmount * chartProgress)
                    )
                    .foregroundStyle(incomeLineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .symbol {
                        Circle()
                            .fill(selectedIncomeLabel == item.label ? incomeLineColor : SpendyColors.cardBackground)
                            .stroke(incomeLineColor, lineWidth: 2)
                            .frame(width: selectedIncomeLabel == item.label ? 9 : 5, height: selectedIncomeLabel == item.label ? 9 : 5)
                    }
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Period", item.label),
                        y: .value("Income", item.incomeAmount * chartProgress)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [incomeLineColor.opacity(0.25), incomeLineColor.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                if avgIncome > 0 {
                    RuleMark(y: .value("Average", avgIncome * chartProgress))
                        .foregroundStyle(incomeLineColor.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("AVG \(formatAxisAmount(avgIncome))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(incomeLineColor)
                                .padding(.horizontal, 4)
                        }
                }
                
                if let selectedLabel = selectedIncomeLabel, let sel = selectedInterval {
                    RuleMark(x: .value("Selected", selectedLabel))
                        .foregroundStyle(incomeLineColor.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .annotation(position: .top, alignment: .center) {
                            Text("+" + sel.incomeAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(incomeLineColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(SpendyColors.cardBackground)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8))
                                }
                        }
                }
            }
            .chartXSelection(value: $selectedIncomeLabel)
            .spendyHoldPreview(selection: $selectedIncomeLabel)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.8, dash: [4, 4]))
                        .foregroundStyle(SpendyColors.separator.opacity(0.6))
                    AxisValueLabel {
                        if let doubleVal = value.as(Double.self) {
                            Text(formatAxisAmount(doubleVal))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 130)
            .padding(.vertical, 4)
            .onChange(of: selectedIncomeLabel) { _, _ in
                HapticsManager.shared.trigger(.selection)
            }
            
            Divider().background(SpendyColors.separator)
            
            // Sub-header: Income by Category / Account
            HStack {
                Text(groupingMode == .categories ? "Income by Category" : "Income by Account")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                if items.count > 4 {
                    Image(systemName: isIncomeListExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if items.count > 4 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isIncomeListExpanded.toggle()
                        HapticsManager.shared.trigger(.selection)
                    }
                }
            }
            .padding(.top, 4)
            
            // List of Income Rows
            if items.isEmpty {
                Text("No income recorded in this period.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .padding(.vertical, 8)
            } else {
                let displayedItems = isIncomeListExpanded ? items : Array(items.prefix(4))
                VStack(spacing: 12) {
                    ForEach(displayedItems) { item in
                        HStack(spacing: 12) {
                            SpendyIconBadge(
                                sfSymbol: item.sfSymbol,
                                color: Color(hex: item.colorHex),
                                size: .medium,
                                style: .circle,
                                monogramName: item.label
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.label)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Text("\(item.txCount) \(item.txCount == 1 ? "transaction" : "transactions")")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            
                            Spacer()
                            
                            Text("+" + item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                .spendyNumberFont(size: 15, weight: .heavy, tracking: -0.4)
                                .foregroundStyle(SpendyColors.incomeGreen)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticsManager.shared.trigger(.selection)
                            if groupingMode == .categories {
                                let cat = store.categories.first(where: { $0.id == item.id }) ?? store.category(for: item.id)
                                selectedCategoryForSheet = cat
                            } else {
                                if let acc = store.accounts.first(where: { $0.id == item.id }) {
                                    selectedAccountForSheet = acc
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8))
        }
    }
    
    // MARK: - Card 4: Minimalist Budget Health Card (Ultra-Clean, Apple HIG)
    @ViewBuilder
    private var budgetRingPacingCard: some View {
        let spent = store.budgetCycleExpenses
        let budgetLimit = store.budgetTargetAmount(for: store.budget.period)
        let isConfigured = store.budget.isActive && budgetLimit > 0
        let remaining = max(0, budgetLimit - spent)
        let ratio = isConfigured ? (budgetLimit > 0 ? spent / budgetLimit : 0.0) : 0.0
        let isExceeded = spent > budgetLimit && isConfigured
        let usedPct = isConfigured ? (spent / budgetLimit) * 100.0 : 0.0
        let daysLeft = store.budgetDaysLeft
        let safeDaily = isExceeded ? 0.0 : (daysLeft > 0 ? remaining / Double(daysLeft) : 0.0)
        
        if !isConfigured {
            // Empty State Banner with Direct Onboarding Action
            HStack(spacing: 16) {
                SpendyIconBadge(
                    sfSymbol: SFIcons.tabBudget,
                    color: SpendyColors.primaryBlue,
                    size: .medium,
                    style: .circle
                )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("No active budget")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text("Set a monthly limit to track health.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    showEditBudgetSheet = true
                }) {
                    Text("Set Budget")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.elevatedControlForeground)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(SpendyColors.elevatedControlFill, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8))
            }
        } else {
            VStack(alignment: .leading, spacing: 14) {
                // 1. Top Header: Title + Big Clean Number + Top-Right Status Pill
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Budget Status")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Text(spent.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .spendyNumberFont(size: 34, weight: .heavy, tracking: -1.0)
                            .foregroundStyle(isExceeded ? SpendyColors.warningOrange : SpendyColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        
                        Text("of \(budgetLimit.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) monthly limit")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    // Top-right pill badge
                    HStack(spacing: 5) {
                        Circle()
                            .fill(isExceeded ? SpendyColors.warningOrange : (ratio > 0.85 ? SpendyColors.warningOrange : SpendyColors.incomeGreen))
                            .frame(width: 6, height: 6)
                        
                        Text(isExceeded ? "Exceeded" : String(format: "%.0f%% used", usedPct))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isExceeded ? SpendyColors.warningOrange : SpendyColors.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
                    .overlay(
                        Capsule().stroke(SpendyColors.separator, lineWidth: 0.8)
                    )
                }
                
                // 2. Minimalist Horizontal Progress Capsule
                Capsule()
                    .fill(SpendyColors.cardBackgroundSecondary)
                    .frame(height: 8)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            let fillWidth = max(0, min(geo.size.width, geo.size.width * CGFloat(min(1.0, ratio))))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: isExceeded
                                            ? [Color(hex: "#FF3B30"), Color(hex: "#FF9500")]
                                            : [SpendyColors.primaryBlue, Color(hex: "#00E5FF")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, fillWidth), height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.top, 2)
                
                Divider().background(SpendyColors.separator)
                
                // 3. Clean 2-Stat Row: Remaining vs Daily Allowance
                HStack(alignment: .center) {
                    // Left: Remaining
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remaining")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Text(remaining.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .spendyNumberFont(size: 18, weight: .heavy, tracking: -0.4)
                            .foregroundStyle(isExceeded ? SpendyColors.warningOrange : SpendyColors.textPrimary)
                        
                        Text("\(daysLeft) days left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    // Right: Daily Allowance
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Daily Allowance")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Text(safeDaily.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .spendyNumberFont(size: 18, weight: .heavy, tracking: -0.4)
                            .foregroundStyle(isExceeded ? SpendyColors.warningOrange : SpendyColors.incomeGreen)
                        
                        Text(isExceeded ? "Over budget" : "Safe to spend / day")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isExceeded ? SpendyColors.warningOrange : SpendyColors.incomeGreen)
                    }
                }
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                HapticsManager.shared.trigger(.selection)
                showEditBudgetSheet = true
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

    /// Sixteen Monday–Saturday weeks, based on transaction dates rather than inferred no-spend days.
    private var streakHeatmapDays: [RecordedDay] {
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = 2
        let periodEnd = currentPeriodBounds.end
        let anchor = min(referenceDate, periodEnd)
        let weekStart = mondayCalendar.dateInterval(of: .weekOfYear, for: anchor)?.start
            ?? mondayCalendar.startOfDay(for: anchor)
        let start = mondayCalendar.date(byAdding: .weekOfYear, value: -15, to: weekStart) ?? weekStart
        let end = mondayCalendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
        let expenses = store.filteredTransactions(for: selectedAccountId).filter {
            $0.type == .expense && $0.date <= referenceDate
        }
        let firstTrackedDay = expenses.map(\.date).min().map { mondayCalendar.startOfDay(for: $0) }
        let today = mondayCalendar.startOfDay(for: referenceDate)
        let recordedDates = Set(expenses.filter { $0.date >= start && $0.date < end }.map {
            mondayCalendar.startOfDay(for: $0.date)
        })

        return (0..<16).flatMap { weekOffset -> [RecordedDay] in
            guard let monday = mondayCalendar.date(byAdding: .weekOfYear, value: weekOffset, to: start) else { return [] }
            return (0..<6).compactMap { dayOffset in
                guard let date = mondayCalendar.date(byAdding: .day, value: dayOffset, to: monday) else { return nil }
                let hasExpense: Bool?
                if recordedDates.contains(date) {
                    hasExpense = true
                } else if firstTrackedDay.map({ date >= $0 }) == true && date < today {
                    hasExpense = false
                } else {
                    hasExpense = nil
                }
                return RecordedDay(date: date, hasExpense: hasExpense)
            }
        }
    }

    private func streakDateRange(_ days: [RecordedDay]) -> String {
        guard let first = days.first?.date, let last = days.last?.date else { return "" }
        return "\(first.formatted(.dateTime.month(.abbreviated).day())) – \(last.formatted(.dateTime.month(.abbreviated).day().year()))"
    }

    private func longestRecordedRun(in days: [RecordedDay]) -> Int {
        var current = 0
        var longest = 0
        for day in days {
            current = day.hasExpense == true ? current + 1 : 0
            longest = max(longest, current)
        }
        return longest
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

    private var averageMetricTitle: String {
        switch granularity {
        case .day: isIncome ? "Income / hour" : "Spend / hour"
        case .week, .month: isIncome ? "Daily income" : "Daily average"
        case .year: isIncome ? "Monthly income" : "Monthly average"
        }
    }

    private var averageMetricDivisor: Int {
        let snapshot = spendingSnapshot
        guard !snapshot.isFuture else { return 1 }
        switch granularity {
        case .day:
            let end = min(referenceDate, snapshot.end)
            return max(1, calendar.dateComponents([.hour], from: snapshot.start, to: end).hour ?? 1)
        case .week, .month:
            let end = min(referenceDate, snapshot.end.addingTimeInterval(-1))
            return max(1, (calendar.dateComponents([.day], from: snapshot.start, to: end).day ?? 0) + 1)
        case .year:
            let end = min(referenceDate, snapshot.end.addingTimeInterval(-1))
            return max(1, (calendar.dateComponents([.month], from: snapshot.start, to: end).month ?? 0) + 1)
        }
    }

    private var averageMetricValue: Double {
        spendingSnapshot.total / Double(averageMetricDivisor)
    }

    private var averageComparisonDetail: String {
        guard spendingSnapshot.hasBaselineRecords else { return "Needs a previous period" }
        let previousAverage = previousPeriodSnapshot.total / Double(averageMetricDivisor)
        guard previousAverage > 0 else { return averageMetricValue > 0 ? "New activity this period" : "Same as previous" }
        let percentage = abs((averageMetricValue - previousAverage) / previousAverage) * 100
        if percentage < 0.5 { return "About the same as previous" }
        return "\(percentage.formatted(.number.precision(.fractionLength(0))))% \(averageMetricValue > previousAverage ? "above" : "below") previous"
    }

    private var activeDayCount: Int {
        Set(spendingSnapshot.transactions.map { calendar.startOfDay(for: $0.date) }).count
    }

    private var transactionFrequencyDetail: String {
        activeDayCount == 1 ? "on 1 active day" : "across \(activeDayCount) active days"
    }

    private var largestTransaction: Transaction? {
        spendingSnapshot.transactions.max { lhs, rhs in
            lhs.amount == rhs.amount ? lhs.date < rhs.date : lhs.amount < rhs.amount
        }
    }

    private var leadingBreakdownItem: AnalyticsBreakdownItem? {
        selectedBreakdownItems.first
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
    
    private var savingsRatePercentage: Double {
        guard totalIncome > 0 else { return 0.0 }
        let net = totalIncome - totalSpending
        let rate = (net / totalIncome) * 100.0
        return max(-100.0, min(100.0, rate))
    }
    
    /// Granular intervals for multi-bar & line charts with robust date boundaries
    private var intervalData: [PeriodIntervalData] {
        var intervals: [PeriodIntervalData] = []
        let txs = filteredTransactions
        
        switch granularity {
        case .day:
            let labels = ["12-6am", "6-12pm", "12-6pm", "6-12am"]
            let start = selectedDate.startOfDay
            for i in 0..<4 {
                let blockStart = calendar.date(byAdding: .hour, value: i * 6, to: start) ?? start
                let blockEnd = calendar.date(byAdding: .hour, value: 6, to: blockStart) ?? start
                let blockTxs = txs.filter { $0.date >= blockStart && $0.date < blockEnd }
                let spend = blockTxs.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
                let inc = blockTxs.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
                intervals.append(PeriodIntervalData(label: labels[i], startDate: blockStart, endDate: blockEnd, spendingAmount: spend, incomeAmount: inc))
            }
            
        case .week:
            let start = currentPeriodBounds.start
            for d in 0..<7 {
                let dayStart = calendar.date(byAdding: .day, value: d, to: start) ?? start
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? start
                let dayTxs = txs.filter { $0.date >= dayStart && $0.date < dayEnd }
                let spend = dayTxs.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
                let inc = dayTxs.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
                intervals.append(PeriodIntervalData(label: SpendyDateFormatterCache.shortWeekday.string(from: dayStart), startDate: dayStart, endDate: dayEnd, spendingAmount: spend, incomeAmount: inc))
            }
            
        case .month:
            let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
            let ranges: [(Int, Int, String)]
            if daysInMonth <= 28 {
                ranges = [
                    (1, 7, "1-7"),
                    (8, 14, "8-14"),
                    (15, 21, "15-21"),
                    (22, daysInMonth, "22-\(daysInMonth)")
                ]
            } else {
                ranges = [
                    (1, 7, "1-7"),
                    (8, 14, "8-14"),
                    (15, 21, "15-21"),
                    (22, 28, "22-28"),
                    (29, daysInMonth, "29-\(daysInMonth)")
                ]
            }
            let start = selectedDate.startOfMonth
            for (startDay, endDay, label) in ranges {
                let rStart = calendar.date(byAdding: .day, value: startDay - 1, to: start) ?? start
                let rEnd = calendar.date(byAdding: .day, value: endDay, to: start) ?? start
                let rangeTxs = txs.filter { $0.date >= rStart && $0.date < rEnd }
                let spend = rangeTxs.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
                let inc = rangeTxs.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
                intervals.append(PeriodIntervalData(label: label, startDate: rStart, endDate: rEnd, spendingAmount: spend, incomeAmount: inc))
            }
            
        case .year:
            let start = selectedDate.startOfYear
            for m in 0..<12 {
                let mStart = calendar.date(byAdding: .month, value: m, to: start) ?? start
                let mEnd = calendar.date(byAdding: .month, value: 1, to: mStart) ?? start
                let mTxs = txs.filter { $0.date >= mStart && $0.date < mEnd }
                let spend = mTxs.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
                let inc = mTxs.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
                intervals.append(PeriodIntervalData(label: SpendyDateFormatterCache.shortMonth.string(from: mStart), startDate: mStart, endDate: mEnd, spendingAmount: spend, incomeAmount: inc))
            }
        }
        
        return intervals
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
    
    private var remainingDaysText: String {
        let now = Date()
        if calendar.isDate(selectedDate, equalTo: now, toGranularity: .month) {
            let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
            let currentDay = calendar.component(.day, from: now)
            let left = max(0, daysInMonth - currentDay)
            return "\(left) days left"
        } else if selectedDate < now.startOfMonth {
            return "Period Completed"
        } else {
            let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
            return "\(daysInMonth) days remaining"
        }
    }
    
    private var dailyAverageSpend: Double {
        let days = max(1, intervalData.count)
        return totalSpending / Double(days)
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
    
    private func formattedMonthRange(_ date: Date) -> String {
        let start = date.startOfMonth
        let end = date.endOfMonth
        return "\(SpendyDateFormatterCache.monthDay.string(from: start)) – \(SpendyDateFormatterCache.monthDay.string(from: end))"
    }
    
    private func formatAxisAmount(_ amount: Double) -> String {
        if amount == 0 { return "0" }
        let sym = store.currencySymbol
        if amount >= 100_000 {
            return String(format: "%@%.0fk", sym, amount / 1000)
        } else if amount >= 1_000 {
            let valStr = String(format: "%.1fk", amount / 1000).replacingOccurrences(of: ".0k", with: "k")
            return "\(sym)\(valStr)"
        } else {
            return String(format: "%@%.0f", sym, amount)
        }
    }
    
    

    
    private func resetSelections() {
        selectedSpendingBucketID = nil
        referenceDate = Date()
        selectedCashflowLabel = nil
        selectedSpendingLabel = nil
        selectedIncomeLabel = nil
        selectedCategorySectorId = nil
        selectedIncomeSectorId = nil
    }
}

#Preview {
    AnalyticsView()
        .environment(ExpenseStore())
        .preferredColorScheme(.dark)
}
