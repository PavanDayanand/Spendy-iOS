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
    var selectedTab: Binding<AppTab>? = nil
    
    // View Filters & Navigation State
    @State private var groupingMode: AnalyticsGroupingMode = .categories
    @State private var granularity: TimeGranularity = .month
    @State private var selectedDate: Date = Date()
    @State private var showMonthPicker: Bool = false
    @State private var selectedAccountId: String = "all"
    
    // Chart State
    @State private var chartProgress: Double = 1.0
    
    // Interactive Selected Chart Items
    @State private var selectedCashflowLabel: String? = nil
    @State private var selectedSpendingLabel: String? = nil
    @State private var selectedIncomeLabel: String? = nil
    @State private var selectedVelocityLabel: String? = nil
    @State private var selectedCategorySectorId: String? = nil
    @State private var selectedIncomeSectorId: String? = nil
    @State private var selectedCategoryForSheet: Category? = nil
    @State private var selectedAccountForSheet: Account? = nil
    @State private var showSubscriptionSheet: Bool = false
    
    // Collapsible List Expand States
    @State private var isSpendingListExpanded: Bool = false
    @State private var isIncomeListExpanded: Bool = false
    
    @Namespace private var analyticsControlsNamespace
    
    private let calendar = Calendar.current
    
    // Computed helpers for account dropdown
    private var selectedAccountLabel: String {
        if selectedAccountId == "all" { return "All Accounts" }
        return store.accounts.first(where: { $0.id == selectedAccountId })?.label ?? "Account"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 18, pinnedViews: [.sectionHeaders]) {
                        // 1. Unpinned Header Bar: Large Title "Analytics"
                        headerBar
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        // 2. Pinned Section: Sticky 3-Toggle Toolbar & Cards Stack
                        Section {
                            VStack(spacing: 18) {
                                // Card 1: Cashflow Overview Card
                                cashflowOverviewCard
                                
                                // Card 2: Spending Breakdown Card & List
                                spendingBreakdownCard
                                
                                // Card 3: Income Breakdown Card & List
                                incomeBreakdownCard
                                
                                // Card 4: Budget Ring & Pacing Card
                                budgetRingPacingCard
                                
                                // Card 5: Smart Insights Carousel
                                smartInsightsCarousel
                                     .padding(.horizontal, -20)
                                    .padding(.bottom, 30)
                            }
                            .padding(.horizontal, 20)
                        } header: {
                            // Sticky Toolbar floating on top
                            compactHeader
                                .padding(.horizontal, 20)
                                .padding(.top, 6)
                                .padding(.bottom, 12)
                        }
                    }
                    .padding(.bottom, 140) // Full clearance for floating bottom GlassTabBar
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showMonthPicker) {
                datePickerSheet
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionWidgetSheet()
            }
            .sheet(item: $selectedAccountForSheet) { account in
                AccountAnalyticsSheet(account: account)
            }
            .navigationDestination(item: $selectedCategoryForSheet) { category in
                CategoryAnalyticsSheet(
                    category: category,
                    topControlsNamespace: analyticsControlsNamespace
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedCategoryForSheet = nil
                    }
                }
            }
            .onAppear {
                chartProgress = 1.0
            }
            .onChange(of: selectedDate) { _, _ in
                resetSelections()
                chartProgress = 1.0
            }
            .onChange(of: granularity) { _, _ in
                resetSelections()
                chartProgress = 1.0
            }
            .onChange(of: selectedAccountId) { _, _ in
                resetSelections()
                chartProgress = 1.0
            }
        }
    }
    
    private func triggerEntranceAnimation() {
        chartProgress = 1.0
    }
    
    // MARK: - Header Bar (Large Title)
    private var headerBar: some View {
        HStack(alignment: .center) {
            Text("Analytics")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
        }
    }
    
    // MARK: - 1. Compact Header Row
    private var compactHeader: some View {
        HStack(spacing: 0) {
            // Left: Timeframe Granularity Selector
            Menu {
                ForEach(TimeGranularity.allCases) { item in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            granularity = item
                            resetSelections()
                        }
                    }) {
                        HStack {
                            Text(item.rawValue)
                            if granularity == item { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                GlassCircleIcon(
                    icon: "calendar",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary
                )
            }
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
                        .font(.system(size: 15, weight: .heavy))
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
            
            // Right: Settings Menu (Account Filter + Category/Account Grouping)
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
                
                Section("Group Breakdown By") {
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
                GlassCircleIcon(
                    icon: "line.3.horizontal.decrease.circle.fill",
                    size: 44,
                    iconSize: 18,
                    iconWeight: .medium,
                    foregroundColor: selectedAccountId != "all" || groupingMode != .categories ? SpendyColors.textPrimary : SpendyColors.textSecondary
                )
            }
        }
    }

    // MARK: - Card 1: Cashflow Overview Card
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
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(isPositive ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
                }
                
                Spacer()
                
                // Savings Rate Badge
                if totalIncome > 0 {
                    let rate = savingsRatePercentage
                    HStack(spacing: 4) {
                        Image(systemName: rate >= 0 ? "leaf.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(String(format: "%.0f%% Savings", abs(rate)))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .foregroundStyle(rate >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
                    .background {
                        Capsule()
                            .fill((rate >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed).opacity(0.15))
                            .overlay(Capsule().stroke((rate >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed).opacity(0.3), lineWidth: 0.8))
                    }
                }
                
                if let sel = selectedInterval {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(sel.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        let selNet = sel.incomeAmount - sel.spendingAmount
                        Text(selNet.formattedSignedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(selNet >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
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
            
            // Native Swift Chart: Interactive Cashflow Multi-Bar Chart with Flow Animation
            Chart(intervals) { item in
                let isSelected = selectedCashflowLabel == item.label
                
                BarMark(
                    x: .value("Period", item.label),
                    y: .value("Spending", item.spendingAmount * chartProgress)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#FF3B30").opacity(isSelected ? 1.0 : (item.spendingAmount > 0 ? 0.9 : 0.2)),
                                 Color(hex: "#FF3B30").opacity(isSelected ? 0.8 : 0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .position(by: .value("Type", "Spending"))
                .cornerRadius(6)
                
                BarMark(
                    x: .value("Period", item.label),
                    y: .value("Income", item.incomeAmount * chartProgress)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#34C759").opacity(isSelected ? 1.0 : (item.incomeAmount > 0 ? 0.95 : 0.2)),
                                 Color(hex: "#34C759").opacity(isSelected ? 0.85 : 0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .position(by: .value("Type", "Income"))
                .cornerRadius(6)
                
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
            
            // Legend Rows
            VStack(spacing: 8) {
                HStack {
                    Circle().fill(Color(hex: "#FF3B30")).frame(width: 7, height: 7)
                    Text("Spending")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Spacer()
                    Text(totalSpending.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Color(hex: "#FF3B30"))
                }
                
                HStack {
                    Circle().fill(Color(hex: "#34C759")).frame(width: 7, height: 7)
                    Text("Income")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Spacer()
                    Text("+" + totalIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Color(hex: "#34C759"))
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
    
    // MARK: - Card 2: Spending Breakdown Card
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
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                Spacer()
                
                if let sel = selectedInterval {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(sel.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Text(sel.spendingAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .font(.system(size: 15, weight: .heavy))
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
            
            // Native Swift Chart: Spending Line & Area Chart with Flow Animation
            Chart {
                ForEach(intervals) { item in
                    LineMark(
                        x: .value("Period", item.label),
                        y: .value("Spending", item.spendingAmount * chartProgress)
                    )
                    .foregroundStyle(Color(hex: "#FF3B30"))
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .symbol {
                        Circle()
                            .fill(selectedSpendingLabel == item.label ? Color(hex: "#FF3B30") : SpendyColors.cardBackground)
                            .stroke(Color(hex: "#FF3B30"), lineWidth: 2)
                            .frame(width: selectedSpendingLabel == item.label ? 10 : 6, height: selectedSpendingLabel == item.label ? 10 : 6)
                    }
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Period", item.label),
                        y: .value("Spending", item.spendingAmount * chartProgress)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FF3B30").opacity(0.35), Color(hex: "#FF3B30").opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // Average Spending RuleMark
                if avgSpend > 0 {
                    RuleMark(y: .value("Average", avgSpend * chartProgress))
                        .foregroundStyle(Color(hex: "#FF3B30").opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("AVG \(formatAxisAmount(avgSpend))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color(hex: "#FF3B30"))
                                .padding(.horizontal, 4)
                        }
                }
                
                if let selectedLabel = selectedSpendingLabel, let sel = selectedInterval {
                    RuleMark(x: .value("Selected", selectedLabel))
                        .foregroundStyle(Color(hex: "#FF3B30").opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .annotation(position: .top, alignment: .center) {
                            Text(sel.spendingAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "#FF3B30"))
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
            
            // Interactive Donut Chart for Category / Account Distribution with Flow Animation
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().background(SpendyColors.separator)
                    
                    Text(groupingMode == .categories ? "Category Distribution" : "Account Distribution")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    HStack(spacing: 16) {
                        Chart(items) { item in
                            let isSelected = selectedCategorySectorId == item.id
                            SectorMark(
                                angle: .value("Amount", max(0.01, item.amount * chartProgress)),
                                innerRadius: .ratio(0.62),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(Color(hex: item.colorHex))
                            .opacity(selectedCategorySectorId == nil || isSelected ? 1.0 : 0.35)
                        }
                        .chartAngleSelection(value: $selectedCategorySectorId)
                        .frame(width: 100, height: 100)
                        .overlay {
                            VStack(spacing: 0) {
                                Text("\(items.count)")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                Text(groupingMode == .categories ? "Categories" : "Accounts")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(items.prefix(4)) { item in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: item.colorHex))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(item.label)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.0f%%", item.percentage))
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(SpendyColors.textTertiary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    if selectedCategorySectorId == item.id {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: item.colorHex).opacity(0.15))
                                    }
                                }
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        if selectedCategorySectorId == item.id {
                                            selectedCategorySectorId = nil
                                        } else {
                                            selectedCategorySectorId = item.id
                                        }
                                        HapticsManager.shared.trigger(.selection)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Divider().background(SpendyColors.separator)
            
            // Sub-header: Spending by Category / Account
            HStack {
                Text(groupingMode == .categories ? "Spending by Category" : "Spending by Account")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                if items.count > 3 {
                    Image(systemName: isSpendingListExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if items.count > 3 {
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
                let displayedItems = isSpendingListExpanded ? items : Array(items.prefix(3))
                VStack(spacing: 12) {
                    ForEach(displayedItems) { item in
                        let isSectorSelected = selectedCategorySectorId == item.id
                        HStack(spacing: 12) {
                            SpendyIconBadge(
                                sfSymbol: item.sfSymbol,
                                color: Color(hex: item.colorHex),
                                size: .medium,
                                style: .circle
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
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundStyle(SpendyColors.textPrimary)
                            }
                        }
                        .padding(8)
                        .background {
                            if isSectorSelected {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: item.colorHex).opacity(0.12))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: item.colorHex).opacity(0.4), lineWidth: 1))
                            }
                        }
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
    
    // MARK: - Card 3: Income Breakdown Card
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
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(SpendyColors.incomeGreen)
                }
                
                Spacer()
                
                if let sel = selectedInterval {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(sel.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Text("+" + sel.incomeAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .font(.system(size: 15, weight: .heavy))
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
            
            // Native Swift Chart: Income Line Chart with Flow Animation
            Chart {
                ForEach(intervals) { item in
                    LineMark(
                        x: .value("Period", item.label),
                        y: .value("Income", item.incomeAmount * chartProgress)
                    )
                    .foregroundStyle(Color(hex: "#34C759"))
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .symbol {
                        Circle()
                            .fill(selectedIncomeLabel == item.label ? Color(hex: "#34C759") : SpendyColors.cardBackground)
                            .stroke(Color(hex: "#34C759"), lineWidth: 2)
                            .frame(width: selectedIncomeLabel == item.label ? 10 : 6, height: selectedIncomeLabel == item.label ? 10 : 6)
                    }
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Period", item.label),
                        y: .value("Income", item.incomeAmount * chartProgress)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#34C759").opacity(0.35), Color(hex: "#34C759").opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                if avgIncome > 0 {
                    RuleMark(y: .value("Average", avgIncome * chartProgress))
                        .foregroundStyle(Color(hex: "#34C759").opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("AVG \(formatAxisAmount(avgIncome))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color(hex: "#34C759"))
                                .padding(.horizontal, 4)
                        }
                }
                
                if let selectedLabel = selectedIncomeLabel, let sel = selectedInterval {
                    RuleMark(x: .value("Selected", selectedLabel))
                        .foregroundStyle(Color(hex: "#34C759").opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .annotation(position: .top, alignment: .center) {
                            Text("+" + sel.incomeAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: "#34C759"))
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
            
            // Donut SectorMark Chart for Income Distribution with Flow Animation
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().background(SpendyColors.separator)
                    
                    Text(groupingMode == .categories ? "Income Source Distribution" : "Income Account Distribution")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    HStack(spacing: 16) {
                        Chart(items) { item in
                            let isSelected = selectedIncomeSectorId == item.id
                            SectorMark(
                                angle: .value("Amount", max(0.01, item.amount * chartProgress)),
                                innerRadius: .ratio(0.62),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(Color(hex: item.colorHex))
                            .opacity(selectedIncomeSectorId == nil || isSelected ? 1.0 : 0.35)
                        }
                        .chartAngleSelection(value: $selectedIncomeSectorId)
                        .frame(width: 100, height: 100)
                        .overlay {
                            VStack(spacing: 0) {
                                Text("\(items.count)")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundStyle(SpendyColors.incomeGreen)
                                Text(groupingMode == .categories ? "Sources" : "Accounts")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(items.prefix(4)) { item in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: item.colorHex))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(item.label)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.0f%%", item.percentage))
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(SpendyColors.incomeGreen)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    if selectedIncomeSectorId == item.id {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: item.colorHex).opacity(0.15))
                                    }
                                }
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        if selectedIncomeSectorId == item.id {
                                            selectedIncomeSectorId = nil
                                        } else {
                                            selectedIncomeSectorId = item.id
                                        }
                                        HapticsManager.shared.trigger(.selection)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Divider().background(SpendyColors.separator)
            
            // Sub-header: Income by Category / Account
            HStack {
                Text(groupingMode == .categories ? "Income by Category" : "Income by Account")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                if items.count > 3 {
                    Image(systemName: isIncomeListExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if items.count > 3 {
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
                let displayedItems = isIncomeListExpanded ? items : Array(items.prefix(3))
                VStack(spacing: 12) {
                    ForEach(displayedItems) { item in
                        let isSelected = selectedIncomeSectorId == item.id
                        HStack(spacing: 12) {
                            SpendyIconBadge(
                                sfSymbol: item.sfSymbol,
                                color: Color(hex: item.colorHex),
                                size: .medium,
                                style: .circle
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
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("+" + item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundStyle(SpendyColors.incomeGreen)
                            }
                        }
                        .padding(8)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: item.colorHex).opacity(0.12))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: item.colorHex).opacity(0.4), lineWidth: 1))
                            }
                        }
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
    
    // MARK: - Card 4: Budget Ring & Pacing Card
    private var budgetRingPacingCard: some View {
        let budgetLimit = store.budgetTargetAmount(for: .monthly)
        let spent = totalSpending
        let pct = budgetLimit > 0 ? (spent / budgetLimit) * 100 : 0.0
        let isExceeded = pct > 100
        let ringProgress = min(1.0, pct / 100.0) * chartProgress
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Budget Status")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
            
            HStack(spacing: 20) {
                // Circular Progress Gauge Ring with Flow Animation
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
                    
                    Text(String(format: "%.0f%%", pct * chartProgress))
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isExceeded ? String(format: "Budget exceeded by %.0f%%", pct - 100) : "Within budget limit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text(spent.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(isExceeded ? SpendyColors.expenseRed : SpendyColors.textPrimary)
                    
                    Text("of \(budgetLimit.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) limit")
                        .font(.system(size: 12, weight: .medium))
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            
            Divider().background(SpendyColors.separator)
            
            // Sub-metrics (Monthly date bounds & Days status)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Period")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    Text(formattedMonthRange(selectedDate))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Status")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    Text(remainingDaysText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            
            Divider().background(SpendyColors.separator)
            
            // Calibrated Daily Budget Pacing Chart with Flow Animation
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Budget Pacing")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SpendyColors.textTertiary)
                
                let pacingItems = velocityPacingData
                Chart {
                    ForEach(pacingItems) { item in
                        if item.isPeak && item.amount > 0 {
                            RectangleMark(
                                x: .value("Period", item.label),
                                yStart: .value("Min", 0),
                                yEnd: .value("Max", (pacingItems.map(\.amount).max() ?? 1.0) * 1.15 * chartProgress)
                            )
                            .foregroundStyle(
                                item.isOverTarget 
                                    ? Color(hex: "#FF3B30").opacity(0.12)
                                    : Color(hex: "#30D158").opacity(0.12)
                            )
                            .cornerRadius(6)
                        }
                        
                        BarMark(
                            x: .value("Period", item.label),
                            y: .value("Spending", item.amount * chartProgress)
                        )
                        .foregroundStyle(
                            item.amount <= 0 
                                ? SpendyColors.separator.opacity(0.4)
                                : (item.isOverTarget ? Color(hex: "#FF3B30") : Color(hex: "#30D158"))
                        )
                        .cornerRadius(5)
                        .annotation(position: .top, alignment: .center, spacing: 4) {
                            if item.isPeak && item.amount > 0 {
                                Image(systemName: item.isOverTarget ? "flame.fill" : "bolt.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(item.isOverTarget ? Color(hex: "#FF3B30") : Color(hex: "#30D158"))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background {
                                        Capsule()
                                            .fill(SpendyColors.cardBackground)
                                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                                    }
                            }
                        }
                    }
                    
                    if let selectedLabel = selectedVelocityLabel, let sel = pacingItems.first(where: { $0.label == selectedLabel }) {
                        RuleMark(x: .value("Selected", selectedLabel))
                            .foregroundStyle(SpendyColors.textPrimary.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .annotation(position: .top, alignment: .center) {
                                Text(sel.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
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
                .chartXSelection(value: $selectedVelocityLabel)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
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
                .frame(height: 140)
                .padding(.vertical, 4)
                .onChange(of: selectedVelocityLabel) { _, _ in
                    HapticsManager.shared.trigger(.selection)
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
    
    // MARK: - Smart Insights Carousel
    private var smartInsightsCarousel: some View {
        let bounds = currentPeriodBounds
        let prevBounds = priorPeriodBounds
        
        let insights = InsightsEngine.getAnalyticsInsights(
            transactions: store.transactions,
            budget: store.budget,
            categories: store.categories,
            subscriptions: store.subscriptions,
            periodStart: bounds.start,
            periodEnd: bounds.end,
            prevStart: prevBounds.start,
            prevEnd: prevBounds.end,
            dataType: .expense,
            currencySymbol: store.currencySymbol
        )
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.primaryBlue)
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
                LazyHStack(spacing: 14) {
                    Spacer().frame(width: 4)
                    
                    if insights.isEmpty {
                        Text("No insights generated for this period.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                            .padding(.vertical, 40)
                            .padding(.horizontal, 20)
                    } else {
                        ForEach(insights) { insight in
                            SharedInsightCard(
                                title: insight.title,
                                value: insight.value,
                                subtitle: insight.desc,
                                icon: insight.icon,
                                color: insight.color,
                                action: {
                                    if insight.id.hasPrefix("sub_") || insight.family == "subscription" {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            if let selectedTab = selectedTab {
                                                selectedTab.wrappedValue = .manage
                                            } else {
                                                showSubscriptionSheet = true
                                            }
                                        }
                                    } else if let catId = insight.categoryId, let cat = store.categories.first(where: { $0.id == catId }) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            selectedCategoryForSheet = cat
                                        }
                                    } else if let cat = store.categories.first(where: { $0.id == insight.id || $0.label.lowercased() == insight.title.lowercased() }) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            selectedCategoryForSheet = cat
                                        }
                                    } else if let firstCat = store.categories.first {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            selectedCategoryForSheet = firstCat
                                        }
                                    }
                                }
                            )
                            .frame(width: 180)
                        }
                    }
                    
                    Spacer().frame(width: 4)
                }
                .padding(.vertical, 10)
            }
        }
    }
    
    // MARK: - Date Picker Modal Sheet
    private var datePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.black
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
    
    /// Filtered transactions in the active period
    private var filteredTransactions: [Transaction] {
        let bounds = currentPeriodBounds
        let accountFiltered = store.filteredTransactions(for: selectedAccountId)
        return accountFiltered.filter { tx in
            tx.date >= bounds.start && tx.date <= bounds.end
        }
    }
    
    private var totalSpending: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
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
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: start)) – \(fmt.string(from: end))"
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
    
    // MARK: - Velocity & Pacing Data Model
    private struct VelocityPacingItem: Identifiable {
        let id = UUID()
        let label: String
        let date: Date
        let amount: Double
        let isPeak: Bool
        let isOverTarget: Bool
    }
    
    private var velocityPacingData: [VelocityPacingItem] {
        let intervals = intervalData
        let maxSpend = intervals.map(\.spendingAmount).max() ?? 0.0
        
        let monthlyBudget = store.budgetTargetAmount(for: .monthly)
        let dailyTarget: Double = store.budget.isActive && store.budget.amount > 0 
            ? (monthlyBudget / 30.0) 
            : (maxSpend > 0 ? maxSpend * 0.6 : 1000.0)
            
        return intervals.map { item in
            let amount = item.spendingAmount
            
            let daysInBlock: Double
            switch granularity {
            case .day:
                daysInBlock = 0.25
            case .week:
                daysInBlock = 1.0
            case .month:
                let diff = calendar.dateComponents([.day], from: item.startDate, to: item.endDate).day ?? 7
                daysInBlock = Double(max(1, diff))
            case .year:
                let diff = calendar.range(of: .day, in: .month, for: item.startDate)?.count ?? 30
                daysInBlock = Double(diff)
            }
            
            let blockTarget = dailyTarget * daysInBlock
            let isOver = amount > blockTarget
            let isPeak = amount > 0 && amount >= (blockTarget * 0.85)
            
            return VelocityPacingItem(
                label: item.label,
                date: item.startDate,
                amount: amount,
                isPeak: isPeak,
                isOverTarget: isOver
            )
        }
    }
    
    private func resetSelections() {
        selectedCashflowLabel = nil
        selectedSpendingLabel = nil
        selectedIncomeLabel = nil
        selectedVelocityLabel = nil
        selectedCategorySectorId = nil
        selectedIncomeSectorId = nil
    }
}

#Preview {
    AnalyticsView()
        .environment(ExpenseStore())
        .preferredColorScheme(.dark)
}
