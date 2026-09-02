//
//  AccountAnalyticsSheet.swift
//  Spendy
//
//  Apple HIG Bank Account Analytics Sheet
//  Features:
//  - Minimal, Direct Fintech IA: Focus on Account Liquidity & Net Cash Flow Solvency
//  - Centered Bank Icon Avatar (Clean, no glow) & Hero Balance
//  - SwiftCharts Area Graph & Period Selector on Content Layer
//  - Direct 2-Row Cash Flow & Solvency Bento Hub
//  - Pure Title Case Typography throughout (no ALL CAPS)
//  - Date-Grouped Transaction Activity List
//

import SwiftUI
import Charts

struct AccountAnalyticsSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let account: Account
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
    @State private var editingAccountToEdit: Account? = nil
    @State private var showDatePicker: Bool = false
    @State private var showAddTransaction: Bool = false
    @Namespace private var accountSheetNamespace
    
    // MARK: - Computed Properties
    private var themeColor: Color {
        account.color
    }

    private var chartThemeColor: Color {
        SpendyColors.isMonoMode ? SpendyColors.monoGraphLine : account.color
    }

    private var isHomeOrigin: Bool {
        topControlsNamespace != nil && periodControlMorphID == "accountDropdownCapsule"
    }

    private var sharedMorphNamespace: Namespace.ID {
        topControlsNamespace ?? accountSheetNamespace
    }

    private func pageMorphID(shared: String, fallback: String) -> String {
        topControlsNamespace == nil ? fallback : shared
    }
    
    private var allAccountTransactions: [Transaction] {
        store.transactions.filter { $0.accountId == account.id }
            .sorted { $0.date > $1.date }
    }
    
    private var periodBounds: (start: Date, end: Date) {
        if let custom = customDateRange {
            return custom
        }
        return AnalyticsChartEngine.periodBounds(for: selectedPeriod)
    }
    
    private var filteredTransactions: [Transaction] {
        let bounds = periodBounds
        return allAccountTransactions.filter {
            $0.date >= bounds.start && $0.date <= bounds.end
        }
    }
    
    private var currentBalance: Double {
        store.balance(for: account.id)
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
    
    private var daysInSelectedPeriod: Int {
        if let custom = customDateRange {
            let diff = Calendar.current.dateComponents([.day], from: custom.start, to: custom.end).day ?? 1
            return max(1, diff + 1)
        }
        return AnalyticsChartEngine.daysInPeriod(for: selectedPeriod)
    }
    
    private var chartPoints: [CategoryChartPoint] {
        AnalyticsChartEngine.generateChartPoints(
            transactions: allAccountTransactions,
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
            
            // Ambient Header Glow
            SpendyAmbientHeaderBackground(color: themeColor, height: 380, opacity: 0.32)
            
            VStack(spacing: 0) {
                if isHomeOrigin {
                    topHeaderBar
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Centralized Clean Bank Avatar (No Glow) & Hero Balance
                        centralizedHeroHeader
                            .padding(.horizontal, 16)
                            .padding(.top, isHomeOrigin ? 2 : 6)
                        
                        // 2. SwiftCharts Area Graph on Content Layer
                        chartSection
                            .padding(.horizontal, 16)
                        
                        // 3. Direct Solvency & Cash Flow Bento Hub
                        if !allAccountTransactions.isEmpty {
                            cashFlowBentoHub
                                .padding(.horizontal, 16)
                            
                            accountInsightsCarousel
                                .padding(.top, 2)
                        }
                        
                        // 4. Date-Grouped Account Activity List
                        transactionsSection
                            .padding(.horizontal, 16)
                            .padding(.top, 2)
                            .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle(isHomeOrigin ? "" : account.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(isHomeOrigin ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            if !isHomeOrigin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.shared.trigger(.light)
                        editingAccountToEdit = account
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                    .accessibilityLabel("Edit Account")
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DateRangePickerSheet(startDate: $customStartDate, endDate: $customEndDate) { start, end in
                customDateRange = (start, end)
            }
        }
        .fullScreenCover(isPresented: $showAddTransaction) {
            AddTransactionView(defaultAccountId: account.id)
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
            
            Text(account.label)
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
                accessibilityLabel: "Edit Account",
                morphID: pageMorphID(shared: editButtonMorphID, fallback: "editButton"),
                namespace: sharedMorphNamespace
            ) {
                HapticsManager.shared.trigger(.light)
                editingAccountToEdit = account
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
    
    // MARK: - 2. Centralized Bank Avatar (No Glow) & Hero Balance Header
    private var centralizedHeroHeader: some View {
        VStack(spacing: 6) {
            // Clean Bank / Account Icon Badge (Zero shadow glow as requested)
            SpendyIconBadge(
                sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                color: themeColor,
                size: .large,
                style: .circle
            )
            
            // Hero Balance Amount
            Text(currentBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                .foregroundStyle(SpendyColors.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            // Period Context Subtitle
            Text("Balance in \(periodHeaderLabel)")
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(SpendyColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
    
    // MARK: - 3. SwiftCharts Area Graph & Period Selector
    private var chartSection: some View {
        VStack(spacing: 14) {
            if chartPoints.isEmpty || totalOutflow == 0 {
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

    // MARK: - 4. Direct Solvency & Cash Flow Bento Hub
    private var cashFlowBentoHub: some View {
        VStack(spacing: 14) {
            // Row 1: Money In & Money Out Dual Split
            HStack(spacing: 12) {
                // Money In
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(SpendyColors.incomeGreen.opacity(0.16))
                            .frame(width: 34, height: 34)
                        Image(systemName: "arrow.down.left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.incomeGreen)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Money In")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        Text("+\(totalInflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                            .spendyNumberFont(size: 17, weight: .bold, tracking: -0.4)
                            .foregroundStyle(SpendyColors.incomeGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .overlay(SpendyColors.separator)
                    .frame(height: 36)
                
                // Money Out
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(SpendyColors.expenseRed.opacity(0.16))
                            .frame(width: 34, height: 34)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.expenseRed)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Money Out")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        Text("-\(totalOutflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                            .spendyNumberFont(size: 17, weight: .bold, tracking: -0.4)
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
                .overlay(SpendyColors.separator)
            
            // Row 2: Net Cash Flow (Solvency KPI) & Activity Count
            HStack(spacing: 12) {
                // Net Cash Flow
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill((netCashFlow >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed).opacity(0.16))
                            .frame(width: 32, height: 32)
                        Image(systemName: netCashFlow >= 0 ? "plus.circle.fill" : "minus.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(netCashFlow >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Net Cash Flow")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        Text("\(netCashFlow >= 0 ? "+" : "-")\(abs(netCashFlow).formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(netCashFlow >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .overlay(SpendyColors.separator)
                    .frame(height: 32)
                
                // Transactions Count
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#AF52DE").opacity(0.16))
                            .frame(width: 32, height: 32)
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "#AF52DE"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activity")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        Text("\(filteredTransactions.count) \(filteredTransactions.count == 1 ? "entry" : "entries")")
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
    
    // MARK: - 4.5. Analytics Smart Insights Carousel (Bar Charts, Dot Matrix, Peak Day, Trend)
    private var dailyAverageSpent: Double {
        totalOutflow / Double(max(1, daysInSelectedPeriod))
    }

    private var topSpendingWeekday: (name: String, dayIndex: Int) {
        let calendar = Calendar.current
        var weekdayTotals: [Int: Double] = [:]
        for tx in filteredTransactions where tx.type == .expense {
            let wd = calendar.component(.weekday, from: tx.date) - 1 // 0 = Sun .. 6 = Sat
            weekdayTotals[wd, default: 0] += tx.amount
        }
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        if let maxEntry = weekdayTotals.max(by: { $0.value < $1.value }) {
            let idx = max(0, min(6, maxEntry.key))
            return (dayNames[idx], idx)
        }
        return ("Sunday", 0)
    }

    private var activeDaysCount: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(filteredTransactions.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    private var past7DaysValues: [Double] {
        let calendar = Calendar.current
        let now = Date()
        var values: [Double] = []
        for i in (0..<7).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: -i, to: now) else {
                values.append(0.0)
                continue
            }
            let dayStart = calendar.startOfDay(for: targetDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let dayTotal = filteredTransactions
                .filter { $0.type == .expense && $0.date >= dayStart && $0.date < dayEnd }
                .reduce(0) { $0 + $1.amount }
            values.append(dayTotal)
        }
        return values
    }

    private var accountInsightsCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Smart Insights")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 1. Peak Activity Weekday Spotlight Card
                    SpotlightBarCard(
                        title: "Peak Day",
                        peakDayName: topSpendingWeekday.name,
                        peakDayIndex: topSpendingWeekday.dayIndex,
                        accentColor: themeColor
                    )
                    .frame(width: 170)
                    
                    // 2. 3x10 Activity Dot Matrix
                    DotMatrixCard(
                        title: "Activity",
                        streakCount: activeDaysCount,
                        streakUnit: "\(activeDaysCount) active \(activeDaysCount == 1 ? "day" : "days")",
                        icon: "flame.fill",
                        color: themeColor,
                        totalDays: daysInSelectedPeriod,
                        activeDays: activeDaysCount
                    )
                    .frame(width: 170)
                    
                    // 3. 7-Day Outflow Bar Chart
                    WeeklyBarChartCard(
                        title: "7-Day Outflow",
                        value: past7DaysValues.reduce(0, +).formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                        subtitle: "7-day total spending",
                        dailyValues: past7DaysValues,
                        averageBaseline: dailyAverageSpent,
                        color: themeColor
                    )
                    .frame(width: 170)
                    
                    // 4. Daily Outflow Burn Rate Card
                    TelemetryHUDCard(
                        title: "Daily Outflow",
                        value: dailyAverageSpent.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                        unit: "/day",
                        subtitle: "Average account burn rate",
                        icon: "gauge.with.dots.needle.bottom.50percent",
                        color: themeColor
                    )
                    .frame(width: 170)
                }
                .padding(.horizontal, 16)
            }
        }
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
                                    let cat = store.categories.first(where: { $0.id == tx.categoryId })
                                    let subscription = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == tx.subscriptionId?.lowercased() })
                                    let iconSymbol = subscription?.sfSymbol ?? (cat?.sfSymbol ?? "cart.fill")
                                    let iconColor = subscription?.color ?? (cat?.color ?? Color(hex: "#34C759"))
                                    
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
                                                
                                                Text(cat?.label ?? "General")
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
