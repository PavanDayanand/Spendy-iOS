//
//  SharedEntityAnalyticsSheet.swift
//  Spendy
//
//  Unified analytics sheet for categories and accounts.
//  Uncarded hero amount + entity icon, home-style discrete bar chart,
//  period scrubber, date range, then Overview / Recent Activity.
//

import SwiftUI

// MARK: - Analytics Entity Enum
enum AnalyticsEntity {
    case category(Category)
    case account(Account)
    
    var id: String {
        switch self {
        case .category(let cat): return cat.id
        case .account(let acc): return acc.id
        }
    }
    
    var label: String {
        switch self {
        case .category(let cat): return cat.label
        case .account(let acc): return acc.label
        }
    }
    
    var subtitle: String {
        switch self {
        case .category(let cat):
            return cat.type == .income ? "Income Category" : "Expense Category"
        case .account(let acc):
            return acc.type.rawValue.capitalized + " Account"
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .category(let cat): return cat.sfSymbol
        case .account(let acc): return acc.sfSymbol
        }
    }
    
    var monogramName: String {
        switch self {
        case .category(let cat): return cat.label
        case .account(let acc): return acc.label
        }
    }
    
    var color: Color {
        switch self {
        case .category(let cat): return cat.color
        case .account(let acc): return acc.color
        }
    }
    
    var defaultType: TransactionType {
        switch self {
        case .category(let cat): return cat.type
        case .account: return .expense
        }
    }
    
    var isAccount: Bool {
        if case .account = self { return true }
        return false
    }
}

// MARK: - Section Tab Enum
enum AnalyticsSheetSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case activity = "Recent Activity"
    
    var id: String { rawValue }
}

// MARK: - Shared Entity Analytics Sheet
struct SharedEntityAnalyticsSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let entity: AnalyticsEntity
    var isSettingsPage: Bool = false
    var initialType: TransactionType = .expense
    var spendingScope: SpendingScope? = nil
    @State private var appliedSpendingScope = false
    var topControlsNamespace: Namespace.ID? = nil
    var backButtonMorphID: String = "topControl_left"
    var editButtonMorphID: String = "topControl_right"
    var periodControlMorphID: String = "periodNavCapsule"
    var calendarControlMorphID: String = "calendarMenu"
    var onDismiss: (() -> Void)? = nil
    
    // Period & Filter State
    @State private var selectedPeriod: ChartPeriod = .month
    @State private var customDateRange: (start: Date, end: Date)? = nil
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    
    // Interactive Chart Scrubbing State
    @State private var scrubbedBarPoint: MinimalBarPoint? = nil
    @State private var isScrubbingChart: Bool = false
    
    // Lower Section Navigation
    @State private var selectedSection: AnalyticsSheetSection = .overview
    
    // Sheet Modals State
    @State private var pendingTransactionEdit: Transaction? = nil
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var editingCategoryToEdit: Category? = nil
    @State private var editingAccountToEdit: Account? = nil
    @State private var showDatePicker: Bool = false
    @State private var showAddTransaction: Bool = false
    
    @Namespace private var internalSheetNamespace
    
    // MARK: - Colors & Theming (Apple HIG Luxury Graphite in Dark Mode, Crisp in Light Mode)
    private var themeColor: Color {
        entity.color
    }
    
    // Keep the presenting page's palette throughout the navigation push.
    private var sheetBackgroundColor: Color {
        isSettingsPage ? SpendyColors.settingsBackground : SpendyColors.appBackground
    }

    private var cardFillColor: Color {
        isSettingsPage ? SpendyColors.settingsCardBackground : SpendyColors.cardBackground
    }
    
    private var cardBorderColor: Color {
        Color(uiColor: .dynamic(
            light: UIColor(white: 0.0, alpha: 0.06),
            dark: UIColor(white: 1.0, alpha: 0.08)
        ))
    }
    
    private var chartTransitionID: String {
        if let custom = customDateRange {
            return "custom_\(custom.start.timeIntervalSince1970)_\(custom.end.timeIntervalSince1970)"
        }
        return selectedPeriod.rawValue
    }
    
    private var isHomeOrigin: Bool {
        topControlsNamespace != nil && periodControlMorphID == "accountDropdownCapsule"
    }
    
    private var sharedMorphNamespace: Namespace.ID {
        topControlsNamespace ?? internalSheetNamespace
    }
    
    private func pageMorphID(shared: String, fallback: String) -> String {
        topControlsNamespace == nil ? fallback : shared
    }
    
    // MARK: - Transactions & Calculation Engine
    private var allEntityTransactions: [Transaction] {
        let transactions = store.transactions.filter { spendingScope?.contains($0, includeDates: false, expensesOnly: false) ?? true }
        switch entity {
        case .category(let cat):
            return transactions.filter {
                $0.categoryId == cat.id && $0.type == cat.type
            }.sorted { $0.date > $1.date }
        case .account(let acc):
            return transactions.filter {
                $0.accountId == acc.id
            }.sorted { $0.date > $1.date }
        }
    }
    
    private var periodBounds: (start: Date, end: Date) {
        if let custom = customDateRange {
            return custom
        }
        return AnalyticsChartEngine.periodBounds(for: selectedPeriod, transactions: allEntityTransactions)
    }
    
    private var daysInSelectedPeriod: Int {
        if let custom = customDateRange {
            let diff = Calendar.current.dateComponents([.day], from: custom.start, to: custom.end).day ?? 1
            return max(1, diff + 1)
        }
        return AnalyticsChartEngine.daysInPeriod(for: selectedPeriod)
    }
    
    private var filteredTransactions: [Transaction] {
        let bounds = periodBounds
        return allEntityTransactions.filter {
            $0.date >= bounds.start && $0.date <= bounds.end
        }
    }
    
    private var totalSpent: Double {
        switch entity {
        case .category(let cat):
            if cat.type == .income {
                return filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            } else {
                return filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            }
        case .account:
            return filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        }
    }
    
    private var currentBalance: Double {
        switch entity {
        case .category:
            return totalSpent
        case .account(let acc):
            return store.balance(for: acc.id)
        }
    }
    
    private var totalInflow: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalOutflow: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var netCashFlow: Double {
        totalInflow - totalOutflow
    }
    
    private var previousPeriodSpent: Double {
        let bounds = periodBounds
        let duration = bounds.end.timeIntervalSince(bounds.start)
        let prevStart = bounds.start.addingTimeInterval(-duration)
        let prevEnd = bounds.start
        
        return allEntityTransactions
            .filter { $0.date >= prevStart && $0.date < prevEnd }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var comparisonPercentage: Double? {
        guard previousPeriodSpent > 0 else { return nil }
        let diff = totalSpent - previousPeriodSpent
        return (diff / previousPeriodSpent) * 100
    }
    
    private var dailyAverageSpent: Double {
        totalSpent / Double(max(1, daysInSelectedPeriod))
    }
    
    private var activeDaysCount: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(filteredTransactions.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    private var highestSingleDay: (date: Date, amount: Double)? {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredTransactions) { calendar.startOfDay(for: $0.date) }
        var maxDay: (date: Date, amount: Double)? = nil
        for (day, txs) in groups {
            let total = txs.reduce(0) { $0 + $1.amount }
            if maxDay == nil || total > (maxDay?.amount ?? 0) {
                maxDay = (date: day, amount: total)
            }
        }
        return maxDay
    }
    
    private var topWeekday: (name: String, dayIndex: Int) {
        let calendar = Calendar.current
        var weekdayTotals: [Int: Double] = [:]
        for tx in filteredTransactions {
            let wd = calendar.component(.weekday, from: tx.date) - 1 // 0 = Sun .. 6 = Sat
            weekdayTotals[wd, default: 0] += tx.amount
        }
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        if let maxEntry = weekdayTotals.max(by: { $0.value < $1.value }), maxEntry.value > 0 {
            let idx = max(0, min(6, maxEntry.key))
            return (dayNames[idx], idx)
        }
        return ("None", 0)
    }
    
    private var categoryBudgetAmount: Double? {
        if case .category(let cat) = entity {
            if let budgetVal = store.budget.categoryBudgets[cat.id], budgetVal > 0 {
                return budgetVal
            }
        }
        return nil
    }
    
    private var barPoints: [AnalyticsBarPoint] {
        let extractor: ([Transaction]) -> Double = { txs in
            switch entity {
            case .category(let cat):
                return txs.filter { $0.type == cat.type }.reduce(0) { $0 + $1.amount }
            case .account:
                return txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            }
        }
        return AnalyticsChartEngine.generateDiscreteBarPoints(
            transactions: allEntityTransactions,
            bounds: periodBounds,
            period: selectedPeriod,
            isCustomRange: customDateRange != nil,
            valueForBucket: extractor
        )
    }
    
    private var chartDataPoints: [MinimalBarPoint] {
        barPoints.map { MinimalBarPoint(id: $0.id, label: $0.label, amount: $0.amount) }
    }
    
    private var activeBarPoint: AnalyticsBarPoint? {
        guard let scrubbed = scrubbedBarPoint else { return nil }
        return barPoints.first(where: { $0.id == scrubbed.id })
    }
    
    // MARK: - Insights Context
    private var activeInsightContext: AnalyticsInsightContext {
        let bounds = periodBounds
        let scope: AnalyticsInsightContext.Scope = {
            switch entity {
            case .category(let cat): return .category(id: cat.id)
            case .account(let acc): return .account(id: acc.id)
            }
        }()
        
        if let custom = customDateRange {
            return AnalyticsInsightContext.custom(
                startDate: custom.start,
                endDate: custom.end,
                scope: scope,
                referenceDate: spendingScope?.referenceDate ?? Date()
            )
        } else {
            let insightPeriod: InsightPeriod = {
                switch selectedPeriod {
                case .week: return .week
                case .month: return .month
                case .threeMonths: return .threeMonths
                case .sixMonths: return .sixMonths
                case .year: return .year
                }
            }()
            
            let duration = bounds.end.timeIntervalSince(bounds.start)
            let prevEnd = bounds.start.addingTimeInterval(-1)
            let prevStart = prevEnd.addingTimeInterval(-duration)
            
            return AnalyticsInsightContext(
                scope: scope,
                period: insightPeriod,
                startDate: bounds.start,
                endDate: bounds.end,
                baselineStartDate: prevStart,
                baselineEndDate: prevEnd,
                isCustomRange: false,
                customRangeLabel: nil,
                referenceDate: spendingScope?.referenceDate ?? Date()
            )
        }
    }
    
    private var insightMoments: [InsightMoment] {
        guard store.insightsEnabled else { return [] }
        let context = activeInsightContext
        let surface: InsightSurface = {
            switch entity {
            case .category(let cat): return .category(id: cat.id)
            case .account: return .analytics
            }
        }()
        
        let facts = InsightFactsExtractor.extractFacts(
            transactions: store.transactions.filter { spendingScope?.contains($0, includeDates: false, expensesOnly: false) ?? true },
            budget: store.budget,
            categories: store.categories,
            subscriptions: store.subscriptions,
            context: context
        )
        return InsightDecisionEngine.shared.evaluate(
            facts: facts,
            surface: surface,
            period: context.period,
            currencySymbol: store.currencySymbol,
            now: context.referenceDate
        )
    }
    
    private var visibleInsights: [InsightMoment] {
        Array(insightMoments.filter { !$0.isInsufficientData }.prefix(5))
    }
    
    private var availableSections: [AnalyticsSheetSection] {
        [.overview, .activity]
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            sheetBackgroundColor.ignoresSafeArea()
            if !isSettingsPage {
                SpendyAmbientHeaderBackground(
                    color: themeColor,
                    height: 440,
                    opacity: 0.24
                )
            }
            
            SpendyPinnedHeaderLayout(isEnabled: isHomeOrigin) {

                if isHomeOrigin {
                    topHeaderBar
                }
            } content: {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        heroIdentityAndAmount
                            .padding(.horizontal, 20)
                            .padding(.top, isHomeOrigin ? 8 : 12)
                        
                        chartSection
                            .padding(.horizontal, 16)
                        
                        scrubberAndCalendarRow
                            .padding(.horizontal, 16)
                        
                        if !visibleInsights.isEmpty, !isScrubbingChart {
                            SpendyInsightSummary(moments: visibleInsights, canSelect: { destination in
                                if case .transaction = destination { return true }
                                return false
                            }) { destination in
                                if case .transaction(let id) = destination {
                                    inspectingTransaction = store.transactions.first { $0.id == id }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        threeSectionsModule
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40)
                    }
                }
                .scrollDisabled(isScrubbingChart)
            }
        }
        .presentationBackground(sheetBackgroundColor)
        .navigationTitle(isHomeOrigin ? "" : entity.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(isHomeOrigin ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            if !isHomeOrigin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.shared.trigger(.light)
                        triggerEditEntity()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Edit \(entity.label)")
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DateRangePickerSheet(startDate: $customStartDate, endDate: $customEndDate) { start, end in
                customDateRange = (start, end)
                scrubbedBarPoint = nil
                isScrubbingChart = false
            }
        }
        .fullScreenCover(isPresented: $showAddTransaction) {
            switch entity {
            case .category(let cat):
                AddTransactionView(defaultCategoryId: cat.id)
            case .account(let acc):
                AddTransactionView(defaultAccountId: acc.id)
            }
        }
        .sheet(item: $editingCategoryToEdit) { cat in
            AddCategorySheet(categoryToEdit: cat, isSettingsPage: isSettingsPage)
        }
        .sheet(item: $editingAccountToEdit) { acc in
            AddAccountSheet(accountToEdit: acc)
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
        .fullScreenCover(item: $editingTransaction) { tx in
            AddTransactionView(transactionToEdit: tx)
        }
        .onAppear {
            if !appliedSpendingScope, let spendingScope {
                customDateRange = (spendingScope.start, spendingScope.end.addingTimeInterval(-0.000001))
                customStartDate = spendingScope.start
                customEndDate = spendingScope.end.addingTimeInterval(-0.000001)
                appliedSpendingScope = true
            }
            selectedSection = .overview
        }
        .onChange(of: availableSections) { _, newSections in
            if !newSections.contains(selectedSection) {
                selectedSection = newSections.first ?? .overview
            }
        }
    }
    
    // MARK: - 1. Top Header Bar (When Pushed with Liquid Glass Morph)
    private var topHeaderBar: some View {
        HStack {
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 15,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Back",
                morphID: backButtonMorphID,
                namespace: topControlsNamespace
            ) {
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }
            
            Spacer()
            
            VStack(spacing: 1) {
                Text(entity.label)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                
                Text(entity.subtitle)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            GlassCircleButton(
                icon: "pencil",
                size: 44,
                iconSize: 15,
                iconWeight: .semibold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .light,
                accessibilityLabel: "Edit \(entity.label)",
                morphID: pageMorphID(shared: editButtonMorphID, fallback: "editButton"),
                namespace: sharedMorphNamespace
            ) {
                HapticsManager.shared.trigger(.light)
                triggerEditEntity()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
    
    private func triggerEditEntity() {
        switch entity {
        case .category(let cat):
            editingCategoryToEdit = cat
        case .account(let acc):
            editingAccountToEdit = acc
        }
    }
    
    // MARK: - Hero Amount + Entity Icon (uncarded, matches Home)
    private var heroDisplayAmount: Double {
        if let bar = activeBarPoint {
            return bar.amount
        }
        return totalSpent
    }
    
    private var heroCaption: String {
        if let bar = activeBarPoint {
            let dateLabel = AnalyticsChartEngine.formattedPointDate(bar.date, period: selectedPeriod)
            return entity.defaultType == .income ? "Received · \(dateLabel)" : "Spent · \(dateLabel)"
        }
        switch entity {
        case .category(let cat):
            return cat.type == .income ? "Total received" : "Total spent"
        case .account:
            return "Spent"
        }
    }
    
    private var heroIdentityAndAmount: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(heroCaption)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .animation(.easeInOut(duration: 0.15), value: activeBarPoint?.id)
                
                if let ids = spendingScope?.accountIDs {
                    Text(ids.count == 1 ? store.account(for: ids.first!).label : "\(ids.count) selected accounts")
                        .font(.caption).foregroundStyle(SpendyColors.textSecondary)
                }
                SpendyGradientText(
                    heroDisplayAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 2),
                    size: 38,
                    weight: .heavy,
                    tracking: -1.0,
                    colors: SpendyGradientPresets.electricBlueToWhite
                )
                .accessibilityIdentifier("entity-spending-total")
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: activeBarPoint?.id)
                
                if activeBarPoint == nil {
                    heroSecondaryLine
                } else if let bar = activeBarPoint {
                    Text(bar.txCount == 1 ? "1 transaction" : "\(bar.txCount) transactions")
                        .font(AppTypography.footnoteMedium)
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            
            Spacer(minLength: 8)
            
            SpendyIconBadge(
                sfSymbol: entity.sfSymbol,
                color: themeColor,
                size: .large,
                style: entity.isAccount ? .rounded() : .circle,
                monogramName: entity.monogramName
            )
            .padding(.top, 2)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(heroCaption), \(heroDisplayAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 2))")
    }
    
    @ViewBuilder
    private var heroSecondaryLine: some View {
        if let custom = customDateRange {
            Text("\(custom.start.formatted(date: .abbreviated, time: .omitted)) – \(custom.end.formatted(date: .abbreviated, time: .omitted))")
                .font(AppTypography.footnoteMedium)
                .foregroundStyle(SpendyColors.textSecondary)
        } else if let pct = comparisonPercentage {
            let isIncrease = pct > 0
            let isGood = entity.defaultType == .income ? isIncrease : !isIncrease
            HStack(spacing: 4) {
                Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 11, weight: .bold))
                Text("\(String(format: "%.0f", abs(pct)))% vs previous period")
                    .font(AppTypography.footnoteMedium)
            }
            .foregroundStyle(isGood ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
        }
    }
    
    private func insightSentence(_ moment: InsightMoment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ShinyHeadlineText(
                headline: moment.headline,
                emphasis: moment.emphasis,
                font: .system(size: 15, weight: .semibold)
            )
            if let supporting = moment.supportingText, !supporting.isEmpty {
                InsightSupportingText(text: supporting, emphasis: moment.emphasis)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Home-style discrete bar chart
    private var chartSection: some View {
        HeroSpendBarChart(
            dataPoints: chartDataPoints,
            scrubbedPoint: $scrubbedBarPoint,
            isScrubbing: $isScrubbingChart,
            barColor: SpendyColors.isMonoMode ? SpendyColors.monoGraphLine : SpendyColors.textPrimary,
            barTopCornerRadius: 5
        )
        .id(chartTransitionID)
        .accessibilityLabel("Spending chart for \(entity.label)")
    }
    
    // MARK: - 4. Period Scrubber Strip & Calendar Row
    private var scrubberAndCalendarRow: some View {
        SpendyGlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                GlassSegmentedPicker(
                    selection: $selectedPeriod,
                    items: ChartPeriod.allCases,
                    titleFor: { $0.shortLabel }
                )
                .onChange(of: selectedPeriod) { _, _ in
                    customDateRange = nil
                    scrubbedBarPoint = nil
                    isScrubbingChart = false
                }
                .glassMorphID(pageMorphID(shared: periodControlMorphID, fallback: "periodCapsule"), in: sharedMorphNamespace)
                
                // Calendar Date Picker Button
                GlassCircleButton(
                    icon: "calendar",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    tintColor: customDateRange != nil ? (SpendyColors.isMonoMode ? SpendyColors.cardBackgroundSecondary : themeColor.opacity(0.3)) : nil,
                    foregroundColor: customDateRange != nil ? (SpendyColors.isMonoMode ? SpendyColors.textPrimary : themeColor) : SpendyColors.textPrimary,
                    haptic: .selection,
                    accessibilityLabel: "Select Date Range",
                    morphID: pageMorphID(shared: calendarControlMorphID, fallback: "calendarButton"),
                    namespace: sharedMorphNamespace
                ) {
                    showDatePicker = true
                }
            }
        }
    }
    
    // MARK: - 5. Three Sections Module (Buttons + Horizontal Swiping)
    private var threeSectionsModule: some View {
        VStack(spacing: 16) {
            // Section Switcher Buttons
            sectionButtonsBar
            
            // Section Content (Full width, no restrictive container)
            sectionContent
                .gesture(
                    DragGesture(minimumDistance: 35)
                        .onEnded { value in
                            handleHorizontalSwipe(translation: value.translation.width)
                        }
                )
        }
    }
    
    private var sectionButtonsBar: some View {
        HStack(spacing: 8) {
            ForEach(availableSections, id: \.id) { section in
                let isSelected = selectedSection == section
                Button {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selectedSection = section
                    }
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(SpendyColors.cardBackgroundSecondary)
                                    .overlay(Capsule().stroke(cardBorderColor, lineWidth: 0.8))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .overview:
            overviewSectionView
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .leading)),
                    removal: .opacity.combined(with: .move(edge: .trailing))
                ))
        case .activity:
            recentActivitySectionView
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
        }
    }
    
    private func handleHorizontalSwipe(translation: CGFloat) {
        let threshold: CGFloat = 40
        if translation < -threshold {
            // Swiped Left -> Move forward
            if selectedSection == .overview {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    selectedSection = .activity
                }
            }
        } else if translation > threshold {
            // Swiped Right -> Move back
            if selectedSection == .activity {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    selectedSection = .overview
                }
            }
        }
    }
    
    // MARK: - Section 1: Overview (Unified Metrics)
    private var overviewSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(overviewRows.enumerated()), id: \.element.id) { index, row in
                    overviewRow(
                        flowType: row.flowType,
                        label: row.label,
                        value: row.value,
                        valueColor: row.valueColor
                    )
                    .padding(.vertical, 14)
                    
                    if index < overviewRows.count - 1 {
                        Divider().overlay(SpendyColors.separator.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(cardFillColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(cardBorderColor, lineWidth: 0.8)
                    }
            }
        }
    }
    
    private struct OverviewMetric: Identifiable {
        let id: String
        let flowType: SpendyFlowType?
        let label: String
        let value: String
        let valueColor: Color
    }
    
    private var overviewRows: [OverviewMetric] {
        var rows: [OverviewMetric] = []
        let showInflow: Bool = {
            if case .category(let cat) = entity, cat.type == .expense, totalInflow == 0 {
                return false
            }
            return true
        }()
        let showOutflow: Bool = {
            if case .category(let cat) = entity, cat.type == .income, totalOutflow == 0 {
                return false
            }
            return true
        }()
        
        if showInflow {
            rows.append(OverviewMetric(
                id: "in",
                flowType: .income,
                label: "Money in",
                value: "+\(totalInflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                valueColor: SpendyColors.incomeGreen
            ))
        }
        if showOutflow {
            rows.append(OverviewMetric(
                id: "out",
                flowType: .expense,
                label: "Money out",
                value: "-\(totalOutflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                valueColor: SpendyColors.textPrimary
            ))
        }
        if showInflow && showOutflow {
            rows.append(OverviewMetric(
                id: "net",
                flowType: .net(isPositive: netCashFlow >= 0),
                label: "Net cash flow",
                value: "\(netCashFlow >= 0 ? "+" : "-")\(abs(netCashFlow).formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                valueColor: netCashFlow >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed
            ))
        }
        
        if let budget = categoryBudgetAmount {
            let remaining = budget - totalOutflow
            rows.append(OverviewMetric(
                id: "budget",
                flowType: remaining >= 0 ? .income : .expense,
                label: remaining >= 0 ? "Budget left" : "Over budget",
                value: "\(remaining >= 0 ? "+" : "-")\(abs(remaining).formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                valueColor: remaining >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed
            ))
        } else if case .account = entity {
            rows.append(OverviewMetric(
                id: "balance",
                flowType: currentBalance >= 0 ? .income : .expense,
                label: "Current balance",
                value: currentBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                valueColor: currentBalance >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed
            ))
        }
        
        rows.append(OverviewMetric(
            id: "active",
            flowType: nil,
            label: "Active days",
            value: "\(activeDaysCount) \(activeDaysCount == 1 ? "day" : "days")",
            valueColor: SpendyColors.textPrimary
        ))
        
        if !filteredTransactions.isEmpty {
            rows.append(OverviewMetric(
                id: "peak",
                flowType: nil,
                label: "Peak weekday",
                value: topWeekday.name,
                valueColor: SpendyColors.textPrimary
            ))
        }
        
        rows.append(OverviewMetric(
            id: "rate",
            flowType: nil,
            label: entity.defaultType == .income ? "Daily inflow rate" : "Daily outflow rate",
            value: "\(dailyAverageSpent.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day",
            valueColor: SpendyColors.textPrimary
        ))
        
        return rows
    }
    
    // MARK: - Overview List Row (Image 2 with Reusable Flow Indicators)
    private func overviewRow(flowType: SpendyFlowType? = nil, label: String, value: String, valueColor: Color) -> some View {
        HStack(spacing: 9) {
            if let flowType = flowType {
                SpendyFlowIndicator(type: flowType, size: 14)
            }
            
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16.5, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(valueColor)
        }
    }
    
    // MARK: - Section 2: Recent Activity (Unified Grouped Container Matching Home Page)
    private var recentActivitySectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Recent transactions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Spacer()
                
                if !filteredTransactions.isEmpty {
                    Text("\(filteredTransactions.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
                }
            }
            .padding(.horizontal, 4)
            
            if filteredTransactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(SpendyColors.textTertiary)
                    Text("No transactions found")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(cardFillColor)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(cardBorderColor, lineWidth: 0.8)
                        }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredTransactions.enumerated()), id: \.element.id) { index, tx in
                        analyticsTransactionRow(tx)
                        
                        if index < filteredTransactions.count - 1 {
                            Rectangle()
                                .fill(SpendyColors.separator.opacity(0.6))
                                .frame(height: 0.5)
                                .padding(.leading, 58)
                                .padding(.trailing, 16)
                        }
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(cardFillColor)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(cardBorderColor, lineWidth: 0.8)
                        }
                }
            }
        }
    }
    
    private func analyticsTransactionRow(_ tx: Transaction) -> some View {
        let cat = store.categories.first(where: { $0.id == tx.categoryId })
        let acc = store.accounts.first(where: { $0.id == tx.accountId })
        let subscription = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == tx.subscriptionId?.lowercased() })
        
        let iconSymbol = subscription?.sfSymbol ?? (cat?.sfSymbol ?? entity.sfSymbol)
        let iconColor = subscription?.color ?? (cat?.color ?? entity.color)
        let iconName = subscription?.name ?? cat?.label ?? entity.monogramName
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            inspectingTransaction = tx
        }) {
            HStack(spacing: 14) {
                // Category / Subscription / Account Icon Badge
                SpendyIconBadge(
                    sfSymbol: iconSymbol,
                    color: iconColor,
                    size: .medium,
                    style: .circle,
                    monogramName: iconName
                )
                
                // Middle: Title + Subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(tx.title.isEmpty ? (cat?.label ?? "Expense") : tx.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    switch entity {
                    case .category:
                        if let acc = acc {
                            HStack(spacing: 5) {
                                SpendyMiniColorChip(
                                    sfSymbol: acc.sfSymbol.isEmpty ? acc.type.defaultSymbol : acc.sfSymbol,
                                    color: acc.color,
                                    monogramName: acc.label
                                )
                                
                                Text("\(acc.label) • \(tx.date.formattedRelative)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(SpendyColors.textSecondary)
                                    .lineLimit(1)
                            }
                        } else {
                            Text(tx.date.formattedRelative)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                        }
                    case .account:
                        if let cat = cat {
                            HStack(spacing: 5) {
                                SpendyMiniColorChip(
                                    sfSymbol: cat.sfSymbol,
                                    color: cat.color,
                                    isCircle: true,
                                    monogramName: cat.label
                                )
                                
                                Text("\(cat.label) • \(tx.date.formattedRelative)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(SpendyColors.textSecondary)
                                    .lineLimit(1)
                            }
                        } else {
                            Text(tx.date.formattedRelative)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Right: Amount
                Text("\(tx.type == .income ? "+" : "-")\(tx.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                    .font(.system(size: 16.5, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(tx.type == .income ? SpendyColors.incomeGreen : SpendyColors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
