//
//  AccountAnalyticsSheet.swift
//  Spendy
//
//  Dedicated Account Analytics Sheet with Centered Hero Balance,
//  SwiftCharts Area Graph directly on Content Layer, Glass Index Pill Selector,
//  2x2 Bento Stat Cards Grid, Account Edit Drawer Sheet Integration,
//  and TransactionDetailSheet Drawer Integration.
//

import SwiftUI
import Charts

struct AccountAnalyticsSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let account: Account
    var topControlsNamespace: Namespace.ID? = nil
    var onDismiss: (() -> Void)? = nil
    
    @State private var selectedPeriod: ChartPeriod = .month
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var editingAccountToEdit: Account? = nil
    
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
        case .all:
            let earliest = allAccountTransactions.map(\.date).min() ?? now
            return (earliest, now)
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
    
    private var comparisonText: String? {
        if netFlow > 0 {
            return "+\(netFlow.formattedCurrency(symbol: store.currencySymbol)) net inflow"
        } else if netFlow < 0 {
            return "\(netFlow.formattedCurrency(symbol: store.currencySymbol)) net outflow"
        } else {
            return nil
        }
    }
    
    private var comparisonColor: Color {
        if netFlow > 0 {
            return SpendyColors.incomeGreen
        } else if netFlow < 0 {
            return SpendyColors.expenseRed
        } else {
            return SpendyColors.textTertiary
        }
    }
    
    private var chartPoints: [CategoryChartPoint] {
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
            
        case .threeMonths, .sixMonths, .year, .all:
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
    
    var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()
            
            // Dynamic Ambient Radial Gradient Glow
            VStack {
                RadialGradient(
                    colors: [
                        themeColor.opacity(0.35),
                        themeColor.opacity(0.15),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 360
                )
                .frame(height: 380)
                .blur(radius: 20)
                .ignoresSafeArea()
                Spacer()
            }
            
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 56)
                        
                        // 1. Centered Hero Account Balance Header
                        heroHeaderSection
                            .padding(.horizontal, 20)
                        
                        // 2. Uncarded SwiftCharts Area Graph & Glass Index Strip
                        chartSection
                            .padding(.horizontal, 16)
                        
                        // 3. 2x2 Bento Stat Cards Grid
                        bentoGridSection
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        
                        // 4. Date-Grouped Account Activity List
                        transactionsSection
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
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
                editingTransaction = txToEdit
            }
        }
        .sheet(item: $editingTransaction) { tx in
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
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(themeColor)
                        .frame(width: 26, height: 26)
                    
                    Text(account.label.prefix(1).uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                
                Text(account.label)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            .optionalMatchedGeometry(id: "topControl_center", in: topControlsNamespace)
            
            Spacer()
            
            // Top-Right Glass Edit Account Toggle Button (Opens Edit Account Drawer)
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
    
    // MARK: - 2. Hero Header Section (Centered, Camel Case Title, Clean layout)
    private var heroHeaderSection: some View {
        VStack(spacing: 6) {
            Text("Account Balance")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
            
            Text(currentBalance.formattedCurrency(symbol: store.currencySymbol))
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            
            if let compText = comparisonText {
                Text(compText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(comparisonColor)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 3. Uncarded SwiftCharts Area Graph & Index Strip
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
                    ForEach(chartPoints) { point in
                        AreaMark(
                            x: .value("Date", point.label),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeColor.opacity(0.45), themeColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Date", point.label),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(themeColor)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                    }
                    
                    if let lastPoint = chartPoints.last, lastPoint.amount != 0 {
                        PointMark(
                            x: .value("Date", lastPoint.label),
                            y: .value("Amount", lastPoint.amount)
                        )
                        .symbol {
                            ZStack {
                                Circle()
                                    .fill(themeColor)
                                    .frame(width: 12, height: 12)
                                    .shadow(color: themeColor, radius: 6)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        if let labelStr = value.as(String.self) {
                            if selectedPeriod == .month {
                                if let day = Int(labelStr), [1, 6, 11, 16, 21, 26, 31].contains(day) {
                                    AxisValueLabel()
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(SpendyColors.textTertiary)
                                }
                            } else {
                                AxisValueLabel()
                                    .font(.system(size: 10, weight: .medium))
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
                            withAnimation(.spring(response: 0.25)) {
                                selectedPeriod = period
                                HapticsManager.shared.trigger(.selection)
                            }
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
    
    // MARK: - 4. 2x2 Bento Grid Section (Matching Attached Screenshot)
    private var bentoGridSection: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            // Card 1: Net Cashflow (Matching screenshot)
            statGridCard(
                title: "Net Cashflow",
                value: netFlow.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                footerText: netFlow >= 0 ? "Positive cashflow" : "Negative cashflow",
                icon: netFlow >= 0 ? "arrow.up.right" : "arrow.down.right",
                iconBgColor: netFlow >= 0 ? Color.white : SpendyColors.expenseRed
            )
            
            // Card 2: Activity Count (Matching screenshot)
            statGridCard(
                title: "Activity",
                value: "\(filteredTransactions.count)",
                footerText: "transactions logged",
                icon: "square.stack.3d.up.fill",
                iconBgColor: themeColor
            )
            
            // Card 3: Total Inflow
            statGridCard(
                title: "Total Inflow",
                value: "+\(totalInflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                footerText: "Income added",
                icon: "arrow.down.left",
                iconBgColor: SpendyColors.incomeGreen
            )
            
            // Card 4: Total Outflow
            statGridCard(
                title: "Total Outflow",
                value: "-\(totalOutflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                footerText: "Expenses paid",
                icon: "arrow.up.right",
                iconBgColor: SpendyColors.expenseRed
            )
        }
    }
    
    private func statGridCard(
        title: String,
        value: String,
        footerText: String,
        icon: String,
        iconBgColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Spacer(minLength: 8)
            
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconBgColor)
                        .frame(width: 26, height: 26)
                        .shadow(color: iconBgColor.opacity(0.4), radius: 4, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(iconBgColor == Color.white ? Color.black : Color.white)
                }
                
                Text(footerText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - 5. Date-Grouped Recent Activity Section
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
                            HStack {
                                Text(dateGroup)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(SpendyColors.textSecondary)
                                
                                Spacer()
                                
                                Text(dayTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                    .font(.system(size: 12, weight: .bold))
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
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: cat?.colorHex ?? "#34C759"))
                                                    .frame(width: 40, height: 40)
                                                
                                                Image(systemName: cat?.sfSymbol ?? "cart.fill")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(Color.white)
                                            }
                                            
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
                                                .font(.system(size: 15, weight: .bold))
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
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(SpendyColors.cardBackground)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
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
