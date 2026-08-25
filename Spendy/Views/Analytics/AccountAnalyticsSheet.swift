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
    
    // MARK: - Computed Properties
    private var themeColor: Color {
        let labelLower = account.label.lowercased()
        if labelLower.contains("revolut") {
            return Color(hex: "#5E5CE6")
        } else if labelLower.contains("chime") {
            return Color(hex: "#30D158")
        } else if labelLower.contains("sbi") {
            return Color(hex: "#007AFF")
        } else if labelLower.contains("canara") {
            return Color(hex: "#0A84FF")
        } else if labelLower.contains("cash") || labelLower.contains("wallet") {
            return Color(hex: "#34C759")
        } else {
            return Color(hex: account.colorHex)
        }
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
    
    private var historicalChartPoints: [CategoryChartPoint] {
        let calendar = Calendar.current
        let bounds = periodBounds
        let txs = filteredTransactions
        
        switch selectedPeriod {
        case .week, .month:
            var points: [CategoryChartPoint] = []
            var current = calendar.startOfDay(for: bounds.start)
            let endDay = calendar.startOfDay(for: bounds.end)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = selectedPeriod == .week ? "EEE" : "d"
            
            while current <= endDay {
                let dayStart = current
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: current)!
                let dayIn = txs.filter { $0.date >= dayStart && $0.date < dayEnd && $0.type == .income }.reduce(0) { $0 + $1.amount }
                let dayOut = txs.filter { $0.date >= dayStart && $0.date < dayEnd && $0.type == .expense }.reduce(0) { $0 + $1.amount }
                let dayNet = dayIn - dayOut
                
                points.append(CategoryChartPoint(
                    date: current,
                    label: dateFormatter.string(from: current),
                    amount: dayNet
                ))
                current = dayEnd
            }
            return points
            
        case .threeMonths, .sixMonths, .year:
            var points: [CategoryChartPoint] = []
            var current = calendar.date(from: calendar.dateComponents([.year, .month], from: bounds.start))!
            let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: bounds.end))!
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            
            while current <= endMonth {
                let monthStart = current
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: current)!
                let monthIn = txs.filter { $0.date >= monthStart && $0.date < monthEnd && $0.type == .income }.reduce(0) { $0 + $1.amount }
                let monthOut = txs.filter { $0.date >= monthStart && $0.date < monthEnd && $0.type == .expense }.reduce(0) { $0 + $1.amount }
                let monthNet = monthIn - monthOut
                
                points.append(CategoryChartPoint(
                    date: current,
                    label: dateFormatter.string(from: current),
                    amount: monthNet
                ))
                current = monthEnd
            }
            return points
        }
    }
    
    private var chartPoints: [CategoryChartPoint] {
        let calendar = Calendar.current
        let bounds = periodBounds
        let txs = filteredTransactions
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
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
            let avgDailyNet = netTotal / Double(daysInPeriod)
            let hasEnoughTxs = allAccountTransactions.count >= 5
            
            var lastActualAmount: Double = 0
            
            while current <= endDay {
                let isActual = current <= today
                
                if isActual {
                    let dayStart = current
                    let dayEnd = calendar.date(byAdding: .day, value: 1, to: current)!
                    let dayIn = txs.filter { $0.date >= dayStart && $0.date < dayEnd && $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let dayOut = txs.filter { $0.date >= dayStart && $0.date < dayEnd && $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    let dayNet = dayIn - dayOut
                    
                    lastActualAmount = dayNet
                    points.append(CategoryChartPoint(
                        id: "actual_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: dayNet,
                        isPredicted: false
                    ))
                } else if hasEnoughTxs {
                    let dayOffset = calendar.dateComponents([.day], from: today, to: current).day ?? 1
                    let predictedAmount = lastActualAmount + (avgDailyNet * Double(dayOffset) * 0.15)
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
            
            let hasEnoughTxs = allAccountTransactions.count >= 5
            var lastActualAmount: Double = 0
            let monthsElapsed = max(1, calendar.dateComponents([.month], from: bounds.start, to: min(now, bounds.end)).month ?? 1)
            let actualTxs = txs.filter { $0.date >= bounds.start && $0.date <= min(now, bounds.end) }
            let netTotal = actualTxs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } - actualTxs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let avgMonthlyNet = netTotal / Double(monthsElapsed)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            
            while current <= endMonth {
                let monthStart = current
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: current)!
                let isActual = current <= now
                
                if isActual {
                    let monthIn = txs.filter { $0.date >= monthStart && $0.date < monthEnd && $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let monthOut = txs.filter { $0.date >= monthStart && $0.date < monthEnd && $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    let monthNet = monthIn - monthOut
                    
                    lastActualAmount = monthNet
                    points.append(CategoryChartPoint(
                        id: "actual_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: monthNet,
                        isPredicted: false
                    ))
                } else if hasEnoughTxs {
                    let monthOffset = calendar.dateComponents([.month], from: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!, to: current).month ?? 1
                    let predictedAmount = lastActualAmount + (avgMonthlyNet * Double(monthOffset) * 0.10)
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
            
            // Dynamic Ambient Radial Gradient Glow
            VStack {
                RadialGradient(
                    colors: [
                        themeColor.opacity(0.38),
                        themeColor.opacity(0.12),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .frame(height: 420)
                .blur(radius: 25)
                .ignoresSafeArea()
                Spacer()
            }
            
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
            .optionalMatchedGeometry(id: "topControl_left", in: topControlsNamespace)
            
            Spacer()
            
            // Account Badge & Name in Center
            HStack(spacing: 8) {
                SpendyIconBadge(
                    sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                    color: themeColor,
                    size: .small
                )
                
                Text(account.label)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            .optionalMatchedGeometry(id: "topControl_center", in: topControlsNamespace)
            
            Spacer()
            
            // Top-Right Glass Edit Account Button
            GlassCircleButton(
                icon: "pencil",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: .white,
                accessibilityLabel: "Edit Account"
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
        VStack(spacing: 4) {
            Text(currentBalance.formattedCurrency(symbol: store.currencySymbol))
                .font(.system(size: 40, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(SpendyColors.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 3. Uncarded SwiftCharts Area Graph & Glass Index Strip
    private var chartSection: some View {
        VStack(spacing: 16) {
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
                    // 1. Actual Area Gradient below curve
                    ForEach(chartPoints.filter { !$0.isPredicted }) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeColor.opacity(0.48), themeColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    
                    // 2. Actual Solid Line Curve
                    ForEach(chartPoints.filter { !$0.isPredicted }) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(themeColor)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                    }
                    
                    // 3. Predictive Dotted Points for Future Days (React Expense App Style)
                    ForEach(chartPoints.filter { $0.isPredicted }) { point in
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .symbol {
                            Circle()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: 4, height: 4)
                        }
                    }
                    
                    // 5. Clean White Endpoint Dot at Today
                    if let lastActual = chartPoints.filter({ !$0.isPredicted }).last {
                        PointMark(
                            x: .value("Date", lastActual.date),
                            y: .value("Amount", lastActual.amount)
                        )
                        .symbol {
                            ZStack {
                                Circle()
                                    .fill(themeColor)
                                    .frame(width: 10, height: 10)
                                    .shadow(color: themeColor, radius: 6)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 5, height: 5)
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
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 180)
                .padding(.horizontal, 4)
            }
            
            // Glass Index Selector Pill Strip
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    ForEach(ChartPeriod.allCases) { period in
                        let isSelected = selectedPeriod == period
                        Button {
                            selectedPeriod = period
                            rawSelectedDate = nil
                            HapticsManager.shared.trigger(.selection)
                        } label: {
                            Text(period.shortLabel)
                                .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                                .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background {
                                    if isSelected {
                                        Capsule()
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                )
                Spacer()
            }
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
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
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
                                    
                                    Button(action: {
                                        HapticsManager.shared.trigger(.selection)
                                        inspectingTransaction = tx
                                    }) {
                                        HStack(spacing: 14) {
                                            SpendyIconBadge(
                                                sfSymbol: cat?.sfSymbol ?? "cart.fill",
                                                color: Color(hex: cat?.colorHex ?? "#34C759"),
                                                size: .medium
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
