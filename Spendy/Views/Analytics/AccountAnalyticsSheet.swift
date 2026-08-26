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

// MARK: - Account Category Spend Model
private struct AccountCategorySpend: Identifiable {
    var id: String { category.id }
    let category: Category
    let totalAmount: Double
    let percentage: Double
}

struct AccountAnalyticsSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let account: Account
    var topControlsNamespace: Namespace.ID? = nil
    var onDismiss: (() -> Void)? = nil
    
    @State private var selectedPeriod: ChartPeriod = .month
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var lastInspectedTransaction: Transaction? = nil
    @State private var editingAccountToEdit: Account? = nil
    @State private var rawSelectedDate: Date? = nil
    @State private var showDatePicker: Bool = false
    @Namespace private var accountSheetNamespace
    
    // MARK: - Computed Properties
    private var themeColor: Color {
        account.color
    }
    
    private var allAccountTransactions: [Transaction] {
        store.transactions.filter { $0.accountId == account.id }
            .sorted { $0.date > $1.date }
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
        let bounds = periodBounds
        let components = Calendar.current.dateComponents([.day], from: bounds.start, to: bounds.end)
        return max(1, (components.day ?? 1) + 1)
    }
    
    private var dailyAvgOutflow: Double {
        totalOutflow / Double(daysInSelectedPeriod)
    }
    
    private var avgTransactionSize: Double {
        let expenseTxs = filteredTransactions.filter { $0.type == .expense }
        guard !expenseTxs.isEmpty else { return 0 }
        return totalOutflow / Double(expenseTxs.count)
    }
    
    private var predictiveChartPoints: [CategoryChartPoint] {
        let actuals = chartPoints.filter { !$0.isPredicted }
        guard let lastActual = actuals.last else { return [] }
        let preds = chartPoints.filter { $0.isPredicted }
        guard !preds.isEmpty else { return [] }
        return [lastActual] + preds
    }
    
    private var chartPoints: [CategoryChartPoint] {
        let calendar = Calendar.current
        let bounds = periodBounds
        let txs = filteredTransactions
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let hasEnoughTxs = allAccountTransactions.count >= 5
        
        switch selectedPeriod {
        case .week, .month:
            var points: [CategoryChartPoint] = []
            var current = calendar.startOfDay(for: bounds.start)
            let endDay = calendar.startOfDay(for: bounds.end)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = selectedPeriod == .week ? "EEE" : "d"
            
            let daysInPeriod = max(1, calendar.dateComponents([.day], from: bounds.start, to: min(today, bounds.end)).day ?? 1)
            let actualTxs = txs.filter { $0.date >= bounds.start && $0.date <= min(now, bounds.end) }
            let netTotal = actualTxs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } - actualTxs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let avgDailyNet = daysInPeriod > 0 ? (netTotal / Double(daysInPeriod)) : 0
            
            var cumulativeNet: Double = 0
            
            while current <= endDay {
                let isActual = current <= today
                
                if isActual {
                    let dayStart = current
                    let dayEnd = calendar.date(byAdding: .day, value: 1, to: current)!
                    let dayIn = txs.filter { $0.date >= dayStart && $0.date < dayEnd && $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let dayOut = txs.filter { $0.date >= dayStart && $0.date < dayEnd && $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    let dayNet = dayIn - dayOut
                    
                    cumulativeNet += dayNet
                    points.append(CategoryChartPoint(
                        id: "actual_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: cumulativeNet,
                        isPredicted: false
                    ))
                } else if hasEnoughTxs {
                    let dayOffset = max(1, calendar.dateComponents([.day], from: today, to: current).day ?? 1)
                    let predictedAmount = cumulativeNet + (avgDailyNet * Double(dayOffset))
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
            let actualTxs = txs.filter { $0.date >= bounds.start && $0.date <= min(now, bounds.end) }
            let netTotal = actualTxs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } - actualTxs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let avgMonthlyNet = monthsElapsed > 0 ? (netTotal / Double(monthsElapsed)) : 0
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            
            var cumulativeNet: Double = 0
            
            while current <= endMonth {
                let monthStart = current
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: current)!
                let isActual = current <= now
                
                if isActual {
                    let monthIn = txs.filter { $0.date >= monthStart && $0.date < monthEnd && $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let monthOut = txs.filter { $0.date >= monthStart && $0.date < monthEnd && $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    let monthNet = monthIn - monthOut
                    
                    cumulativeNet += monthNet
                    points.append(CategoryChartPoint(
                        id: "actual_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: cumulativeNet,
                        isPredicted: false
                    ))
                } else if hasEnoughTxs {
                    let monthOffset = max(1, calendar.dateComponents([.month], from: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!, to: current).month ?? 1)
                    let predictedAmount = cumulativeNet + (avgMonthlyNet * Double(monthOffset))
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
            
            // Dynamic Ambient Full-Width Header Glow
            SpendyAmbientHeaderBackground(color: themeColor, height: 380, opacity: 0.34)
            
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 56)
                        
                        // 1. Clean Hero Account Balance Header (Pure Content)
                        heroHeaderSection
                            .padding(.horizontal, 20)
                        
                        // 2. Uncarded SwiftCharts Area Graph & Glass Index Strip
                        chartSection
                            .padding(.horizontal, 16)
                        
                        // 3. Consolidated 4-Metric Account Overview Card
                        accountOverviewCard
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        
                        // 4. Date-Grouped Account Activity List
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
        .sheet(item: $editingAccountToEdit) { acc in
            AddAccountSheet(accountToEdit: acc)
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
    
    // MARK: - 1. Floating Header Bar
    private var headerBar: some View {
        HStack {
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: .white,
                accessibilityLabel: "Back",
                morphID: "backButton",
                namespace: accountSheetNamespace
            ) {
                HapticsManager.shared.trigger(.selection)
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }
            .optionalMatchedGeometry(id: "topControl_left", in: topControlsNamespace)
            
            Spacer()
            
            // Top-Right Glass Edit Account Button
            GlassCircleButton(
                icon: "pencil",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: .white,
                accessibilityLabel: "Edit Account",
                morphID: "editButton",
                namespace: accountSheetNamespace
            ) {
                HapticsManager.shared.trigger(.light)
                editingAccountToEdit = account
            }
            .optionalMatchedGeometry(id: "topControl_right", in: topControlsNamespace)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 2. Hero Header Section (Clean Apple Wallet Typography)
    private var heroHeaderSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(periodHeaderLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
                
                Text(currentBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 38, weight: .heavy, design: .rounded).monospacedDigit())
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
                    
                    // 3. Predictive Continuous Dashed Forecast Curve & Area (when >= 5 transactions)
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
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(ChartPeriod.allCases) { period in
                        let isSelected = selectedPeriod == period
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                                selectedPeriod = period
                                rawSelectedDate = nil
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
                                        if #available(iOS 26, *) {
                                            Capsule()
                                                .fill(Color.white.opacity(0.20))
                                                .glassEffect(.regular.interactive(), in: .capsule)
                                                .glassEffectID("activePeriodPill", in: accountSheetNamespace)
                                        } else {
                                            Capsule()
                                                .fill(Color.white.opacity(0.20))
                                                .matchedGeometryEffect(id: "activePeriodPill", in: accountSheetNamespace)
                                        }
                                    }
                                }
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .nativeLiquidGlassCapsule(isInteractive: true)
                .glassMorphID("periodCapsule", in: accountSheetNamespace)
                
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
                        .glassMorphID("calendarButton", in: accountSheetNamespace)
                }
                .buttonStyle(.plain)
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
                    .font(.system(size: 16, weight: .bold, design: .rounded))
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
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
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
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
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
                                    .fill(Color(hex: "#141416"))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
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
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: date)
    }
    
    private func formattedPointDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        if selectedPeriod == .week || selectedPeriod == .month {
            fmt.dateFormat = "d MMM"
        } else {
            fmt.dateFormat = "MMM yyyy"
        }
        return fmt.string(from: date)
    }
    
    private func axisLabelDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        switch selectedPeriod {
        case .week: fmt.dateFormat = "EEE"
        case .month: fmt.dateFormat = "d MMM"
        case .threeMonths, .sixMonths: fmt.dateFormat = "MMM"
        case .year: fmt.dateFormat = "MMM yy"
        }
        return fmt.string(from: date)
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

// MARK: - Optional Matched Geometry Extension
extension View {
    @ViewBuilder
    func optionalMatchedGeometry(id: String, in namespace: Namespace.ID?) -> some View {
        if let namespace = namespace {
            self.matchedGeometryEffect(id: id, in: namespace)
        } else {
            self
        }
    }
}
