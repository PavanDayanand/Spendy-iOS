//
//  CategoryAnalyticsSheet.swift
//  Spendy
//
//  Dedicated Category Sheet with Vibrant Category Gradient Glow, SwiftCharts Area Graph,
//  Top-Right Calendar Index Menu, Bento Insight Cards, Bank-Badged Transactions List,
//  and TransactionDetailSheet Drawer Integration.
//

import SwiftUI
import Charts


// MARK: - Category Analytics Sheet
struct CategoryAnalyticsSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let category: Category
    var initialType: TransactionType = .expense
    var topControlsNamespace: Namespace.ID? = nil
    var backButtonMorphID: String = "topControl_left"
    var editButtonMorphID: String = "topControl_right"
    var periodControlMorphID: String = "periodNavCapsule"
    var calendarControlMorphID: String = "calendarMenu"
    var onDismiss: (() -> Void)? = nil
    
    @State private var selectedPeriod: ChartPeriod = .month
    @State private var customDateRange: (start: Date, end: Date)? = nil
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var pendingEditTransaction: Transaction? = nil
    @State private var lastInspectedTransaction: Transaction? = nil
    @State private var editingCategoryToEdit: Category? = nil
    @State private var showDatePicker: Bool = false
    @State private var showAddTransaction: Bool = false
    @Namespace private var categorySheetNamespace
    
    // MARK: - Computed Properties
    private var themeColor: Color {
        category.color
    }

    private var sharedMorphNamespace: Namespace.ID {
        topControlsNamespace ?? categorySheetNamespace
    }

    private func pageMorphID(shared: String, fallback: String) -> String {
        topControlsNamespace == nil ? fallback : shared
    }
    
    private var daysInSelectedPeriod: Int {
        if let custom = customDateRange {
            let diff = Calendar.current.dateComponents([.day], from: custom.start, to: custom.end).day ?? 1
            return max(1, diff + 1)
        }
        return AnalyticsChartEngine.daysInPeriod(for: selectedPeriod)
    }
    
    private var allCategoryTransactions: [Transaction] {
        store.transactions.filter {
            $0.categoryId == category.id && $0.type == category.type
        }
    }
    
    private var periodBounds: (start: Date, end: Date) {
        if let custom = customDateRange {
            return custom
        }
        return AnalyticsChartEngine.periodBounds(for: selectedPeriod)
    }
    
    private var filteredTransactions: [Transaction] {
        let bounds = periodBounds
        return allCategoryTransactions.filter {
            $0.date >= bounds.start && $0.date <= bounds.end
        }.sorted { $0.date > $1.date }
    }
    
    private var totalSpent: Double {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private var previousPeriodSpent: Double {
        let bounds = periodBounds
        let duration = bounds.end.timeIntervalSince(bounds.start)
        let prevStart = bounds.start.addingTimeInterval(-duration)
        let prevEnd = bounds.start
        
        return allCategoryTransactions
            .filter { $0.date >= prevStart && $0.date < prevEnd }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var comparisonText: String {
        if previousPeriodSpent == 0 && totalSpent == 0 { return "No data yet" }
        if previousPeriodSpent == 0 { return "No data from last period" }
        let diff = totalSpent - previousPeriodSpent
        let pct = (diff / previousPeriodSpent) * 100
        if pct > 0 {
            return "↑ \(String(format: "%.0f", abs(pct)))% vs last period"
        } else if pct < 0 {
            return "↓ \(String(format: "%.0f", abs(pct)))% vs last period"
        } else {
            return "Same as last period"
        }
    }
    
    private var comparisonColor: Color {
        if previousPeriodSpent == 0 { return SpendyColors.textTertiary }
        let diff = totalSpent - previousPeriodSpent
        if category.type == .expense {
            return diff > 0 ? SpendyColors.expenseRed : SpendyColors.incomeGreen
        } else {
            return diff > 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed
        }
    }
    
    private var chartPoints: [CategoryChartPoint] {
        AnalyticsChartEngine.generateChartPoints(
            transactions: allCategoryTransactions,
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
        case .month:
            formatter.dateFormat = "MMMM"
            return "Spent in \(formatter.string(from: bounds.start))"
        case .threeMonths:
            return "Last 3 Months"
        case .sixMonths:
            return "Last 6 Months"
        case .year:
            formatter.dateFormat = "yyyy"
            return "Spent in \(formatter.string(from: bounds.start))"
        }
    }

    
    // MARK: - Insights Calculations
    private var averageSpentPerWeek: Double {
        guard !filteredTransactions.isEmpty else { return 0 }
        let weeks = max(1, Double(daysInSelectedPeriod) / 7.0)
        return totalSpent / weeks
    }
    
    private var topSpendingWeekday: (name: String, dayIndex: Int, amount: Double) {
        var dayTotals = Array(repeating: 0.0, count: 7)
        let calendar = Calendar.current
        for tx in filteredTransactions {
            let weekday = calendar.component(.weekday, from: tx.date) - 1
            if weekday >= 0 && weekday < 7 {
                dayTotals[weekday] += tx.amount
            }
        }
        var maxIdx = 4
        var maxAmt = 0.0
        for (idx, amt) in dayTotals.enumerated() {
            if amt > maxAmt {
                maxAmt = amt
                maxIdx = idx
            }
        }
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return (dayNames[maxIdx], maxIdx, maxAmt)
    }
    
    private var monthForecast: Double {
        let calendar = Calendar.current
        let now = Date()
        let startMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let range = calendar.range(of: .day, in: .month, for: now) ?? 1..<31
        let totalDays = Double(range.count)
        let dayPassed = max(1.0, Double(calendar.component(.day, from: now)))
        let monthTxs = allCategoryTransactions.filter { $0.date >= startMonth && $0.date <= now }
        let monthSpent = monthTxs.reduce(0) { $0 + $1.amount }
        let dailyRate = monthSpent / dayPassed
        return dailyRate * totalDays
    }
    
    private var highestSingleDay: (Date, Double)? {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredTransactions) { calendar.startOfDay(for: $0.date) }
        var maxDay: (Date, Double)? = nil
        for (day, txs) in groups {
            let total = txs.reduce(0) { $0 + $1.amount }
            if maxDay == nil || total > (maxDay?.1 ?? 0) {
                maxDay = (day, total)
            }
        }
        return maxDay
    }
    
    // Dynamic AI Category Insights Engine
    private var dynamicCategoryInsights: [InsightItem] {
        guard totalSpent > 0 else { return [] }
        var items: [InsightItem] = []
        let currSymbol = store.currencySymbol
        
        // 1. Pace / Trend Insight
        if previousPeriodSpent > 0 {
            let diff = totalSpent - previousPeriodSpent
            let pct = abs((diff / previousPeriodSpent) * 100)
            let isIncrease = diff > 0
            
            if category.type == .expense {
                items.append(InsightItem(
                    id: "cat_trend_\(category.id)",
                    family: "Trend",
                    scope: "Category",
                    personaFit: [],
                    confidence: 0.9,
                    severity: isIncrease ? 0.7 : 0.3,
                    eligibility: true,
                    title: isIncrease ? "Spending Increased" : "Spending Decreased",
                    value: "\(isIncrease ? "+" : "-")\(String(format: "%.0f", pct))%",
                    desc: isIncrease ? "You spent \(diff.formattedCurrency(symbol: currSymbol, decimals: 0)) more on \(category.label) than last period." : "Great job! Spent \(abs(diff).formattedCurrency(symbol: currSymbol, decimals: 0)) less than last period.",
                    icon: isIncrease ? "arrow.up.right" : "arrow.down.right",
                    colorHex: isIncrease ? "#FF3B30" : "#30D158",
                    categoryId: category.id
                ))
            }
        }
        
        // 2. High Day Insight
        if let (highDate, highAmount) = highestSingleDay, highAmount > 0 {
            let df = DateFormatter()
            df.dateFormat = "MMM d"
            items.append(InsightItem(
                id: "cat_peak_\(category.id)",
                family: "Peak",
                scope: "Category",
                personaFit: [],
                confidence: 0.85,
                severity: 0.4,
                eligibility: true,
                title: "Peak Spending Day",
                value: highAmount.formattedCurrency(symbol: currSymbol, decimals: 0),
                desc: "Highest single day was \(df.string(from: highDate)).",
                icon: "bolt.fill",
                colorHex: category.colorHex,
                categoryId: category.id
            ))
        }
        
        // 3. Weekly Velocity Insight
        if averageSpentPerWeek > 0 {
            items.append(InsightItem(
                id: "cat_weekly_\(category.id)",
                family: "Velocity",
                scope: "Category",
                personaFit: [],
                confidence: 0.8,
                severity: 0.3,
                eligibility: true,
                title: "Weekly Pace",
                value: "\(averageSpentPerWeek.formattedCurrency(symbol: currSymbol, decimals: 0))/wk",
                desc: "Average weekly pace in \(category.label) for this period.",
                icon: "calendar.badge.clock",
                colorHex: "#5E5CE6",
                categoryId: category.id
            ))
        }
        
        return items
    }
    
    private var dateGroupedTransactions: [(String, Double, [Transaction])] {

        AnalyticsChartEngine.dateGroupedTransactions(from: filteredTransactions)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()
            
            // Ambient Category Full-Width Header Glow
            SpendyAmbientHeaderBackground(color: themeColor, height: 420, opacity: 0.38)
            
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 64)
                        
                        // 1. Pure Hero Header
                        heroHeaderSection
                            .padding(.horizontal, 20)
                        
                        // 2. Uncarded SwiftCharts Area Graph & Glass Selector
                        chartSection
                            .padding(.horizontal, 16)
                        
                        // 3. Insights Card (when low data) or Dynamic Carousel (when enough data)
                        if allCategoryTransactions.count < 3 || dynamicCategoryInsights.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Insights")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Text("Add more transactions to unlock personalised insights")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(SpendyColors.textSecondary)
                                    .lineSpacing(4)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(SpendyColors.cardBackground)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                                    }
                            }
                            .padding(.horizontal, 16)
                        } else {
                            categoryInsightsCarousel
                        }
                        
                        // 4. Date-Grouped Activity List
                        transactionsSection
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 40)
                    }
                }
                
                // Floating Sticky Header Bar
                headerBar
                    .padding(.top, 16)
                    .zIndex(100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showDatePicker) {
            DateRangePickerSheet(startDate: $customStartDate, endDate: $customEndDate) { start, end in
                customDateRange = (start, end)
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(defaultCategoryId: category.id)
        }
        .sheet(item: $editingCategoryToEdit) { cat in
            AddCategorySheet(categoryToEdit: cat)
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $inspectingTransaction, onDismiss: {
            if let pending = pendingEditTransaction {
                editingTransaction = pending
                pendingEditTransaction = nil
            }
        }) { tx in
            TransactionDetailSheet(transaction: tx) { txToEdit in
                lastInspectedTransaction = tx
                pendingEditTransaction = txToEdit
                inspectingTransaction = nil
            }
        }
        .sheet(item: $editingTransaction, onDismiss: {
            if let last = lastInspectedTransaction {
                let fresh = store.transactions.first(where: { $0.id == last.id }) ?? last
                lastInspectedTransaction = nil
                pendingEditTransaction = fresh
                // In iOS 17+, modifying state that triggers another sheet presentation in onDismiss works
                inspectingTransaction = fresh
            }
        }) { tx in
            AddTransactionView(transactionToEdit: tx)
        }
    }
    
    // MARK: - 1. Floating Sticky Header Bar
    private var headerBar: some View {
        SpendyGlassEffectContainer(spacing: 12) {
            ZStack {
                // Centered Category Name
                Text(category.label)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 60)
                
                HStack {
                    GlassCircleButton(
                        icon: "chevron.left",
                        size: 44,
                        iconSize: 16,
                        iconWeight: .bold,
                        foregroundColor: SpendyColors.textPrimary,
                        accessibilityLabel: "Back",
                        morphID: pageMorphID(shared: backButtonMorphID, fallback: "backButton"),
                        namespace: sharedMorphNamespace
                    ) {
                        HapticsManager.shared.trigger(.selection)
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    }

                    Spacer()

                    // Right-Side Edit Glass Button
                    GlassCircleButton(
                        icon: "pencil",
                        size: 44,
                        iconSize: 16,
                        iconWeight: .bold,
                        foregroundColor: SpendyColors.textPrimary,
                        accessibilityLabel: "Edit Category",
                        morphID: pageMorphID(shared: editButtonMorphID, fallback: "editButton"),
                        namespace: sharedMorphNamespace
                    ) {
                        HapticsManager.shared.trigger(.light)
                        editingCategoryToEdit = category
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 2. Clean Hero Header Section
    private var heroHeaderSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(periodHeaderLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
                
                Text(totalSpent.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                Text(comparisonText == "No data yet" ? "No data from last period" : comparisonText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(comparisonColor)
            }
            
            Spacer(minLength: 16)
            
            SpendyIconBadge(
                sfSymbol: category.sfSymbol,
                color: themeColor,
                size: .hero,
                style: .circle
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 3. SwiftCharts Area Graph & Index Filter Strip
    private var chartSection: some View {
        VStack(spacing: 14) {
            if chartPoints.isEmpty || totalSpent == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.flattrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundStyle(SpendyColors.textTertiary)
                    Text("No transactions in this period")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    // 1. Actual Area Gradient below historical curve
                    ForEach(chartPoints) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeColor.opacity(0.35), themeColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)
                    }
                    
                    // 2. Actual Solid Line Curve
                    ForEach(chartPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(themeColor)
                        .lineStyle(StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                    }
                    
                    // 3. Luminous "Today" Anchor Beacon
                    if let lastActual = chartPoints.last {
                        PointMark(
                            x: .value("Date", lastActual.date),
                            y: .value("Amount", lastActual.amount)
                        )
                        .symbol {
                            ZStack {
                                Circle()
                                    .fill(themeColor.opacity(0.35))
                                    .frame(width: 18, height: 18)
                                Circle()
                                    .fill(themeColor)
                                    .frame(width: 9, height: 9)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
                .chartXScale(domain: periodBounds.start...periodBounds.end)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        if let dateVal = value.as(Date.self) {
                            AxisValueLabel {
                                Text(axisLabelDate(dateVal))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 180)
            }
            
            // Native Liquid Glass Index Selector Pill Strip + Date Picker Button
            SpendyGlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    GlassSegmentedPicker(
                        selection: $selectedPeriod,
                        items: ChartPeriod.allCases,
                        titleFor: { $0.shortLabel },
                        activeTint: customDateRange != nil ? nil : Color.white.opacity(0.22),
                        selectedForegroundColor: Color.white
                    )
                    .onChange(of: selectedPeriod) { _, _ in
                        customDateRange = nil
                    }
                    .glassMorphID(pageMorphID(shared: periodControlMorphID, fallback: "periodCapsule"), in: sharedMorphNamespace)

                    // Calendar Date Picker Button (Highlighted when custom date range is active)
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
            .padding(.top, 4)
        }
    }


    
    // MARK: - Helper Formatters
    private func axisLabelDate(_ date: Date) -> String {
        AnalyticsChartEngine.axisLabel(for: date, period: selectedPeriod)
    }
    
    // MARK: - 4. Category Insights Bento Carousel
    private var categoryInsightsCarousel: some View {
        let bounds = periodBounds
        let catInsights = InsightsEngine.getAnalyticsInsights(
            transactions: store.transactions,
            budget: store.budget,
            categories: store.categories,
            subscriptions: store.subscriptions,
            periodStart: bounds.start,
            periodEnd: bounds.end,
            prevStart: bounds.start,
            prevEnd: bounds.end,
            dataType: category.type,
            currencySymbol: store.currencySymbol
        ).filter { $0.categoryId == category.id }
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(themeColor)
                Text("Smart Insights")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.horizontal, 20)
            
            Text("Specifically generated based on your spendings")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // Engine generated specific insights for this category
                    ForEach(catInsights) { insight in
                        SharedInsightCard(
                            title: insight.title,
                            value: insight.value,
                            subtitle: insight.desc,
                            icon: insight.icon,
                            color: insight.color
                        )
                        .frame(width: 180)
                    }
                    
                    // Card 1: Avg Spent
                    avgSpentCard
                    
                    // Card 2: Top Day
                    topDayCard
                    
                    // Card 3: Month Forecast
                    monthForecastCard
                    
                    // Card 4: Activity / Transactions Count
                    activityCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }
    
    // Bento Card 1: Avg Spent (with 14 progress pills)
    private var avgSpentCard: some View {
        SharedInsightCard(
            title: "Avg Spent",
            value: averageSpentPerWeek.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
            subtitle: "Average spend per week",
            icon: "chart.bar.fill",
            color: themeColor
        ) {
            HStack(spacing: 3) {
                let ratio = (totalSpent / max(1.0, averageSpentPerWeek * 4)) * 14
                let filledCount = min(14, max(1, ratio.safeInt))
                ForEach(0..<14, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(idx < filledCount ? themeColor : Color.white.opacity(0.12))
                        .frame(height: 5)
                }
            }
        }
        .frame(width: 180)
    }
    
    // Bento Card 2: Top Day (with 7 S M T W T F S weekday bars)
    private var topDayCard: some View {
        let topDayInfo = topSpendingWeekday
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        
        return SharedInsightCard(
            title: "Top Day",
            value: topDayInfo.name,
            subtitle: "Highest spending day",
            icon: "calendar",
            color: themeColor
        ) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<7, id: \.self) { idx in
                    let isTop = idx == topDayInfo.dayIndex
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isTop ? themeColor : Color.white.opacity(0.18))
                            .frame(height: isTop ? 18 : 8)
                        
                        Text(days[idx])
                            .font(.system(size: 8, weight: isTop ? .bold : .medium))
                            .foregroundStyle(isTop ? themeColor : SpendyColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: 180)
    }
    
    // Bento Card 3: Month Forecast
    private var monthForecastCard: some View {
        SharedInsightCard(
            title: "Month Forecast",
            value: monthForecast.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
            subtitle: "Projected spent by month-end",
            icon: "sparkles",
            color: themeColor
        )
        .frame(width: 180)
    }
    
    // Bento Card 4: Activity / Transactions Count
    private var activityCard: some View {
        SharedInsightCard(
            title: "Activity",
            value: "\(filteredTransactions.count)",
            subtitle: "\(filteredTransactions.count == 1 ? "transaction" : "transactions") in this period",
            icon: "square.stack.3d.up.fill",
            color: themeColor
        )
        .frame(width: 180)
    }
    
    // MARK: - 5. Date-Grouped Recent Activity Transactions Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(SpendyColors.textTertiary)
                .tracking(1.2)
                .padding(.leading, 4)
            
            if dateGroupedTransactions.isEmpty {
                VStack(spacing: 8) {
                    Text("No transactions found")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 20) {
                    ForEach(dateGroupedTransactions, id: \.0) { dateGroup, dayTotal, txs in
                        VStack(alignment: .leading, spacing: 8) {
                            // Date Group Header
                            HStack {
                                Text(dateGroup)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(SpendyColors.textTertiary)
                                Spacer()
                                Text(dayTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            
                            // Card Container
                            VStack(spacing: 0) {
                                ForEach(Array(txs.enumerated()), id: \.element.id) { index, tx in
                                    categoryTransactionRow(tx)
                                        .onTapGesture {
                                            HapticsManager.shared.trigger(.selection)
                                            inspectingTransaction = tx
                                        }
                                    
                                    if index < txs.count - 1 {
                                        Divider()
                                            .background(Color.white.opacity(0.06))
                                            .padding(.leading, 64)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(hex: "#141416"))
                                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Individual Transaction Row with Category Icon & Bank Badge
    private func categoryTransactionRow(_ tx: Transaction) -> some View {
        let account = store.accounts.first(where: { $0.id == tx.accountId })
        
        return HStack(spacing: 14) {
            // Category Icon Badge
            SpendyIconBadge(
                sfSymbol: category.sfSymbol,
                color: category.color,
                size: .small,
                style: .circle
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tx.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // Bank Account Badge
                    if let acc = account {
                        HStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(acc.color)
                                    .frame(width: 14, height: 14)
                                Image(systemName: acc.sfSymbol)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            Text(acc.label)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(SpendyColors.textSecondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
                        )
                    }
                    
                    Text(tx.date.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            
            Spacer()
            
            // Amount
            Text(tx.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                .spendyNumberFont(size: 15, weight: .heavy, tracking: -0.4)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
