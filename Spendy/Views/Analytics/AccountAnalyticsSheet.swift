//
//  AccountAnalyticsSheet.swift
//  Spendy
//
//  Apple HIG Bank Account Analytics Sheet
//  Features:
//  - Centralized Bank/Account Icon & Hero Balance
//  - SwiftCharts Area Graph & Index Filter Strip matching Category Analytics
//  - Liquid Glass Segmented Period Selector (1w, 1m, 3m, 6m, 1y, Custom)
//  - Redesigned Liquid Glass Cash Flow & Stats Bento Hub
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
    
    private var daysInSelectedPeriod: Int {
        if let custom = customDateRange {
            let diff = Calendar.current.dateComponents([.day], from: custom.start, to: custom.end).day ?? 1
            return max(1, diff + 1)
        }
        return AnalyticsChartEngine.daysInPeriod(for: selectedPeriod)
    }
    
    private var dailyAvgOutflow: Double {
        totalOutflow / Double(daysInSelectedPeriod)
    }
    
    private var avgTransactionSize: Double {
        let expenseTxs = filteredTransactions.filter { $0.type == .expense }
        guard !expenseTxs.isEmpty else { return 0 }
        return totalOutflow / Double(expenseTxs.count)
    }
    
    // MARK: - SwiftCharts Points (Identical to Category Analytics)
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
            SpendyAmbientHeaderBackground(color: themeColor, height: 420, opacity: 0.35)
            
            VStack(spacing: 0) {
                if isHomeOrigin {
                    topHeaderBar
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Centralized Account Avatar & Hero Balance Header
                        centralizedHeroHeader
                            .padding(.horizontal, 16)
                            .padding(.top, isHomeOrigin ? 2 : 6)
                        
                        // 2. Exact SwiftCharts Area Graph & Index Filter Strip (from Category Analytics)
                        chartSection
                            .padding(.horizontal, 16)
                        
                        // 3. Redesigned Unified Cash Flow & Stats Bento Hub
                        if allAccountTransactions.isEmpty {
                            emptyInsightsCard
                                .padding(.horizontal, 16)
                        } else {
                            unifiedAccountStatsCard
                                .padding(.horizontal, 16)
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
    
    // MARK: - 2. Centralized Bank Avatar & Hero Balance Header
    private var centralizedHeroHeader: some View {
        VStack(spacing: 6) {
            // Centralized Bank / Account Icon Badge
            SpendyIconBadge(
                sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                color: themeColor,
                size: .large,
                style: .circle
            )
            .shadow(color: themeColor.opacity(0.4), radius: 12, y: 3)
            
            // Hero Balance Amount
            Text(currentBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                .foregroundStyle(SpendyColors.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            // Period / Context Subtitle
            Text("Balance in \(periodHeaderLabel)")
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(SpendyColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
    
    // MARK: - 3. SwiftCharts Area Graph & Index Filter Strip (Identical to Category Analytics)
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
                    // 1. Actual Area Gradient below historical curve
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
                    
                    // 2. Actual Solid Line Curve
                    ForEach(chartPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(chartThemeColor)
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

    // MARK: - 4. Redesigned Unified Cash Flow & Stats Bento Hub
    private var unifiedAccountStatsCard: some View {
        VStack(spacing: 14) {
            // Row 1: Money In & Money Out Dual Hero Split
            HStack(spacing: 12) {
                // Money In Cell
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
                
                // Money Out Cell
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
            
            // Row 2: Daily Average & Avg Transaction
            HStack(spacing: 12) {
                // Daily Average
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.16))
                            .frame(width: 32, height: 32)
                        Image(systemName: "calendar")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(themeColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Average")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        Text("\(dailyAvgOutflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .overlay(SpendyColors.separator)
                    .frame(height: 32)
                
                // Avg Transaction
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#AF52DE").opacity(0.16))
                            .frame(width: 32, height: 32)
                        Image(systemName: "creditcard")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(Color(hex: "#AF52DE"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avg Transaction")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        Text(avgTransactionSize.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
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
    
    // MARK: - Empty Insights Card
    private var emptyInsightsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Text("Add more transactions to unlock personalised insights")
                .font(.system(size: 13.5, weight: .regular))
                .foregroundStyle(SpendyColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
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
