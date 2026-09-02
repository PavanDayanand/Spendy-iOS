//
//  CategoryAnalyticsSheet.swift
//  Spendy
//
//  Apple HIG Category Analytics Sheet
//  Features:
//  - Minimal, Direct Fintech IA: Focus on Category Spending Velocity & Budget Adherence
//  - Centered Category Icon Avatar (Clean, no glow) & Hero Total Spent
//  - SwiftCharts Area Graph & Period Selector on Content Layer
//  - Direct 2-Row Category Performance & Pace Bento Hub
//  - Pure Title Case Typography throughout (no ALL CAPS)
//  - Date-Grouped Transaction Activity List
//

import SwiftUI
import Charts

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
    @State private var editingCategoryToEdit: Category? = nil
    @State private var showDatePicker: Bool = false
    @State private var showAddTransaction: Bool = false
    @Namespace private var categorySheetNamespace
    
    // MARK: - Computed Properties
    private var themeColor: Color {
        category.color
    }

    private var chartThemeColor: Color {
        SpendyColors.isMonoMode ? SpendyColors.monoGraphLine : category.color
    }

    private var isHomeOrigin: Bool {
        topControlsNamespace != nil && periodControlMorphID == "accountDropdownCapsule"
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
    
    private var comparisonPercentage: Double? {
        guard previousPeriodSpent > 0 else { return nil }
        let diff = totalSpent - previousPeriodSpent
        return (diff / previousPeriodSpent) * 100
    }
    
    private var dailyAverageSpent: Double {
        totalSpent / Double(max(1, daysInSelectedPeriod))
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
    
    private var categoryBudgetAmount: Double? {
        if let budgetVal = store.budget.categoryBudgets[category.id], budgetVal > 0 {
            return budgetVal
        }
        return nil
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
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: bounds.start)
        case .threeMonths:
            return "Last 3 Months"
        case .sixMonths:
            return "Last 6 Months"
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: bounds.start)
        }
    }
    
    private var dateGroupedTransactions: [(String, Double, [Transaction])] {
        AnalyticsChartEngine.dateGroupedTransactions(from: filteredTransactions)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()
            
            // Ambient Category Glow
            SpendyAmbientHeaderBackground(color: themeColor, height: 380, opacity: 0.32)
            
            VStack(spacing: 0) {
                if isHomeOrigin {
                    topHeaderBar
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Centralized Category Avatar (No Glow) & Hero Total Spent
                        centralizedHeroHeader
                            .padding(.horizontal, 16)
                            .padding(.top, isHomeOrigin ? 2 : 6)
                        
                        // 2. SwiftCharts Area Graph on Content Layer
                        chartSection
                            .padding(.horizontal, 16)
                        
                        // 3. Direct Category Spending & Pace Bento Hub
                        if !filteredTransactions.isEmpty {
                            categoryBentoHub
                                .padding(.horizontal, 16)
                            
                            categoryInsightsCarousel
                                .padding(.top, 2)
                        }
                        
                        // 4. Date-Grouped Category Activity List
                        transactionsSection
                            .padding(.horizontal, 16)
                            .padding(.top, 2)
                            .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle(isHomeOrigin ? "" : category.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(isHomeOrigin ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            if !isHomeOrigin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.shared.trigger(.light)
                        editingCategoryToEdit = category
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                    .accessibilityLabel("Edit Category")
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DateRangePickerSheet(startDate: $customStartDate, endDate: $customEndDate) { start, end in
                customDateRange = (start, end)
            }
        }
        .fullScreenCover(isPresented: $showAddTransaction) {
            AddTransactionView(defaultCategoryId: category.id)
        }
        .sheet(item: $editingCategoryToEdit) { cat in
            AddCategorySheet(categoryToEdit: cat)
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
    
    // MARK: - 1. Top Header Bar (When Pushed from Home with Liquid Glass Morph)
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
            
            Text(category.label)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            GlassCircleButton(
                icon: "pencil",
                size: 44,
                iconSize: 15,
                iconWeight: .semibold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .light,
                accessibilityLabel: "Edit Category",
                morphID: pageMorphID(shared: editButtonMorphID, fallback: "editButton"),
                namespace: sharedMorphNamespace
            ) {
                HapticsManager.shared.trigger(.light)
                editingCategoryToEdit = category
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
    
    // MARK: - 2. Centralized Category Avatar (No Glow) & Hero Total Spent
    private var centralizedHeroHeader: some View {
        VStack(spacing: 6) {
            // Clean Category Icon Badge (Zero shadow glow)
            SpendyIconBadge(
                sfSymbol: category.sfSymbol,
                color: themeColor,
                size: .large,
                style: .circle
            )
            
            // Hero Total Spent Amount
            Text(totalSpent.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                .foregroundStyle(SpendyColors.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            // Period / Context Subtitle or Trend Pill
            if let pct = comparisonPercentage {
                let isIncrease = pct > 0
                HStack(spacing: 4) {
                    Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("\(String(format: "%.0f", abs(pct)))% vs last period")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(isIncrease ? SpendyColors.expenseRed : SpendyColors.incomeGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background {
                    Capsule(style: .continuous)
                        .fill((isIncrease ? SpendyColors.expenseRed : SpendyColors.incomeGreen).opacity(0.12))
                }
            } else {
                Text("Spent in \(periodHeaderLabel)")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
    
    // MARK: - 3. SwiftCharts Area Graph & Period Selector
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
                    // 1. Area Gradient below curve
                    ForEach(chartPoints) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [chartThemeColor.opacity(0.35), chartThemeColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)
                    }
                    
                    // 2. Solid Line Curve
                    ForEach(chartPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(chartThemeColor)
                        .lineStyle(StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                    }
                    
                    // 3. Anchor Beacon
                    if let lastActual = chartPoints.last {
                        PointMark(
                            x: .value("Date", lastActual.date),
                            y: .value("Amount", lastActual.amount)
                        )
                        .symbol {
                            ZStack {
                                Circle()
                                    .fill(chartThemeColor.opacity(0.35))
                                    .frame(width: 18, height: 18)
                                Circle()
                                    .fill(chartThemeColor)
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
                        titleFor: { $0.shortLabel }
                    )
                    .onChange(of: selectedPeriod) { _, _ in
                        customDateRange = nil
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
            .padding(.top, 4)
        }
    }

    private func axisLabelDate(_ date: Date) -> String {
        AnalyticsChartEngine.axisLabel(for: date, period: selectedPeriod)
    }

    // MARK: - 4. Direct Category Spending & Pace Bento Hub
    private var categoryBentoHub: some View {
        VStack(spacing: 14) {
            // Row 1: Total Spent & Budget Remaining (or Previous Period)
            HStack(spacing: 12) {
                totalSpentCell
                
                Divider()
                    .overlay(SpendyColors.separator)
                    .frame(height: 36)
                
                if let budget = categoryBudgetAmount {
                    budgetMetricCell(budget: budget)
                } else {
                    lastPeriodMetricCell
                }
            }
            
            Divider()
                .overlay(SpendyColors.separator)
            
            // Row 2: Daily Pace & Peak Day
            HStack(spacing: 12) {
                dailyPaceCell
                
                Divider()
                    .overlay(SpendyColors.separator)
                    .frame(height: 32)
                
                peakDayCell
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                }
        }
    }

    private var totalSpentCell: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.16))
                    .frame(width: 34, height: 34)
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(themeColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Spent")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                Text(totalSpent.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .spendyNumberFont(size: 17, weight: .bold, tracking: -0.4)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func budgetMetricCell(budget: Double) -> some View {
        let remaining = max(0.0, budget - totalSpent)
        let isOver = totalSpent > budget
        let statusColor = isOver ? SpendyColors.expenseRed : SpendyColors.incomeGreen
        
        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.16))
                    .frame(width: 34, height: 34)
                Image(systemName: isOver ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isOver ? "Over Budget" : "Budget Left")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                Text(remaining.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .spendyNumberFont(size: 17, weight: .bold, tracking: -0.4)
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lastPeriodMetricCell: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(SpendyColors.cardBackgroundSecondary)
                    .frame(width: 34, height: 34)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Last Period")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                Text(previousPeriodSpent.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .spendyNumberFont(size: 17, weight: .bold, tracking: -0.4)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dailyPaceCell: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.16))
                    .frame(width: 32, height: 32)
                Image(systemName: "speedometer")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(themeColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Pace")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                Text("\(dailyAverageSpent.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var peakDayCell: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#FF9F0A").opacity(0.16))
                    .frame(width: 32, height: 32)
                Image(systemName: "flame.fill")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color(hex: "#FF9F0A"))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Peak Day")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                if let peak = highestSingleDay {
                    let df = DateFormatter()
                    let _ = df.dateFormat = "d MMM"
                    Text("\(peak.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) (\(df.string(from: peak.date)))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                } else {
                    Text("—")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 4.5. Analytics Smart Insights Carousel (4 Bento Cards)
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

    private var categoryInsightsCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Smart Insights")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // Card 1: Avg Spent (Gradient Trend Card)
                    avgSpentCard
                    
                    // Card 2: Top Day (Spotlight Bar Card)
                    topDayCard
                    
                    // Card 3: Month Forecast (Pacing Pin Bar Card)
                    monthForecastCard
                    
                    // Card 4: Activity / Transactions Count (Dot Matrix Card)
                    activityCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }
    
    // Bento Card 1: Avg Spent (Gradient Trend Card)
    private var avgSpentCard: some View {
        GradientTrendCard(
            title: "Avg spent",
            value: averageSpentPerWeek.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
            subtitle: "Per week",
            lineColor: themeColor
        )
        .frame(width: 180)
    }
    
    // Bento Card 2: Top Day (Spotlight Bar Card)
    private var topDayCard: some View {
        let topDayInfo = topSpendingWeekday
        return SpotlightBarCard(
            title: "Top day",
            peakDayName: topDayInfo.name,
            peakDayIndex: topDayInfo.dayIndex,
            accentColor: themeColor
        )
        .frame(width: 180)
    }
    
    // Bento Card 3: Month Forecast (Pacing Pin Bar Card)
    private var monthForecastCard: some View {
        let ratio = min(1.0, max(0.1, totalSpent / max(1.0, monthForecast)))
        return PacingPinBarCard(
            title: "Month Forecast",
            value: monthForecast.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
            deltaText: "\(store.currencySymbol)\(Int(monthForecast))",
            subtitle: "Projected spent by month-end",
            progress: ratio,
            icon: "sparkles",
            color: themeColor
        )
        .frame(width: 180)
    }
    
    // Bento Card 4: Activity (Dot Matrix Habit Card)
    private var activityCard: some View {
        DotMatrixCard(
            title: "Activity",
            streakCount: filteredTransactions.count,
            streakUnit: filteredTransactions.count == 1 ? "expense in period" : "expenses in period",
            icon: "square.stack.3d.up.fill",
            color: themeColor,
            totalDays: 30,
            activeDays: min(30, filteredTransactions.count)
        )
        .frame(width: 180)
    }
    
    // MARK: - 5. Date-Grouped Recent Activity Section (Title Case)
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.leading, 4)
            
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
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 16) {
                    ForEach(dateGroupedTransactions, id: \.0) { dateGroup, dayTotal, txs in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(dateGroup)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(SpendyColors.textSecondary)
                                
                                Spacer()
                                
                                Text(dayTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                    .spendyNumberFont(size: 12, weight: .bold, tracking: -0.3)
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                ForEach(Array(txs.enumerated()), id: \.element.id) { idx, tx in
                                    let subscription = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == tx.subscriptionId?.lowercased() })
                                    let iconSymbol = subscription?.sfSymbol ?? category.sfSymbol
                                    let iconColor = subscription?.color ?? category.color
                                    let acc = store.accounts.first(where: { $0.id == tx.accountId })
                                    
                                    Button(action: {
                                        HapticsManager.shared.trigger(.selection)
                                        inspectingTransaction = tx
                                    }) {
                                        HStack(spacing: 12) {
                                            SpendyIconBadge(
                                                sfSymbol: iconSymbol,
                                                color: iconColor,
                                                size: .medium,
                                                style: .circle
                                            )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(tx.title)
                                                    .font(.system(size: 14.5, weight: .semibold))
                                                    .foregroundStyle(SpendyColors.textPrimary)
                                                    .lineLimit(1)
                                                
                                                Text(acc?.label ?? "General")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundStyle(SpendyColors.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text("\(tx.type == .income ? "+" : "-")\(tx.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                                                .spendyNumberFont(size: 15, weight: .bold, tracking: -0.3)
                                                .foregroundStyle(tx.type == .income ? SpendyColors.incomeGreen : SpendyColors.textPrimary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(SpendyColors.cardBackground)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if idx < txs.count - 1 {
                                        Divider()
                                            .overlay(SpendyColors.separator)
                                            .padding(.leading, 64)
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                }
            }
        }
    }
}
