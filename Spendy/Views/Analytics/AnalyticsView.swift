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

private struct SpendingDay: Identifiable {
    let date: Date
    let amount: Double?
    var id: Date { date }
}

private struct AnalyticsPanelStyle: ViewModifier {
    var verticalPadding: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
    }
}

struct AnalyticsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var selectedTab: Binding<AppTab>? = nil
    var topControlsNamespace: Namespace.ID? = nil
    var onDismiss: (() -> Void)? = nil
    var isSubpageActiveBinding: Binding<Bool>? = nil
    
    var initialAccountID: String = "all"
    var initialDate: Date? = nil
    @State private var appliedInitialScope = false
    @State private var selectedSpendingBucketID: String?
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
    @State private var selectedNoSpendDate: Date? = nil
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
        showsSpendingBreakdown || showSubscriptionSheet ||
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
                    headerBar
                        .padding(.horizontal, 20)
                        .padding(.top, topControlsNamespace != nil ? 4 : 10)

                    Section {
                        VStack(spacing: 16) {
                            spendingRhythmCard.modifier(AnalyticsPanelStyle(verticalPadding: 12))
                            spendingMixSection.modifier(AnalyticsPanelStyle(verticalPadding: 12))
                            if !isIncome { noSpendDaysSection }
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
                SubscriptionsView(initialSelectedSubscriptionId: selectedSubscriptionIdForDetail)
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
            .sheet(isPresented: $showEditBudgetSheet) {
                EditBudgetSheet(isEditing: store.budget.isActive)
            }
            .navigationDestination(item: $selectedAccountForSheet) { account in
                AccountAnalyticsSheet(
                    account: account,
                    spendingScope: SpendingScope(start: spendingSnapshot.start, end: spendingSnapshot.end, referenceDate: referenceDate, transactionType: transactionType),
                    topControlsNamespace: analyticsControlsNamespace
                )
            }
            .navigationDestination(item: $selectedCategoryForSheet) { category in
                CategoryAnalyticsSheet(
                    category: category,
                    spendingScope: SpendingScope(start: spendingSnapshot.start, end: spendingSnapshot.end,
                        referenceDate: referenceDate, accountIDs: selectedAccountId == "all" ? nil : [selectedAccountId], transactionType: transactionType),
                    topControlsNamespace: analyticsControlsNamespace
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
            }
            .onChange(of: quickActions.requestedAnalyticsWeekDate) { _, _ in openRequestedWeek() }
            .onChange(of: isSubpageActive) { _, active in
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
                Text(isIncome ? "No income recorded for this period." : "No spending recorded for this period.")
                    .font(.subheadline)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .padding(.vertical, 12)
            }
            if store.insightsEnabled && !isIncome {
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

    private var noSpendDaysSection: some View {
        let days = monthSpendingDays
        let cells = calendarCells(for: days)
        let tracked = days.compactMap(\.amount)
        let noSpendCount = tracked.filter { $0 == 0 }.count
        let bestRun = longestNoSpendRun(in: days)
        let selectedDay = days.first { day in
            selectedNoSpendDate.map { calendar.isDate(day.date, inSameDayAs: $0) } ?? false
        }

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No-spend streak")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                Spacer()
            }

            if tracked.isEmpty {
                Text("No completed days to track yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(SpendyColors.textSecondary)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 20) {
                    streakMetric(title: "Best run", value: "\(bestRun)", unit: bestRun == 1 ? "day" : "days")
                    streakMetric(title: "No-spend days", value: "\(noSpendCount)", unit: "of \(tracked.count)")
                    Spacer()
                }
            }

                HStack(spacing: 0) {
                    ForEach(["M", "T", "W", "T", "F", "S", "S"].indices, id: \.self) { index in
                        Text(["M", "T", "W", "T", "F", "S", "S"][index])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                    ForEach(cells.indices, id: \.self) { index in
                        if let day = cells[index] {
                            Button {
                                selectedNoSpendDate = day.date
                                HapticsManager.shared.trigger(.selection)
                            } label: {
                                calendarDayMark(day, isSelected: selectedDay?.id == day.id)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(day.date.formatted(date: .abbreviated, time: .omitted)), \(day.amount.map { $0 == 0 ? "no recorded spending" : "spent \($0.formattedCurrency(symbol: store.currencySymbol, decimals: 0))" } ?? (day.date >= calendar.startOfDay(for: Date()) ? "not completed" : "before tracking"))")
                        } else {
                            Color.clear.frame(height: 44)
                        }
                    }
                }

                if let selectedDay {
                    HStack {
                        Text(selectedDay.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        Spacer()
                        Text(selectedDay.amount.map { $0 == 0 ? "No recorded spending" : $0.formattedCurrency(symbol: store.currencySymbol, decimals: 0) } ?? (selectedDay.date >= calendar.startOfDay(for: Date()) ? "Not completed" : "Before tracking"))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                } else {
                    Text("Tap a date to inspect recorded spending.")
                        .font(.caption).foregroundStyle(SpendyColors.textSecondary)
                }
            VStack(alignment: .leading, spacing: 8) {
                Label("Filled date · no recorded spending", systemImage: "square.fill")
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Filled date · no recorded spending")
                    .accessibilityIdentifier("streak-legend-no-spending")
                Label("Outlined date · spending recorded", systemImage: "square")
                Label("Plain date · incomplete or before tracking", systemImage: "calendar")
            }
            .font(.caption).foregroundStyle(SpendyColors.textSecondary)
            Text("Completed days since your first expense. Missing entries do not prove a no-spend day.")
                .font(.caption).foregroundStyle(SpendyColors.textTertiary)
        }
        .accessibilityIdentifier("no-spend-calendar")
        .modifier(AnalyticsPanelStyle())
    }

    private func streakMetric(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(SpendyColors.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .spendyNumberFont(size: 27, weight: .bold, tracking: -0.5)
                    .foregroundStyle(SpendyColors.textPrimary)
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
        }
    }

    private func calendarDayMark(_ day: SpendingDay, isSelected: Bool) -> some View {
        let isNoSpend = day.amount == 0
        return Text(day.date.formatted(.dateTime.day()))
            .font(.caption.weight(day.amount == nil ? .regular : .semibold)).monospacedDigit()
            .foregroundStyle(isNoSpend ? SpendyColors.appBackground : (day.amount == nil ? SpendyColors.textTertiary : SpendyColors.textPrimary))
            .frame(maxWidth: .infinity).frame(height: 44)
            .background {
                RoundedRectangle(cornerRadius: 9)
                    .fill(isNoSpend ? SpendyColors.textPrimary : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(day.amount != nil && !isNoSpend ? SpendyColors.textSecondary : Color.clear, lineWidth: 1)
                    }
                    .padding(4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 11)
                    .stroke(isSelected ? SpendyColors.textPrimary : Color.clear, lineWidth: 2)
                    .padding(1)
            }
            .contentShape(Rectangle())
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
                Text(isIncome ? "Your income breakdown will appear here." : "Your spending breakdown will appear here.")
                    .font(.system(size: 13))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .padding(.vertical, 8)
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
                Text("Record income or spending to see cash flow.")
                    .font(.system(size: 13))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .padding(.vertical, 8)
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

    /// A month calendar; days before the first expense and today/future days remain untracked.
    private var monthSpendingDays: [SpendingDay] {
        let start = selectedDate.startOfMonth
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        let expenses = store.filteredTransactions(for: selectedAccountId).filter { $0.type == .expense }
        let firstTrackedDay = expenses.map(\.date).min().map { calendar.startOfDay(for: $0) }
        let today = calendar.startOfDay(for: Date())
        let amounts = Dictionary(grouping: expenses.filter { $0.date >= start && $0.date < end }) {
            calendar.startOfDay(for: $0.date)
        }.mapValues { transactions in
            transactions.reduce(0.0) { $0 + $1.amount }
        }

        return (0..<count).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let isTracked = firstTrackedDay.map { date >= $0 && date < today } ?? false
            return SpendingDay(date: date, amount: isTracked ? (amounts[date] ?? 0) : nil)
        }
    }

    private func calendarCells(for days: [SpendingDay]) -> [SpendingDay?] {
        guard let first = days.first else { return [] }
        let leading = (calendar.component(.weekday, from: first.date) + 5) % 7
        let filled: [SpendingDay?] = Array(repeating: nil, count: leading) + days.map(Optional.some)
        let trailing = (7 - filled.count % 7) % 7
        return filled + Array(repeating: nil, count: trailing)
    }

    private func longestNoSpendRun(in days: [SpendingDay]) -> Int {
        var current = 0
        var longest = 0
        for day in days {
            current = day.amount == 0 ? current + 1 : 0
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
        selectedNoSpendDate = nil
    }
}

#Preview {
    AnalyticsView()
        .environment(ExpenseStore())
        .preferredColorScheme(.dark)
}
