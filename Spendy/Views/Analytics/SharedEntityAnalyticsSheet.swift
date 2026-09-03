//
//  SharedEntityAnalyticsSheet.swift
//  Spendy
//
//  Unified Analytics Sheet for Categories and Accounts.
//  Features:
//  - Clean solid background (no top ambient glow gradient), adaptive for both Light and Dark mode
//  - Top iOS-style metric card: Left side total amount + clean trend number (no pill) + subtitle, Right side icon badge
//  - Bottom row of top card: date range label without calendar icon + active days
//  - High-fidelity Swift Chart: pure clean line curve with area fill, trailing Y-axis numbers, X-axis dates, interactive crosshair (no bar charts)
//  - Standard index period scrubber strip (1W, 2W, 1M, 3M, 6M, 1Y, ALL) + calendar date-range picker
//  - 3 full-width sections: Overview, Recent Activity, Insights
//  - Overview section features:
//      * Top 3-metric summary card (Expenses, Income, Net)
//      * Full-width clean list with dividers (Money in, Money out, Net cash flow, Active days, Peak weekday, Daily outflow rate)
//  - Tappable section buttons + natural horizontal swipe navigation
//

import SwiftUI
import Charts

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
}

// MARK: - Section Tab Enum
enum AnalyticsSheetSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case activity = "Recent Activity"
    case insights = "Insights"
    
    var id: String { rawValue }
}

// MARK: - Shared Entity Analytics Sheet
struct SharedEntityAnalyticsSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let entity: AnalyticsEntity
    var initialType: TransactionType = .expense
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
    @State private var scrubbedDate: Date? = nil
    @State private var scrubbedPoint: CategoryChartPoint? = nil
    
    // Lower Section Navigation
    @State private var selectedSection: AnalyticsSheetSection = .overview
    
    // Sheet Modals State
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var editingCategoryToEdit: Category? = nil
    @State private var editingAccountToEdit: Account? = nil
    @State private var showDatePicker: Bool = false
    @State private var showAddTransaction: Bool = false
    
    @Namespace private var internalSheetNamespace
    
    // MARK: - Colors & Theming (Light & Dark Mode Adaptive)
    private var themeColor: Color {
        entity.color
    }
    
    private var chartThemeColor: Color {
        SpendyColors.isMonoMode ? SpendyColors.monoGraphLine : entity.color
    }
    
    private var cardFillColor: Color {
        Color(uiColor: .dynamic(
            light: UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0),
            dark: UIColor(red: 22.0/255.0, green: 22.0/255.0, blue: 24.0/255.0, alpha: 1.0)
        ))
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
        switch entity {
        case .category(let cat):
            return store.transactions.filter {
                $0.categoryId == cat.id && $0.type == cat.type
            }.sorted { $0.date > $1.date }
        case .account(let acc):
            return store.transactions.filter {
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
    
    private var chartPoints: [CategoryChartPoint] {
        AnalyticsChartEngine.generateChartPoints(
            transactions: allEntityTransactions,
            period: selectedPeriod,
            hasEnoughTxs: false
        ).filter { !$0.isPredicted }
    }
    
    private var periodHeaderLabel: String {
        let formatter = DateFormatter()
        let bounds = periodBounds
        if customDateRange != nil {
            formatter.dateFormat = "d MMM"
            return "\(formatter.string(from: bounds.start)) – \(formatter.string(from: bounds.end))"
        }
        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: bounds.start)) – \(formatter.string(from: bounds.end))"
        case .twoWeeks:
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: bounds.start)) – \(formatter.string(from: bounds.end))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: bounds.start)
        case .threeMonths:
            return "Last 3 Months"
        case .sixMonths:
            return "Last 6 Months"
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: bounds.start)
        case .all:
            return "All Time"
        }
    }
    
    private var dateGroupedTransactions: [(String, Double, [Transaction])] {
        AnalyticsChartEngine.dateGroupedTransactions(from: filteredTransactions)
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
                referenceDate: Date()
            )
        } else {
            let insightPeriod: InsightPeriod = {
                switch selectedPeriod {
                case .week: return .week
                case .twoWeeks: return .week
                case .month: return .month
                case .threeMonths: return .threeMonths
                case .sixMonths: return .sixMonths
                case .year: return .year
                case .all: return .all
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
                referenceDate: Date()
            )
        }
    }
    
    private var insightMoments: [InsightMoment] {
        let context = activeInsightContext
        let surface: InsightSurface = {
            switch entity {
            case .category(let cat): return .category(id: cat.id)
            case .account: return .analytics
            }
        }()
        
        let facts = InsightFactsExtractor.extractFacts(
            transactions: store.transactions,
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
    
    private var availableSections: [AnalyticsSheetSection] {
        if insightMoments.isEmpty {
            return [.overview, .activity]
        } else {
            return [.overview, .activity, .insights]
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Adaptive background for both light and dark mode (no top ambient glow gradient)
            SpendyColors.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isHomeOrigin {
                    topHeaderBar
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Top Rectangular iOS Metric Card (Amount on left, icon on right, no pill)
                        topMetricCard
                            .padding(.horizontal, 16)
                            .padding(.top, isHomeOrigin ? 4 : 8)
                        
                        // 2. High-Fidelity Swift Chart (Clean curve, trailing Y-axis numbers, no volume bars)
                        chartSection
                            .padding(.horizontal, 16)
                        
                        // 3. Horizontal Scrubber Pill Strip + Calendar
                        scrubberAndCalendarRow
                            .padding(.horizontal, 16)
                        
                        // 4. Three Sections Down: Buttons Switcher + Full-Width Swipeable Pages
                        threeSectionsModule
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 40)
                    }
                }
            }
        }
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
            AddCategorySheet(categoryToEdit: cat)
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $editingAccountToEdit) { acc in
            AddAccountSheet(accountToEdit: acc)
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $inspectingTransaction) { tx in
            TransactionDetailSheet(transaction: tx) { txToEdit in
                inspectingTransaction = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    editingTransaction = txToEdit
                }
            }
        }
        .fullScreenCover(item: $editingTransaction) { tx in
            AddTransactionView(transactionToEdit: tx)
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
    
    // MARK: - 2. Top Metric Card (Left: Total Amount + Trend, Right: Icon Badge, No Pill, No Calendar Icon)
    private var topMetricCard: some View {
        let displayAmount: Double = {
            if let scrubbed = scrubbedPoint {
                return scrubbed.amount
            }
            switch entity {
            case .category:
                return totalSpent
            case .account:
                return currentBalance
            }
        }()
        
        let isScrubbing = scrubbedPoint != nil
        
        return VStack(spacing: 12) {
            // Row 1: Left = Total Amount & Trend text, Right = Category Icon Badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    // Amount and Trend number row (Number + arrow directly, no pill capsule background)
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(displayAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        trendOrSecondaryText(isScrubbing: isScrubbing)
                    }
                    
                    Text(cardPrimarySubtitle(isScrubbing: isScrubbing))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Spacer()
                
                // Right side: Icon Badge of the category/account
                SpendyIconBadge(
                    sfSymbol: entity.sfSymbol,
                    color: themeColor,
                    size: .large,
                    style: .circle
                )
            }
            
            Divider()
                .overlay(SpendyColors.separator.opacity(0.6))
            
            // Row 2: Left = Date range (no calendar icon!), Right = Active days count
            HStack {
                Text(cardSecondaryDateLabel(isScrubbing: isScrubbing))
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Text(cardSecondaryRateLabel(isScrubbing: isScrubbing))
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(SpendyColors.textPrimary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardFillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 8, y: 3)
        }
    }
    
    private func cardPrimarySubtitle(isScrubbing: Bool) -> String {
        if let scrubbed = scrubbedPoint {
            return AnalyticsChartEngine.formattedPointDate(scrubbed.date, period: selectedPeriod)
        }
        switch entity {
        case .category(let cat):
            return cat.type == .income ? "Total Inflow" : "Total Spent"
        case .account:
            return "Current Balance"
        }
    }
    
    private func cardSecondaryDateLabel(isScrubbing: Bool) -> String {
        if isScrubbing {
            return "Scrubbing timeline"
        }
        return periodHeaderLabel
    }
    
    private func cardSecondaryRateLabel(isScrubbing: Bool) -> String {
        if let scrubbed = scrubbedPoint {
            if scrubbed.dayVolume > 0 {
                return "Day: \(scrubbed.dayVolume.formattedCurrency(symbol: store.currencySymbol, decimals: 0))"
            } else {
                return "\(scrubbed.txCount) txs"
            }
        }
        return "\(activeDaysCount) active days"
    }
    
    @ViewBuilder
    private func trendOrSecondaryText(isScrubbing: Bool) -> some View {
        if let scrubbed = scrubbedPoint {
            Text(scrubbed.dayVolume.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(themeColor)
        } else if case .account = entity {
            let isPositive = netCashFlow >= 0
            HStack(spacing: 2) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                Text("\(isPositive ? "+" : "-")\(abs(netCashFlow).formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(isPositive ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
        } else if let pct = comparisonPercentage {
            let isIncrease = pct > 0
            let isGood = entity.defaultType == .income ? isIncrease : !isIncrease
            let color = isGood ? SpendyColors.incomeGreen : SpendyColors.expenseRed
            
            HStack(spacing: 2) {
                Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                Text("\(String(format: "%.0f", abs(pct)))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(color)
        }
    }
    
    // MARK: - 3. High-Fidelity Swift Chart (Clean Curve, No Bar Charts)
    private var chartSection: some View {
        VStack(spacing: 6) {
            if chartPoints.isEmpty || (totalSpent == 0 && currentBalance == 0) {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.flattrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundStyle(SpendyColors.textTertiary)
                    Text("No transactions in this period")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(cardFillColor.opacity(0.5))
                }
            } else {
                Chart {
                    // 1. Area Gradient below curve
                    ForEach(chartPoints) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [chartThemeColor.opacity(0.28), chartThemeColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)
                    }
                    
                    // 2. Solid Smooth Line Curve
                    ForEach(chartPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(chartThemeColor)
                        .lineStyle(StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                    }
                    
                    // 3. Default End Anchor Beacon (When not scrubbing)
                    if scrubbedPoint == nil, let lastActual = chartPoints.last {
                        PointMark(
                            x: .value("Date", lastActual.date),
                            y: .value("Amount", lastActual.amount)
                        )
                        .symbol {
                            ZStack {
                                Circle()
                                    .fill(chartThemeColor.opacity(0.35))
                                    .frame(width: 16, height: 16)
                                Circle()
                                    .fill(chartThemeColor)
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 3.5, height: 3.5)
                            }
                        }
                    }
                    
                    // 4. Interactive Scrub Crosshair & Anchor Beacon
                    if let scrubbed = scrubbedPoint {
                        RuleMark(x: .value("Date", scrubbed.date))
                            .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                            .foregroundStyle(SpendyColors.textSecondary.opacity(0.6))
                        
                        PointMark(
                            x: .value("Date", scrubbed.date),
                            y: .value("Amount", scrubbed.amount)
                        )
                        .symbol {
                            ZStack {
                                Circle()
                                    .fill(chartThemeColor.opacity(0.4))
                                    .frame(width: 22, height: 22)
                                Circle()
                                    .fill(chartThemeColor)
                                    .frame(width: 11, height: 11)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                }
                .chartXScale(domain: periodBounds.start...periodBounds.end)
                .chartXSelection(value: $scrubbedDate)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        if let dateVal = value.as(Date.self) {
                            AxisValueLabel {
                                Text(AnalyticsChartEngine.axisLabel(for: dateVal, period: selectedPeriod))
                                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(SpendyColors.separator.opacity(0.4))
                        if let doubleVal = value.as(Double.self) {
                            AxisValueLabel {
                                Text(formatYAxis(doubleVal))
                                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                        }
                    }
                }
                .frame(height: 205)
                .onChange(of: scrubbedDate) { _, newDate in
                    handleScrub(date: newDate)
                }
            }
        }
    }
    
    private func formatYAxis(_ val: Double) -> String {
        if val >= 1_000_000 {
            return String(format: "%.1fM", val / 1_000_000)
        } else if val >= 1_000 {
            return String(format: "%.0fK", val / 1_000)
        } else {
            return String(format: "%.0f", val)
        }
    }
    
    private func handleScrub(date: Date?) {
        guard let date = date, !chartPoints.isEmpty else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                scrubbedPoint = nil
            }
            return
        }
        
        let closest = chartPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
        
        if closest != scrubbedPoint {
            HapticsManager.shared.trigger(.selection)
            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.85)) {
                scrubbedPoint = closest
            }
        }
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
                    scrubbedDate = nil
                    scrubbedPoint = nil
                }
                .glassMorphID(pageMorphID(shared: periodControlMorphID, fallback: "periodCapsule"), in: sharedMorphNamespace)
                
                // Calendar Date Picker Button
                GlassCircleButton(
                    icon: "calendar",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    tintColor: customDateRange != nil ? themeColor.opacity(0.3) : nil,
                    foregroundColor: customDateRange != nil ? themeColor : SpendyColors.textPrimary,
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
        HStack(spacing: 6) {
            ForEach(availableSections, id: \.id) { section in
                let isSelected = selectedSection == section
                Button {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(section.rawValue)
                            .font(.system(size: 13.5, weight: isSelected ? .bold : .semibold, design: .rounded))
                            .lineLimit(1)
                        
                        if section == .insights, !insightMoments.isEmpty {
                            Circle()
                                .fill(themeColor)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .foregroundStyle(isSelected ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                    .background {
                        if isSelected {
                            Capsule(style: .continuous)
                                .fill(cardFillColor)
                                .overlay {
                                    Capsule(style: .continuous)
                                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                                }
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 4, y: 1)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    private func handleHorizontalSwipe(translation: CGFloat) {
        let sections = availableSections
        guard let currentIndex = sections.firstIndex(of: selectedSection) else { return }
        
        if translation < -40 && currentIndex < sections.count - 1 {
            // Swiped left -> move to next section
            HapticsManager.shared.trigger(.selection)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selectedSection = sections[currentIndex + 1]
            }
        } else if translation > 40 && currentIndex > 0 {
            // Swiped right -> move to previous section
            HapticsManager.shared.trigger(.selection)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selectedSection = sections[currentIndex - 1]
            }
        }
    }
    
    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .overview:
            overviewSectionView
                .transition(.opacity)
        case .activity:
            recentActivitySectionView
                .transition(.opacity)
        case .insights:
            insightsSectionView
                .transition(.opacity)
        }
    }
    
    // MARK: - Section 1: Overview (Image 3 Top Card + Image 2 Clean List)
    private var overviewSectionView: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 1. Top 3-Metric Summary Card (Image 3: Expenses, Income, Net)
            threeMetricSummaryCard
            
            // 2. Clean List of Metrics with Dividers (Image 2)
            VStack(alignment: .leading, spacing: 0) {
                Text("Overview")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 0) {
                    // Money in
                    overviewRow(
                        label: "Money in",
                        value: "+\(totalInflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                        valueColor: SpendyColors.incomeGreen
                    )
                    Divider().overlay(SpendyColors.separator.opacity(0.7)).padding(.vertical, 14)
                    
                    // Money out
                    overviewRow(
                        label: "Money out",
                        value: "-\(totalOutflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                        valueColor: SpendyColors.textPrimary
                    )
                    Divider().overlay(SpendyColors.separator.opacity(0.7)).padding(.vertical, 14)
                    
                    // Net cash flow
                    overviewRow(
                        label: "Net cash flow",
                        value: "\(netCashFlow >= 0 ? "+" : "-")\(abs(netCashFlow).formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                        valueColor: netCashFlow >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed
                    )
                    Divider().overlay(SpendyColors.separator.opacity(0.7)).padding(.vertical, 14)
                    
                    // Budget Left / Over Budget (if budgeted)
                    if let budget = categoryBudgetAmount {
                        let remaining = budget - totalOutflow
                        overviewRow(
                            label: remaining >= 0 ? "Budget left" : "Over budget",
                            value: "\(remaining >= 0 ? "+" : "-")\(abs(remaining).formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                            valueColor: remaining >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed
                        )
                        Divider().overlay(SpendyColors.separator.opacity(0.7)).padding(.vertical, 14)
                    } else if case .account = entity {
                        overviewRow(
                            label: "Current balance",
                            value: currentBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                            valueColor: currentBalance >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed
                        )
                        Divider().overlay(SpendyColors.separator.opacity(0.7)).padding(.vertical, 14)
                    }
                    
                    // Active days
                    overviewRow(
                        label: "Active days",
                        value: "\(activeDaysCount) \(activeDaysCount == 1 ? "day" : "days")",
                        valueColor: SpendyColors.textPrimary
                    )
                    Divider().overlay(SpendyColors.separator.opacity(0.7)).padding(.vertical, 14)
                    
                    // Peak weekday
                    overviewRow(
                        label: "Peak weekday",
                        value: topWeekday.name,
                        valueColor: SpendyColors.textPrimary
                    )
                    Divider().overlay(SpendyColors.separator.opacity(0.7)).padding(.vertical, 14)
                    
                    // Daily outflow/inflow rate
                    overviewRow(
                        label: entity.defaultType == .income ? "Daily inflow rate" : "Daily outflow rate",
                        value: "\(dailyAverageSpent.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day",
                        valueColor: SpendyColors.textPrimary
                    )
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Three-Metric Summary Card (Image 3: Expenses, Income, Net)
    private var threeMetricSummaryCard: some View {
        HStack(spacing: 0) {
            // Expenses
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text("Expenses")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Text(totalOutflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Income
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.left.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text("Income")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Text(totalInflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(SpendyColors.incomeGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Net
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: "equal.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text("Net")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Text("\(netCashFlow >= 0 ? "+" : "-")\(abs(netCashFlow).formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(netCashFlow >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardFillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 6, y: 2)
        }
    }
    
    // MARK: - Overview List Row (Image 2)
    private func overviewRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16.5, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(valueColor)
        }
    }
    
    // MARK: - Section 2: Recent Activity (Full-Width Date-Grouped Transactions)
    private var recentActivitySectionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            if dateGroupedTransactions.isEmpty {
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
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(cardFillColor)
                }
            } else {
                VStack(spacing: 16) {
                    ForEach(dateGroupedTransactions, id: \.0) { dateGroup, dayTotal, txs in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(dateGroup)
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundStyle(SpendyColors.textSecondary)
                                
                                Spacer()
                                
                                Text(dayTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                ForEach(Array(txs.enumerated()), id: \.element.id) { idx, tx in
                                    AnalyticsTransactionRowView(
                                        tx: tx,
                                        entity: entity,
                                        currencySymbol: store.currencySymbol,
                                        cardFillColor: cardFillColor,
                                        onSelect: {
                                            HapticsManager.shared.trigger(.selection)
                                            inspectingTransaction = tx
                                        }
                                    )
                                    
                                    if idx < txs.count - 1 {
                                        Divider()
                                            .overlay(SpendyColors.separator)
                                            .padding(.leading, 64)
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(SpendyColors.separator, lineWidth: 0.7)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Section 3: Insights (Smart Moments)
    private var insightsSectionView: some View {
        VStack(spacing: 12) {
            EditorialInsightRailView(
                moments: insightMoments,
                showSectionHeader: false
            )
        }
    }
}

// MARK: - Extracted Transaction Row Subview for Swift Compiler Optimization
private struct AnalyticsTransactionRowView: View {
    @Environment(ExpenseStore.self) private var store
    
    let tx: Transaction
    let entity: AnalyticsEntity
    let currencySymbol: String
    let cardFillColor: Color
    let onSelect: () -> Void
    
    private var category: Category? {
        store.categories.first(where: { $0.id == tx.categoryId })
    }
    
    private var account: Account? {
        store.accounts.first(where: { $0.id == tx.accountId })
    }
    
    private var subscription: Subscription? {
        store.subscriptions.first(where: { $0.id.uuidString.lowercased() == tx.subscriptionId?.lowercased() })
    }
    
    private var iconSymbol: String {
        subscription?.sfSymbol ?? (category?.sfSymbol ?? entity.sfSymbol)
    }
    
    private var iconColor: Color {
        subscription?.color ?? (category?.color ?? entity.color)
    }
    
    private var sublabel: String {
        switch entity {
        case .category:
            return account?.label ?? "General Account"
        case .account:
            return category?.label ?? "General Category"
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                SpendyIconBadge(
                    sfSymbol: iconSymbol,
                    color: iconColor,
                    size: .medium,
                    style: .circle
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(sublabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Spacer()
                
                Text("\(tx.type == .income ? "+" : "-")\(tx.amount.formattedCurrency(symbol: currencySymbol, decimals: 0))")
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(tx.type == .income ? SpendyColors.incomeGreen : SpendyColors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
            .background(cardFillColor)
        }
        .buttonStyle(.plain)
    }
}
