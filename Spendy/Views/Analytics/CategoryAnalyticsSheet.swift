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

// MARK: - Chart Period Enum
enum ChartPeriod: String, CaseIterable, Identifiable {
    case week = "1w"
    case month = "1m"
    case threeMonths = "3m"
    case sixMonths = "6m"
    case year = "1y"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .week: return "1 Week"
        case .month: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "1 Year"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .week: return "1w"
        case .month: return "1m"
        case .threeMonths: return "3m"
        case .sixMonths: return "6m"
        case .year: return "1y"
        }
    }
}

// MARK: - Chart Data Point
struct CategoryChartPoint: Identifiable, Equatable {
    let id: String
    let date: Date
    let label: String
    let amount: Double
    let isPredicted: Bool
    
    init(id: String = UUID().uuidString, date: Date, label: String, amount: Double, isPredicted: Bool = false) {
        self.id = id
        self.date = date
        self.label = label
        self.amount = amount
        self.isPredicted = isPredicted
    }
}

// MARK: - Category Analytics Sheet
struct CategoryAnalyticsSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let category: Category
    var initialType: TransactionType = .expense
    var topControlsNamespace: Namespace.ID? = nil
    var onDismiss: (() -> Void)? = nil
    
    @State private var selectedPeriod: ChartPeriod = .month
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var lastInspectedTransaction: Transaction? = nil
    @State private var editingCategoryToEdit: Category? = nil
    @State private var showDatePicker: Bool = false
    
    // MARK: - Computed Properties
    private var themeColor: Color {
        category.color
    }
    
    private var daysInSelectedPeriod: Int {
        let bounds = periodBounds
        let calendar = Calendar.current
        return max(1, calendar.dateComponents([.day], from: bounds.start, to: bounds.end).day ?? 1)
    }
    
    private var allCategoryTransactions: [Transaction] {
        store.transactions.filter {
            $0.categoryId == category.id && $0.type == category.type
        }
    }
    
    private var periodBounds: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
            return (start, now)
        case .month:
            return (now.startOfMonth, now.endOfMonth)
        case .threeMonths:
            let start = calendar.date(byAdding: .month, value: -2, to: calendar.startOfDay(for: now)) ?? now
            return (start, now.endOfDay)
        case .sixMonths:
            let start = calendar.date(byAdding: .month, value: -5, to: calendar.startOfDay(for: now)) ?? now
            return (start, now.endOfDay)
        case .year:
            return (now.startOfYear, now.endOfYear)
        }
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
    
    private var predictiveChartPoints: [CategoryChartPoint] {
        let actuals = chartPoints.filter { !$0.isPredicted }
        guard let lastActual = actuals.last else { return [] }
        let preds = chartPoints.filter { $0.isPredicted }
        guard !preds.isEmpty else { return [] }
        // Prepend last actual to make a continuous dashed line from today onward
        return [lastActual] + preds
    }
    
    private var chartPoints: [CategoryChartPoint] {
        let calendar = Calendar.current
        let bounds = periodBounds
        let txs = filteredTransactions
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let hasEnoughTxs = allCategoryTransactions.count >= 5
        
        switch selectedPeriod {
        case .week, .month:
            var points: [CategoryChartPoint] = []
            var current = calendar.startOfDay(for: bounds.start)
            let endDay = calendar.startOfDay(for: bounds.end)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = selectedPeriod == .week ? "EEE" : "d"
            
            let daysElapsed = max(1, calendar.dateComponents([.day], from: bounds.start, to: min(today, bounds.end)).day ?? 1)
            let totalSpentSoFar = txs.filter { $0.date >= bounds.start && $0.date <= min(now, bounds.end) }.reduce(0) { $0 + $1.amount }
            let dailyRate = daysElapsed > 0 ? (totalSpentSoFar / Double(daysElapsed)) : 0
            
            var cumulativeSpend: Double = 0
            
            while current <= endDay {
                let isActual = current <= today
                
                if isActual {
                    let dayStart = current
                    let dayEnd = calendar.date(byAdding: .day, value: 1, to: current)!
                    let daySpent = txs
                        .filter { $0.date >= dayStart && $0.date < dayEnd }
                        .reduce(0) { $0 + $1.amount }
                    
                    cumulativeSpend += daySpent
                    points.append(CategoryChartPoint(
                        id: "actual_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: cumulativeSpend,
                        isPredicted: false
                    ))
                } else if hasEnoughTxs {
                    let dayOffset = max(1, calendar.dateComponents([.day], from: today, to: current).day ?? 1)
                    let predictedAmount = cumulativeSpend + (dailyRate * Double(dayOffset))
                    points.append(CategoryChartPoint(
                        id: "pred_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: predictedAmount,
                        isPredicted: true
                    ))
                }
                current = calendar.date(byAdding: .day, value: 1, to: current)!
            }
            return points
            
        case .threeMonths, .sixMonths, .year:
            var points: [CategoryChartPoint] = []
            var current = calendar.date(from: calendar.dateComponents([.year, .month], from: bounds.start))!
            let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: bounds.end))!
            
            let monthsElapsed = max(1, calendar.dateComponents([.month], from: bounds.start, to: min(now, bounds.end)).month ?? 1)
            let totalSpentSoFar = txs.filter { $0.date >= bounds.start && $0.date <= min(now, bounds.end) }.reduce(0) { $0 + $1.amount }
            let monthlyRate = monthsElapsed > 0 ? (totalSpentSoFar / Double(monthsElapsed)) : 0
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            
            var cumulativeSpend: Double = 0
            
            while current <= endMonth {
                let monthStart = current
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: current)!
                let isActual = current <= now
                
                if isActual {
                    let monthSpent = txs
                        .filter { $0.date >= monthStart && $0.date < monthEnd }
                        .reduce(0) { $0 + $1.amount }
                    cumulativeSpend += monthSpent
                    points.append(CategoryChartPoint(
                        id: "actual_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: cumulativeSpend,
                        isPredicted: false
                    ))
                } else if hasEnoughTxs {
                    let monthOffset = max(1, calendar.dateComponents([.month], from: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!, to: current).month ?? 1)
                    let predictedAmount = cumulativeSpend + (monthlyRate * Double(monthOffset))
                    points.append(CategoryChartPoint(
                        id: "pred_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: predictedAmount,
                        isPredicted: true
                    ))
                }
                current = monthEnd
            }
            return points
        }
    }
    
    private var periodHeaderLabel: String {
        let formatter = DateFormatter()
        let bounds = periodBounds
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
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredTransactions) { tx -> Date in
            calendar.startOfDay(for: tx.date)
        }
        
        let dateFormatter = DateFormatter()
        
        return groups.keys.sorted(by: >).map { day -> (String, Double, [Transaction]) in
            let dayTxs = groups[day]!.sorted { $0.date > $1.date }
            let dayTotal = dayTxs.reduce(0) { $0 + $1.amount }
            
            let label: String
            if calendar.isDateInToday(day) {
                label = "Today"
            } else if calendar.isDateInYesterday(day) {
                label = "Yesterday"
            } else {
                dateFormatter.dateFormat = "d MMM yyyy"
                label = dateFormatter.string(from: day)
            }
            return (label, dayTotal, dayTxs)
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()
            
            // Ambient Category Radial Color Glow
            VStack {
                RadialGradient(
                    colors: [
                        themeColor.opacity(0.35),
                        themeColor.opacity(0.12),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 380
                )
                .frame(height: 380)
                .blur(radius: 20)
                .ignoresSafeArea()
                Spacer()
            }
            
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 56)
                        
                        // 1. Pure Hero Header
                        heroHeaderSection
                            .padding(.horizontal, 20)
                        
                        // 2. Uncarded SwiftCharts Area Graph & Glass Selector
                        chartSection
                            .padding(.horizontal, 16)
                        
                        // 3. Dynamic Insights Carousel
                        if !dynamicCategoryInsights.isEmpty {
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
                    .padding(.top, 8)
                    .zIndex(100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $editingCategoryToEdit) { cat in
            AddCategorySheet(categoryToEdit: cat)
                .presentationBackground(SpendyColors.appBackground)
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
    }
    
    // MARK: - 1. Floating Sticky Header Bar
    private var headerBar: some View {
        SpendyGlassEffectContainer(spacing: 12) {
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: .white,
                accessibilityLabel: "Back"
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
                foregroundColor: .white,
                accessibilityLabel: "Edit Category"
            ) {
                HapticsManager.shared.trigger(.light)
                editingCategoryToEdit = category
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
                    .font(.system(size: 38, weight: .heavy, design: .rounded).monospacedDigit())
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
                    ForEach(chartPoints.filter { !$0.isPredicted }) { point in
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
                    ForEach(chartPoints.filter { !$0.isPredicted }) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(themeColor)
                        .lineStyle(StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                    }
                    
                    // 3. Predictive Continuous Dashed Forecast Curve & Glow Area
                    if !predictiveChartPoints.isEmpty {
                        ForEach(predictiveChartPoints) { point in
                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Amount", point.amount)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [themeColor.opacity(0.18), themeColor.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.monotone)
                            
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Amount", point.amount)
                            )
                            .foregroundStyle(themeColor.opacity(0.85))
                            .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round, dash: [6, 4]))
                            .interpolationMethod(.monotone)
                        }
                    }
                    
                    // 4. Luminous "Today" Anchor Beacon
                    if let lastActual = chartPoints.filter({ !$0.isPredicted }).last {
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
                
                // Clean Legend Row
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(themeColor)
                            .frame(width: 14, height: 2.5)
                        Text("Actual")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                    
                    if !predictiveChartPoints.isEmpty {
                        HStack(spacing: 6) {
                            HStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(themeColor.opacity(0.8))
                                    .frame(width: 3, height: 2.5)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(themeColor.opacity(0.8))
                                    .frame(width: 3, height: 2.5)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(themeColor.opacity(0.8))
                                    .frame(width: 3, height: 2.5)
                            }
                            Text("Predicted")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Native Liquid Glass Index Selector Pill Strip + Date Picker Button
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(ChartPeriod.allCases) { period in
                        let isSelected = selectedPeriod == period
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                                selectedPeriod = period
                            }
                            HapticsManager.shared.trigger(.selection)
                        } label: {
                            Text(period.shortLabel)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Color.white : SpendyColors.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background {
                                    if isSelected {
                                        Capsule()
                                            .fill(Color.white.opacity(0.20))
                                    }
                                }
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .nativeLiquidGlassCapsule(isInteractive: true)
                
                // Calendar Date Picker Button
                Button {
                    HapticsManager.shared.trigger(.selection)
                    showDatePicker = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(Color(hex: "#1C1C1E").opacity(0.75))
                                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Helper Formatters
    private func axisLabelDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        switch selectedPeriod {
        case .week: fmt.dateFormat = "EEE"
        case .month: fmt.dateFormat = "d"
        case .threeMonths, .sixMonths: fmt.dateFormat = "MMM"
        case .year: fmt.dateFormat = "MMM"
        }
        return fmt.string(from: date)
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
                                    .fill(Color(hex: "#0A0A0C"))
                                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
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
                .font(.system(size: 15, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
