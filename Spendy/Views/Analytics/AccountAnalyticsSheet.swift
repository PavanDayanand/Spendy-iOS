//
//  AccountAnalyticsSheet.swift
//  Spendy
//
//  Apple HIG Bank Account Analytics Sheet with Hero Balance,
//  Interactive Touch-Scrubbing SwiftCharts Area Graph on Content Layer,
//  Glass Index Period Selector, 4-Metric Account Overview Card,
//  and Date-Grouped Transaction Activity List.
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
    @State private var rawSelectedDate: Date? = nil
    @State private var showDatePicker: Bool = false
    @State private var showAddTransaction: Bool = false
    @Namespace private var accountSheetNamespace
    
    // MARK: - Computed Properties
    private var themeColor: Color {
        account.color
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
    
    private var netFlow: Double {
        totalInflow - totalOutflow
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
    
    private var chartPoints: [CategoryChartPoint] {
        AnalyticsChartEngine.generateChartPoints(
            transactions: allAccountTransactions,
            period: selectedPeriod,
            hasEnoughTxs: false,
            valueForDay: { txs in
                let inflow = txs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let outflow = txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                return inflow - outflow
            }
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
            return "Balance in \(formatter.string(from: bounds.start))"
        case .threeMonths:
            return "Last 3 Months"
        case .sixMonths:
            return "Last 6 Months"
        case .year:
            formatter.dateFormat = "yyyy"
            return "Balance in \(formatter.string(from: bounds.start))"
        }
    }
    
    private var dateGroupedTransactions: [(String, Double, [Transaction])] {
        AnalyticsChartEngine.dateGroupedTransactions(from: filteredTransactions)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()
            
            // Dynamic Ambient Full-Width Header Glow
            SpendyAmbientHeaderBackground(color: themeColor, height: 420, opacity: 0.38)
            
            VStack(spacing: 0) {
                if isHomeOrigin {
                    topHeaderBar
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Clean Hero Account Balance Header (Pure Content)
                        heroHeaderSection
                            .padding(.horizontal, 20)
                            .padding(.top, isHomeOrigin ? 4 : 12)
                        
                        // 2. Uncarded SwiftCharts Area Graph & Glass Index Strip
                        chartSection
                            .padding(.horizontal, 16)
                        
                        // 3. Consolidated 4-Metric Account Overview Card or Insights Card
                        if allAccountTransactions.count < 3 {
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
                            accountOverviewCard
                                .padding(.horizontal, 20)
                                .padding(.top, 4)
                        }
                        
                        // 4. Date-Grouped Account Activity List
                        transactionsSection
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
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
            
            Text(account.label)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            // Trailing Edit button matching topControl_right
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
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
    
    // MARK: - 2. Hero Header Section (Clean Apple Wallet Typography)
    private var heroHeaderSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(periodHeaderLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
                
                Text(currentBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                Text(account.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            
            Spacer(minLength: 16)
            
            SpendyIconBadge(
                sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                color: themeColor,
                size: .hero,
                style: .circle
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 3. Uncarded SwiftCharts Area Graph & Glass Index Strip
    private var chartSection: some View {
        VStack(spacing: 14) {
            if chartPoints.isEmpty {
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
                        titleFor: { $0.shortLabel }
                    )
                    .onChange(of: selectedPeriod) { _, _ in
                        customDateRange = nil
                        rawSelectedDate = nil
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


    
    // MARK: - 4. Consolidated 4-Metric Account Overview Card
    private var accountOverviewCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Metric 1: Money In
                metricCell(
                    title: "Money In",
                    value: "+\(totalInflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                    icon: "arrow.down.left",
                    iconColor: SpendyColors.incomeGreen
                )
                
                Divider()
                    .overlay(SpendyColors.separator)
                    .frame(height: 44)
                
                // Metric 2: Money Out
                metricCell(
                    title: "Money Out",
                    value: "-\(totalOutflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                    icon: "arrow.up.right",
                    iconColor: SpendyColors.expenseRed
                )
            }
            
            Divider()
                .overlay(SpendyColors.separator)
            
            HStack(spacing: 12) {
                // Metric 3: Daily Average
                metricCell(
                    title: "Daily Average",
                    value: "\(dailyAvgOutflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day",
                    icon: "calendar",
                    iconColor: themeColor
                )
                
                Divider()
                    .overlay(SpendyColors.separator)
                    .frame(height: 44)
                
                // Metric 4: Avg Transaction
                metricCell(
                    title: "Avg Transaction",
                    value: avgTransactionSize.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                    icon: "creditcard",
                    iconColor: Color(hex: "#AF52DE")
                )
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: "#141416"))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
    
    private func metricCell(
        title: String,
        value: String,
        icon: String,
        iconColor: Color
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.16))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Text(value)
                    .spendyNumberFont(size: 16, weight: .bold, tracking: -0.4)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 5. Date-Grouped Recent Activity Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("RECENT ACTIVITY")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(SpendyColors.textTertiary)
                .tracking(1.2)
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
                                        HStack(spacing: 14) {
                                             SpendyIconBadge(
                                                sfSymbol: iconSymbol,
                                                color: iconColor,
                                                size: .medium,
                                                style: .circle
                                            )
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(tx.title.isEmpty ? (cat?.label ?? "Expense") : tx.title)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundStyle(SpendyColors.textPrimary)
                                                
                                                Text(formattedTime(tx.date))
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundStyle(SpendyColors.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(formattedAmount(tx))
                                                .spendyNumberFont(size: 15, weight: .bold, tracking: -0.4)
                                                .foregroundStyle(tx.type == .income ? SpendyColors.incomeGreen : SpendyColors.textPrimary)
                                        }
                                        .padding(14)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if idx < txs.count - 1 {
                                        Divider()
                                            .overlay(SpendyColors.separator)
                                            .padding(.leading, 68)
                                    }
                                }
                            }
                            .background {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(SpendyColors.cardBackground)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Formatters
    private func formattedTime(_ date: Date) -> String {
        AnalyticsChartEngine.formattedTime(date)
    }
    
    private func formattedPointDate(_ date: Date) -> String {
        AnalyticsChartEngine.formattedPointDate(date, period: selectedPeriod)
    }
    
    private func axisLabelDate(_ date: Date) -> String {
        AnalyticsChartEngine.axisLabel(for: date, period: selectedPeriod)
    }
    
    private func formattedAmount(_ tx: Transaction) -> String {
        let sym = store.currencySymbol
        switch tx.type {
        case .expense: return "-\(tx.amount.formattedCurrency(symbol: sym))"
        case .income: return "+\(tx.amount.formattedCurrency(symbol: sym))"
        case .transfer: return "\(tx.amount.formattedCurrency(symbol: sym))"
        }
    }
}


