//
//  AnalyticsView.swift
//  Spendy
//
//  Multi-Chart Financial Analytics Hub with Timeframe Granularities (Day/Week/Month/Year),
//  Categories vs Accounts Toggles, Cashflow/Spending/Income Breakdown Cards & Budget Ring Pacing
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

// MARK: - Transaction Type Filter
enum TransactionTypeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case expense = "Expense"
    case income = "Income"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "arrow.left.arrow.right"
        case .expense: return "arrow.down.circle.fill"
        case .income: return "arrow.up.circle.fill"
        }
    }
}

// MARK: - Interval Data Model for Multi-Charts
struct PeriodIntervalData: Identifiable {
    let id = UUID()
    let label: String
    let startDate: Date
    let endDate: Date
    let spendingAmount: Double
    let incomeAmount: Double
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

struct AnalyticsView: View {
    @Environment(ExpenseStore.self) private var store
    
    // View Filters & Time Navigation
    @State private var groupingMode: AnalyticsGroupingMode = .categories
    @State private var granularity: TimeGranularity = .month
    @State private var selectedDate: Date = Date()
    @State private var showMonthPicker: Bool = false
    @State private var selectedAccountId: String = "all"
    @State private var typeFilter: TransactionTypeFilter = .all
    
    // Interactive Selected Interval (for tapping bars)
    @State private var selectedIntervalIndex: Int? = nil
    
    private let calendar = Calendar.current
    
    // Computed helpers for account dropdown
    private var selectedAccountLabel: String {
        if selectedAccountId == "all" { return "All Accounts" }
        return store.accounts.first(where: { $0.id == selectedAccountId })?.label ?? "Account"
    }
    
    private var selectedAccountSymbol: String {
        if selectedAccountId == "all" { return "wallet.pass.fill" }
        return store.accounts.first(where: { $0.id == selectedAccountId })?.sfSymbol ?? "creditcard.fill"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 3. Card 1: Cashflow Overview Card
                        cashflowOverviewCard
                        
                        // 4. Card 2: Spending Breakdown Card & List
                        spendingBreakdownCard
                        
                        // 5. Card 3: Income Breakdown Card & List
                        incomeBreakdownCard
                        
                        // 6. Card 4: Budget Ring & Pacing Card
                        budgetRingPacingCard
                        
                        // 7. Card 5: Smart Insights Carousel
                        smartInsightsCarousel
                            .padding(.horizontal, -20) // Negate parent padding for full bleed scroll
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .safeAreaInset(edge: .top) {
                    // 1. Compact Header: Account | < Period > | Settings
                    compactHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 16)
                        .background(
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .ignoresSafeArea(.all, edges: .top)
                        )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showMonthPicker) {
                datePickerSheet
            }
        }
    }
    
    // MARK: - 1. Compact Header Row
    // [🏦] ◀ Aug 2026 ▶ [⚙]
    private var compactHeader: some View {
        HStack(spacing: 0) {
            // Left: Granularity Selector (Liquid Glass circle with dropdown)
            Menu {
                ForEach(TimeGranularity.allCases) { item in
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            granularity = item
                            selectedIntervalIndex = nil
                        }
                    }) {
                        HStack {
                            Text(item.rawValue)
                            if granularity == item { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .nativeLiquidGlassCircle(isInteractive: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select Timeframe")
            
            Spacer()
            
            // Center: Period Navigation  ◀  Aug 2026  ▶
            HStack(spacing: 8) {
                Button(action: { stepPeriod(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showMonthPicker = true
                }) {
                    Text(formattedPillTitle)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .contentTransition(.numericText())
                }
                .buttonStyle(.plain)
                
                Button(action: { stepPeriod(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .nativeLiquidGlassCapsule(isInteractive: true)
            
            Spacer()
            
            // Right: Combined Settings Menu (Account + Type Filter + Grouping)
            Menu {
                Section("Account") {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { selectedAccountId = "all" }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        Label("All Accounts", systemImage: "wallet.pass.fill")
                        if selectedAccountId == "all" { Image(systemName: "checkmark") }
                    }
                    ForEach(store.accounts) { acc in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) { selectedAccountId = acc.id }
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            Label(acc.label, systemImage: acc.sfSymbol)
                            if selectedAccountId == acc.id { Image(systemName: "checkmark") }
                        }
                    }
                }
                
                Divider()
                
                Section("Show") {
                    ForEach(TransactionTypeFilter.allCases) { filter in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) { typeFilter = filter }
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            Label(filter.rawValue, systemImage: filter.icon)
                            if typeFilter == filter { Image(systemName: "checkmark") }
                        }
                    }
                }
                
                Divider()
                
                Section("Group by") {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { groupingMode = .categories }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        Label("Categories", systemImage: "square.grid.2x2.fill")
                        if groupingMode == .categories { Image(systemName: "checkmark") }
                    }
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { groupingMode = .accounts }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        Label("Accounts", systemImage: "building.columns.fill")
                        if groupingMode == .accounts { Image(systemName: "checkmark") }
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(typeFilter != .all || groupingMode != .categories ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .nativeLiquidGlassCircle(isInteractive: true)
            }
            .buttonStyle(.plain)
        }
    }
    

    // MARK: - 4. Card 1: Cashflow Overview Card
    private var cashflowOverviewCard: some View {
        let net = totalIncome - totalSpending
        let isPositive = net >= 0
        let intervals = intervalData
        let maxVal = max(100.0, intervals.map { max($0.spendingAmount, $0.incomeAmount) }.max() ?? 100.0)
        
        return VStack(alignment: .leading, spacing: 14) {
            Text("Cashflow")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SpendyColors.textTertiary)
            
            Text(net.formattedSignedCurrency(symbol: store.currencySymbol, decimals: 0))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(isPositive ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
            
            // Native Swift Chart: Cashflow Overview
            Chart(intervals) { item in
                BarMark(
                    x: .value("Period", item.label),
                    y: .value("Spending", item.spendingAmount)
                )
                .foregroundStyle(SpendyColors.textPrimary.opacity(item.spendingAmount > 0 ? 0.9 : 0.15))
                .position(by: .value("Type", "Spending"))
                .cornerRadius(4)
                
                BarMark(
                    x: .value("Period", item.label),
                    y: .value("Income", item.incomeAmount)
                )
                .foregroundStyle(SpendyColors.incomeGreen.opacity(item.incomeAmount > 0 ? 0.95 : 0.15))
                .position(by: .value("Type", "Income"))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(SpendyColors.separator)
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .chartLegend(.hidden)
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 140)
            .padding(.vertical, 8)
            
            // Budget Insight Alert Badge
            if store.budget.isActive && store.budget.amount > 0 {
                let limit = store.budgetTargetAmount(for: .monthly)
                let exceeded = totalSpending > limit
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(exceeded ? SpendyColors.warningOrange : SpendyColors.incomeGreen)
                    
                    Text(exceeded ? String(format: "Budget exceeded, %@ over with %d days left", (totalSpending - limit).formattedCurrency(symbol: store.currencySymbol, decimals: 0), remainingDaysInMonth) : "Pacing smoothly within monthly budget.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                .padding(.vertical, 4)
            }
            
            Divider().background(SpendyColors.separator)
            
            // Legend Rows
            VStack(spacing: 8) {
                HStack {
                    Circle().fill(SpendyColors.textPrimary).frame(width: 7, height: 7)
                    Text("Spending")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Spacer()
                    Text(totalSpending.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                HStack {
                    Circle().fill(SpendyColors.incomeGreen).frame(width: 7, height: 7)
                    Text("Income")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Spacer()
                    Text("+" + totalIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
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
    
    // MARK: - 5. Card 2: Spending Breakdown Card
    private var spendingBreakdownCard: some View {
        let items = spendingBreakdownItems
        let intervals = intervalData
        let maxSpend = max(100.0, intervals.map(\.spendingAmount).max() ?? 100.0)
        
        return VStack(alignment: .leading, spacing: 14) {
            Text("Spending")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SpendyColors.textTertiary)
            
            Text(totalSpending.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(SpendyColors.textPrimary)
            
            // Native Swift Chart: Spending Line Chart
            Chart(intervals) { item in
                LineMark(
                    x: .value("Period", item.label),
                    y: .value("Spending", item.spendingAmount)
                )
                .foregroundStyle(SpendyColors.textPrimary)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .symbol(Circle())
                .symbolSize(40)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Period", item.label),
                    y: .value("Spending", item.spendingAmount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [SpendyColors.textPrimary.opacity(0.3), SpendyColors.textPrimary.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(SpendyColors.separator)
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 120)
            .padding(.vertical, 4)
            
            Divider().background(SpendyColors.separator)
            
            // Sub-header: Spending by Category / Account
            HStack {
                Text(groupingMode == .categories ? "Spending by Category" : "Spending by Account")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            .padding(.top, 4)
            
            // List of Category / Account Breakdown Rows
            if items.isEmpty {
                Text("No spending recorded in this period.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            // Circular icon badge
                            ZStack {
                                Circle()
                                    .fill(Color(uiColor: .dynamic(
                                        light: UIColor(white: 0.88, alpha: 1),
                                        dark: UIColor(white: 0.18, alpha: 1)
                                    )))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: item.sfSymbol)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.label)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Text("\(item.txCount) \(item.txCount == 1 ? "expense" : "expenses")")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            
                            Spacer()
                            
                            Text(item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundStyle(SpendyColors.textPrimary)
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
    
    // MARK: - 6. Card 3: Income Breakdown Card
    private var incomeBreakdownCard: some View {
        let items = incomeBreakdownItems
        let intervals = intervalData
        let maxIncome = max(100.0, intervals.map(\.incomeAmount).max() ?? 100.0)
        
        return VStack(alignment: .leading, spacing: 14) {
            Text("Income")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SpendyColors.textTertiary)
            
            Text("+" + totalIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(SpendyColors.incomeGreen)
            
            // Native Swift Chart: Income Line Chart
            Chart(intervals) { item in
                LineMark(
                    x: .value("Period", item.label),
                    y: .value("Income", item.incomeAmount)
                )
                .foregroundStyle(SpendyColors.incomeGreen)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .symbol(Circle())
                .symbolSize(40)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Period", item.label),
                    y: .value("Income", item.incomeAmount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [SpendyColors.incomeGreen.opacity(0.3), SpendyColors.incomeGreen.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(SpendyColors.separator)
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 120)
            .padding(.vertical, 4)
            
            Divider().background(SpendyColors.separator)
            
            // Sub-header: Income by Category / Account
            HStack {
                Text(groupingMode == .categories ? "Income by Category" : "Income by Account")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            .padding(.top, 4)
            
            // List of Income Rows
            if items.isEmpty {
                Text("No income recorded in this period.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(uiColor: .dynamic(
                                        light: UIColor(white: 0.88, alpha: 1),
                                        dark: UIColor(white: 0.18, alpha: 1)
                                    )))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: item.sfSymbol)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(SpendyColors.incomeGreen)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.label)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Text("\(item.txCount) \(item.txCount == 1 ? "transaction" : "transactions")")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            
                            Spacer()
                            
                            Text("+" + item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundStyle(SpendyColors.incomeGreen)
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
    
    // MARK: - 7. Card 4: Budget Ring & Pacing Card
    private var budgetRingPacingCard: some View {
        let budgetLimit = store.budgetTargetAmount(for: .monthly)
        let spent = totalSpending
        let pct = budgetLimit > 0 ? (spent / budgetLimit) * 100 : 0.0
        let isExceeded = pct > 100
        let ringProgress = min(1.0, pct / 100.0)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Budget")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SpendyColors.textTertiary)
            
            HStack(spacing: 20) {
                // Circular Progress Gauge Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 8)
                        .frame(width: 84, height: 84)
                    
                    Circle()
                        .trim(from: 0.0, to: ringProgress)
                        .stroke(
                            isExceeded ? SpendyColors.expenseRed : SpendyColors.textPrimary,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 84, height: 84)
                    
                    Text(String(format: "%.0f%%", pct))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isExceeded ? String(format: "Budget exceeded by %.0f%%", pct - 100) : "Within budget limit")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text(spent.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(isExceeded ? SpendyColors.expenseRed : SpendyColors.textPrimary)
                    
                    Text("of \(budgetLimit.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) limit")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .padding(.vertical, 4)
            
            // Pacing note
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isExceeded ? SpendyColors.warningOrange : SpendyColors.incomeGreen)
                
                Text(isExceeded ? String(format: "At this pace, the budget will be exceeded by ↑ %@", (spent - budgetLimit).formattedCurrency(symbol: store.currencySymbol, decimals: 0)) : "You are pacing within safe limits for this month.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            
            Divider().background(SpendyColors.separator)
            
            // Sub-metrics (Monthly date bounds & Days left)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                    Text(formattedMonthRange(selectedDate))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Days left")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                    Text("\(remainingDaysInMonth) days left")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
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
    
    // MARK: - 8. Card 5: Smart Insights Carousel
    private var smartInsightsCarousel: some View {
        let bounds = currentPeriodBounds
        let prevBounds = priorPeriodBounds
        
        let targetType: TransactionType = (typeFilter == .income) ? .income : .expense
        
        let insights = InsightsEngine.getAnalyticsInsights(
            transactions: store.transactions,
            budget: store.budget,
            categories: store.categories,
            subscriptions: store.subscriptions,
            periodStart: bounds.start,
            periodEnd: bounds.end,
            prevStart: prevBounds.start,
            prevEnd: prevBounds.end,
            dataType: targetType,
            currencySymbol: store.currencySymbol
        )
        
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                Spacer().frame(width: 4)
                
                if insights.isEmpty {
                    Text("No insights generated for this period.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)
                } else {
                    ForEach(insights) { insight in
                        insightCard(
                            title: insight.title,
                            value: insight.value,
                            subtitle: insight.desc,
                            color: insight.color,
                            icon: insight.icon
                        )
                    }
                }
                
                Spacer().frame(width: 4)
            }
            .padding(.vertical, 10)
        }
    }
    
    private func insightCard(title: String, value: String, subtitle: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Title
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(SpendyColors.textSecondary)
                .textCase(.uppercase)
                .padding(.bottom, 16)
            
            // Value
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.bottom, 4)
            
            Spacer()
            
            // Footer: Icon + Subtitle
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                        // Adds the subtle glow from the React version
                        .shadow(color: color.opacity(0.33), radius: 5, x: 0, y: 0)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color)
                }
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(width: 180, height: 165, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(white: 0.04)) // Close to #0a0a0a
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 12, x: 0, y: 5)
        }
    }
    
    // MARK: - Date Picker Modal Sheet
    private var datePickerSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    DatePicker(
                        "Choose Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(SpendyColors.textPrimary)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(SpendyColors.cardBackground)
                    }
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
                    .foregroundStyle(SpendyColors.textPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Computed Properties & Period Math
    
    /// Date range boundaries based on selected granularity
    private var currentPeriodBounds: (start: Date, end: Date) {
        switch granularity {
        case .day:
            return (selectedDate.startOfDay, selectedDate.endOfDay)
        case .week:
            return (selectedDate.startOfWeek, selectedDate.endOfWeek)
        case .month:
            return (selectedDate.startOfMonth, selectedDate.endOfMonth)
        case .year:
            return (selectedDate.startOfYear, selectedDate.endOfYear)
        }
    }
    
    private var priorPeriodBounds: (start: Date, end: Date) {
        let bounds = currentPeriodBounds
        switch granularity {
        case .day:
            let start = calendar.date(byAdding: .day, value: -1, to: bounds.start) ?? bounds.start
            let end = calendar.date(byAdding: .day, value: -1, to: bounds.end) ?? bounds.end
            return (start, end)
        case .week:
            let start = calendar.date(byAdding: .weekOfYear, value: -1, to: bounds.start) ?? bounds.start
            let end = calendar.date(byAdding: .weekOfYear, value: -1, to: bounds.end) ?? bounds.end
            return (start, end)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: bounds.start) ?? bounds.start
            let end = calendar.date(byAdding: .month, value: -1, to: bounds.end) ?? bounds.end
            return (start, end)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: bounds.start) ?? bounds.start
            let end = calendar.date(byAdding: .year, value: -1, to: bounds.end) ?? bounds.end
            return (start, end)
        }
    }
    
    /// Filtered transactions in the active period, optionally filtered by account and type
    private var filteredTransactions: [Transaction] {
        let bounds = currentPeriodBounds
        let accountFiltered = store.filteredTransactions(for: selectedAccountId)
        return accountFiltered.filter { tx in
            let inPeriod = tx.date >= bounds.start && tx.date <= bounds.end
            switch typeFilter {
            case .all: return inPeriod
            case .expense: return inPeriod && tx.type == .expense
            case .income: return inPeriod && tx.type == .income
            }
        }
    }
    
    private var totalSpending: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
    }
    
    /// Granular intervals for the multi-bar charts
    private var intervalData: [PeriodIntervalData] {
        var intervals: [PeriodIntervalData] = []
        let txs = filteredTransactions
        
        switch granularity {
        case .day:
            // 4 time blocks: Night (12-6), Morning (6-12), Afternoon (12-18), Evening (18-24)
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
            // 7 Days: Mon, Tue, Wed, Thu, Fri, Sat, Sun
            let start = selectedDate.startOfWeek
            let shortFmt = DateFormatter()
            shortFmt.dateFormat = "EEE"
            for d in 0..<7 {
                let dayStart = calendar.date(byAdding: .day, value: d, to: start) ?? start
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? start
                let dayTxs = txs.filter { $0.date >= dayStart && $0.date < dayEnd }
                let spend = dayTxs.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
                let inc = dayTxs.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
                intervals.append(PeriodIntervalData(label: shortFmt.string(from: dayStart), startDate: dayStart, endDate: dayEnd, spendingAmount: spend, incomeAmount: inc))
            }
            
        case .month:
            // 5 interval blocks matching screenshot: 1-7, 8-14, 15-21, 22-28, 29-31
            let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
            let ranges = [
                (1, 7, "1-7"),
                (8, 14, "8-14"),
                (15, 21, "15-21"),
                (22, 28, "22-28"),
                (29, daysInMonth, "29-\(daysInMonth)")
            ]
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
            // 12 Months: Jan..Dec
            let start = selectedDate.startOfYear
            let monthFmt = DateFormatter()
            monthFmt.dateFormat = "MMM"
            for m in 0..<12 {
                let mStart = calendar.date(byAdding: .month, value: m, to: start) ?? start
                let mEnd = calendar.date(byAdding: .month, value: 1, to: mStart) ?? start
                let mTxs = txs.filter { $0.date >= mStart && $0.date < mEnd }
                let spend = mTxs.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
                let inc = mTxs.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
                intervals.append(PeriodIntervalData(label: monthFmt.string(from: mStart), startDate: mStart, endDate: mEnd, spendingAmount: spend, incomeAmount: inc))
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
    
    private var currentPeriodTitle: String {
        switch granularity {
        case .day:
            let fmt = DateFormatter()
            fmt.dateFormat = "d MMMM yyyy"
            return fmt.string(from: selectedDate)
        case .week:
            let fmt = DateFormatter()
            fmt.dateFormat = "d MMM"
            return "\(fmt.string(from: selectedDate.startOfWeek)) – \(fmt.string(from: selectedDate.endOfWeek))"
        case .month:
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM yyyy"
            return "Budget: \(fmt.string(from: selectedDate))"
        case .year:
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy"
            return "Year \(fmt.string(from: selectedDate))"
        }
    }
    
    private var formattedPillTitle: String {
        let fmt = DateFormatter()
        switch granularity {
        case .day: fmt.dateFormat = "d MMM"
        case .week: fmt.dateFormat = "d MMM"
        case .month: fmt.dateFormat = "MMM yyyy"
        case .year: fmt.dateFormat = "yyyy"
        }
        return fmt.string(from: selectedDate)
    }
    
    private var remainingDaysInMonth: Int {
        let now = Date()
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
        if calendar.isDate(selectedDate, equalTo: now, toGranularity: .month) {
            let currentDay = calendar.component(.day, from: now)
            return max(0, daysInMonth - currentDay)
        }
        return 0
    }
    
    private var dailyAverageSpend: Double {
        let days = max(1, intervalData.count)
        return totalSpending / Double(days)
    }
    
    private var mostActiveWeekdayName: String {
        var dayCounts: [Int: Int] = [:]
        for t in filteredTransactions.filter({ $0.type == .expense }) {
            let wd = calendar.component(.weekday, from: t.date)
            dayCounts[wd, default: 0] += 1
        }
        guard let topWd = dayCounts.max(by: { $0.value < $1.value })?.key else {
            return "None"
        }
        let symbols = calendar.weekdaySymbols
        return symbols[topWd - 1]
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
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: start)) – \(fmt.string(from: end))"
    }
}

#Preview {
    AnalyticsView()
        .environment(ExpenseStore())
        .preferredColorScheme(.dark)
}
