//
//  DashboardView.swift
//  Spendy
//
//  Artistic Gen-Z Finance Hub inspired by modern athletic minimalist UI:
//  Electric Cobalt Canvas Top with 7-Day Vertical Capsule Bars,
//  Massive Rounded Centerpiece Card (38pt corner radius),
//  Segmented Time Filter (D, W, M), 3-Column Metric Row,
//  Tactile 3-Mode Floating Pill Selector, and Retained Monthly Cashflow Card.
//

import SwiftUI
import Charts

// MARK: - Helper Model for Smart Insight Cards
struct InsightCardViewModel: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let value: String
    let subtitle: String
    var categoryId: String? = nil
    var family: String? = nil
}

// MARK: - Trend Graph Point
struct SpendTrendPoint: Identifiable, Equatable {
    let id: Int
    let label: String
    let amount: Double
}

// MARK: - Inline Hero Spend Trend Curve Graph
struct HeroSpendTrendGraph: View {
    let points: [SpendTrendPoint]
    let filter: DashboardTimeFilter
    
    var body: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                let amounts = points.map { $0.amount }
                let maxAmount = max(1.0, amounts.max() ?? 1.0)
                let count = max(1, points.count)
                
                let coords: [CGPoint] = points.enumerated().map { index, point in
                    let x = count > 1 ? (CGFloat(index) / CGFloat(count - 1)) * w : w / 2
                    let normalized = CGFloat(point.amount / maxAmount)
                    let y = h - (normalized * (h - 14) + 7)
                    return CGPoint(x: x, y: y)
                }
                
                ZStack {
                    // Soft Area Gradient Fill Under Curve
                    Path { path in
                        guard coords.count > 1 else { return }
                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: coords[0])
                        
                        for i in 1..<coords.count {
                            let prev = coords[i - 1]
                            let cur = coords[i]
                            let midX = (prev.x + cur.x) / 2
                            path.addCurve(
                                to: cur,
                                control1: CGPoint(x: midX, y: prev.y),
                                control2: CGPoint(x: midX, y: cur.y)
                            )
                        }
                        
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                SpendyColors.electricCobalt.opacity(0.18),
                                SpendyColors.electricCobalt.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Smooth Glowing Curve Stroke
                    Path { path in
                        guard coords.count > 1 else { return }
                        path.move(to: coords[0])
                        for i in 1..<coords.count {
                            let prev = coords[i - 1]
                            let cur = coords[i]
                            let midX = (prev.x + cur.x) / 2
                            path.addCurve(
                                to: cur,
                                control1: CGPoint(x: midX, y: prev.y),
                                control2: CGPoint(x: midX, y: cur.y)
                            )
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                SpendyColors.electricCobalt.opacity(0.45),
                                SpendyColors.electricCobalt
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round)
                    )
                    
                    // Glowing Pin on the Latest / Peak Point
                    if let last = coords.last {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle().stroke(SpendyColors.electricCobalt, lineWidth: 2.5)
                            )
                            .shadow(color: SpendyColors.electricCobalt.opacity(0.7), radius: 5, x: 0, y: 0)
                            .position(last)
                    }
                }
            }
            .frame(height: 46)
            
            // Minimal Axis Indicators
            HStack {
                if let first = points.first {
                    Text(first.label)
                }
                Spacer()
                if points.count > 2 {
                    Text(points[points.count / 2].label)
                }
                Spacer()
                if let last = points.last {
                    Text(last.label)
                }
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color.gray.opacity(0.75))
            .padding(.horizontal, 2)
        }
    }
}

// MARK: - Time Filter Enum (D, W, M)
enum DashboardTimeFilter: String, CaseIterable, Identifiable {
    case day = "D"
    case week = "W"
    case month = "M"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        }
    }
}



// MARK: - Mini Sparkline Component for Accounts Card
struct AccountsMiniSparkline: View {
    var isPositive: Bool = true
    
    var effectiveColor: Color {
        isPositive ? Color(hex: "#30D158") : Color(hex: "#FF453A")
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let col = effectiveColor
            
            ZStack(alignment: .bottomTrailing) {
                Path { path in
                    if isPositive {
                        path.move(to: CGPoint(x: 0, y: h * 0.75))
                        path.addCurve(
                            to: CGPoint(x: w * 0.65, y: h * 0.70),
                            control1: CGPoint(x: w * 0.20, y: h * 0.75),
                            control2: CGPoint(x: w * 0.45, y: h * 0.72)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: w, y: h * 0.08),
                            control: CGPoint(x: w * 0.85, y: h * 0.60)
                        )
                    } else {
                        path.move(to: CGPoint(x: 0, y: h * 0.12))
                        path.addCurve(
                            to: CGPoint(x: w * 0.60, y: h * 0.18),
                            control1: CGPoint(x: w * 0.20, y: h * 0.12),
                            control2: CGPoint(x: w * 0.40, y: h * 0.15)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: w, y: h * 0.88),
                            control: CGPoint(x: w * 0.80, y: h * 0.35)
                        )
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [col.opacity(0.30), col.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Path { path in
                    if isPositive {
                        path.move(to: CGPoint(x: 0, y: h * 0.75))
                        path.addCurve(
                            to: CGPoint(x: w * 0.65, y: h * 0.70),
                            control1: CGPoint(x: w * 0.20, y: h * 0.75),
                            control2: CGPoint(x: w * 0.45, y: h * 0.72)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: w, y: h * 0.08),
                            control: CGPoint(x: w * 0.85, y: h * 0.60)
                        )
                    } else {
                        path.move(to: CGPoint(x: 0, y: h * 0.12))
                        path.addCurve(
                            to: CGPoint(x: w * 0.60, y: h * 0.18),
                            control1: CGPoint(x: w * 0.20, y: h * 0.12),
                            control2: CGPoint(x: w * 0.40, y: h * 0.15)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: w, y: h * 0.88),
                            control: CGPoint(x: w * 0.80, y: h * 0.35)
                        )
                    }
                }
                .stroke(col, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Main Dashboard View
struct DashboardView: View {
    @Environment(ExpenseStore.self) private var store
    @Binding var showAddTransaction: Bool
    var selectedTab: Binding<AppTab>? = nil
    
    // Sheets & Modal State
    @State private var showSettings: Bool = false
    @State private var settingsInitialDestination: SettingsDestination? = nil
    @State private var showCurrencyConverter: Bool = false
    @State private var showReceiptPrinter: Bool = false
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var lastInspectedTransaction: Transaction? = nil
    @State private var selectedCategoryForSheet: Category? = nil
    @State private var selectedAccountForSheet: Account? = nil
    @State private var showAccountsHub: Bool = false
    
    // Interactive Time Filter (D, W, M)
    @State private var selectedTimeFilter: DashboardTimeFilter = .month
    
    // Filter & Privacy State
    @State private var selectedAccountId: String = "all"
    @State private var hideBalance: Bool = false
    @State private var showAllTransactions: Bool = false
    
    @Namespace private var topControlsNamespace
    
    // Dynamic Filtered Data
    private var displayedTransactions: [Transaction] {
        store.filteredTransactions(for: selectedAccountId)
    }
    
    private var visibleTransactions: [Transaction] {
        if showAllTransactions {
            return displayedTransactions
        } else {
            return Array(displayedTransactions.prefix(5))
        }
    }
    
    private var displayedBalance: Double {
        store.filteredBalance(for: selectedAccountId)
    }
    
    private var selectedAccountLabel: String {
        if selectedAccountId == "all" { return "All Accounts" }
        return store.accounts.first(where: { $0.id == selectedAccountId })?.label ?? "Account"
    }
    
    private var selectedAccountSymbol: String {
        if selectedAccountId == "all" { return "wallet.pass.fill" }
        return store.accounts.first(where: { $0.id == selectedAccountId })?.sfSymbol ?? "creditcard.fill"
    }
    
    // Dynamic Spend for D / W / M Filter
    private var filteredSpendAmount: Double {
        let calendar = Calendar.current
        let now = Date()
        let expenses = displayedTransactions.filter { $0.type == .expense }
        
        switch selectedTimeFilter {
        case .day:
            return expenses.filter { calendar.isDateInToday($0.date) }.reduce(0) { $0 + $1.amount }
        case .week:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return 0 }
            return expenses.filter { $0.date >= weekStart }.reduce(0) { $0 + $1.amount }
        case .month:
            return currentMonthExpenseTotal
        }
    }
    
    // Dynamic Inline Trend Curve Data for D / W / M
    private var trendGraphPoints: [SpendTrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        let expenses = displayedTransactions.filter { $0.type == .expense }
        
        switch selectedTimeFilter {
        case .day:
            let todayExpenses = expenses.filter { calendar.isDateInToday($0.date) }
            let hours = [0, 4, 8, 12, 16, 20, 23]
            var points: [SpendTrendPoint] = []
            
            for (idx, hour) in hours.enumerated() {
                let hourTxs = todayExpenses.filter {
                    let h = calendar.component(.hour, from: $0.date)
                    return h <= hour
                }
                let sum = hourTxs.reduce(0.0) { $0 + $1.amount }
                let label = hour == 0 ? "12AM" : (hour == 12 ? "12PM" : (hour > 12 ? "\(hour - 12)PM" : "\(hour)AM"))
                points.append(SpendTrendPoint(id: idx, label: label, amount: sum))
            }
            
            let allZero = points.allSatisfy { $0.amount == 0 }
            if allZero {
                return [
                    SpendTrendPoint(id: 0, label: "12AM", amount: 0),
                    SpendTrendPoint(id: 1, label: "6AM", amount: 0),
                    SpendTrendPoint(id: 2, label: "12PM", amount: 0),
                    SpendTrendPoint(id: 3, label: "6PM", amount: 0),
                    SpendTrendPoint(id: 4, label: "Now", amount: 0)
                ]
            }
            return points
            
        case .week:
            var points: [SpendTrendPoint] = []
            let today = calendar.startOfDay(for: now)
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            
            for offset in (0..<7).reversed() {
                if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                    let dayTxs = expenses.filter { calendar.isDate($0.date, inSameDayAs: date) }
                    let total = dayTxs.reduce(0.0) { $0 + $1.amount }
                    let name = formatter.string(from: date)
                    points.append(SpendTrendPoint(id: 6 - offset, label: name, amount: total))
                }
            }
            return points
            
        case .month:
            let monthTxs = currentMonthExpenseTxs
            let currentDay = calendar.component(.day, from: now)
            let intervals = [
                (1, min(7, currentDay), "W1"),
                (8, min(14, currentDay), "W2"),
                (15, min(21, currentDay), "W3"),
                (22, min(31, currentDay), "W4")
            ]
            
            var points: [SpendTrendPoint] = []
            var cumulative: Double = 0
            for (idx, interval) in intervals.enumerated() {
                if interval.0 <= currentDay {
                    let intTxs = monthTxs.filter {
                        let d = calendar.component(.day, from: $0.date)
                        return d >= interval.0 && d <= interval.1
                    }
                    cumulative += intTxs.reduce(0.0) { $0 + $1.amount }
                }
                points.append(SpendTrendPoint(id: idx, label: interval.2, amount: cumulative))
            }
            return points
        }
    }
    
    private var completedGoalPercentage: Int {
        let incTotal = currentMonthIncomeTxs.reduce(0) { $0 + $1.amount }
        let expTotal = currentMonthExpenseTotal
        guard incTotal > 0 else { return 41 }
        let savings = incTotal - expTotal
        return max(0, min(100, Int((savings / incTotal) * 100)))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // 1. Dynamic Canvas Background framing the centerpiece card
                store.canvasBackgroundColor
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        // 2. Detached Top Capsule Navbar (Uniform 44x44 Circular Buttons)
                        topDetachedPillBar
                            .padding(.top, 4)
                        
                        // 3. Main Centerpiece Sheet Card
                        centerpieceWhiteCard
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
                
                // Floating Currency Converter Drawer Overlay
                if showCurrencyConverter {
                    Color.black.opacity(0.40)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                showCurrencyConverter = false
                            }
                        }
                    
                    GeometryReader { geometry in
                        VStack {
                            FloatingCurrencyConverterView(isPresented: $showCurrencyConverter)
                                .padding(.horizontal, 16)
                                .padding(.top, geometry.safeAreaInsets.top + 50)
                            Spacer()
                        }
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .ignoresSafeArea(edges: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings, onDismiss: {
                settingsInitialDestination = nil
            }) {
                SettingsView(initialDestination: settingsInitialDestination)
                    .presentationBackground(Color(hex: "#1C1C1E"))
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
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
            .sheet(isPresented: $showReceiptPrinter) {
                ReceiptPrinterSheet()
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
            .navigationDestination(item: $selectedCategoryForSheet) { category in
                CategoryAnalyticsSheet(
                    category: category,
                    topControlsNamespace: topControlsNamespace
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedCategoryForSheet = nil
                    }
                }
            }
            .navigationDestination(item: $selectedAccountForSheet) { account in
                AccountAnalyticsSheet(
                    account: account,
                    topControlsNamespace: topControlsNamespace
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedAccountForSheet = nil
                    }
                }
            }
            .navigationDestination(isPresented: $showAccountsHub) {
                AccountsView(topControlsNamespace: topControlsNamespace)
            }
        }
    }
    
    // MARK: - 1. Top Detached Capsule Navbar (Uniform 44x44 Circular Buttons)
    private var topDetachedPillBar: some View {
        HStack(alignment: .center) {
            // Profile Button (44x44 Circle - Opens Settings)
            Button(action: {
                HapticsManager.shared.trigger(.light)
                showSettings = true
            }) {
                ZStack {
                    if let imgData = store.profileImageData, let uiImage = UIImage(data: imgData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else if let symbol = store.profileIconSymbol, !symbol.isEmpty {
                        Circle()
                            .fill(store.cardChipBackground)
                            .frame(width: 44, height: 44)
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(store.cardTextPrimary)
                    } else {
                        Circle()
                            .fill(store.cardChipBackground)
                            .frame(width: 44, height: 44)
                        Text(store.userName.prefix(1).uppercased().isEmpty ? "P" : String(store.userName.prefix(1).uppercased()))
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(store.cardTextPrimary)
                    }
                }
            }
            .buttonStyle(PressableSpringButtonStyle())
            
            Spacer()
            
            // Top Right Action Buttons Group (Receipts, Converter, Privacy Eye - All 44x44 Circles)
            HStack(spacing: 8) {
                // Receipt Printer Button (44x44 Circle)
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    showReceiptPrinter = true
                }) {
                    ZStack {
                        Circle()
                            .fill(store.cardChipBackground)
                            .frame(width: 44, height: 44)
                        Image(systemName: "printer.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(store.cardChipText)
                    }
                }
                .buttonStyle(PressableSpringButtonStyle())
                
                // Currency Converter Button (44x44 Circle)
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        showCurrencyConverter = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(store.cardChipBackground)
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(store.cardChipText)
                    }
                }
                .buttonStyle(PressableSpringButtonStyle())
                
                // Privacy Eye Button (44x44 Circle)
                Button(action: {
                    withAnimation(.spring(response: 0.25)) {
                        hideBalance.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(store.cardChipBackground)
                            .frame(width: 44, height: 44)
                        Image(systemName: hideBalance ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(store.cardChipText)
                    }
                }
                .buttonStyle(PressableSpringButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(store.cardBackgroundColor)
                .overlay(
                    Capsule().stroke(store.cardBorderColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 3)
        }
    }
    
    // MARK: - 2. Centerpiece Sheet Card
    private var centerpieceWhiteCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top Controls Row: Account Selector on Left + D/W/M Segmented Capsule on Right
            HStack(alignment: .center) {
                // Account Selector Dropdown Menu Chip
                Menu {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { selectedAccountId = "all" }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        HStack {
                            Text("All Accounts")
                            if selectedAccountId == "all" { Image(systemName: "checkmark") }
                        }
                    }
                    
                    Divider()
                    
                    ForEach(store.accounts) { acc in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) { selectedAccountId = acc.id }
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            HStack {
                                Text("\(acc.label) (\(store.balance(for: acc.id).formattedCurrency(symbol: store.currencySymbol)))")
                                if selectedAccountId == acc.id { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: selectedAccountSymbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(store.canvasBackgroundColor)
                        
                        Text(selectedAccountLabel)
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundStyle(store.cardTextPrimary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(store.cardTextSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(store.cardChipBackground)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Segmented D / W / M Time Filter Capsule
                HStack(spacing: 3) {
                    ForEach(DashboardTimeFilter.allCases) { filter in
                        Button(action: {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedTimeFilter = filter
                            }
                        }) {
                            Text(filter.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(selectedTimeFilter == filter ? store.cardTextPrimary : store.cardTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background {
                                    if selectedTimeFilter == filter {
                                        Capsule()
                                            .fill(store.isCardDark ? Color(hex: "#3A3A3C") : Color.white)
                                            .shadow(color: Color.black.opacity(0.12), radius: 3, y: 1)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background {
                    Capsule()
                        .fill(store.cardChipBackground)
                }
            }
            
            // Hero Display Amount Section
            heroAmountSection
            
            // 3-Column Metric Breakdown Row (Expenses, Income, Savings)
            threeColumnMetricsRow
            
            Divider()
                .overlay(store.cardDividerColor)
            
            // Retained Monthly Cashflow Split Card (User Loved Feature - Spacious Non-wrapping Layout)
            monthlyCashflowCard
            
            // Budget Health & Pacing Card
            budgetHealthCard
            
            // Smart Insights Section (Horizontal Scroll Carousel)
            smartInsightsSection
            
            // Accounts Unified Card Section
            accountsUnifiedCardSection
            
            // Recent Activity Stream
            recentTransactionsSection
        }
        .padding(20)
        .padding(.bottom, 100) // Extends card background under the floating nav bar
        .background {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(store.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .stroke(store.cardBorderColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 24, y: 8)
        }
    }
    
    // MARK: - 3. Hero Amount Section
    private var heroAmountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(selectedAccountId == "all" ? "TOTAL SPENDING" : "\(selectedAccountLabel.uppercased()) OUTFLOW")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(store.cardTextSecondary)
                
                // Big Bold Optical Display Number
                if hideBalance {
                    Text("\(store.currencySymbol)••••••")
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundStyle(store.cardTextPrimary)
                } else {
                    Text(filteredSpendAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundStyle(store.cardTextPrimary)
                }
                
                Text("\(selectedTimeFilter.label) • Outflow")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(store.cardTextSecondary)
            }
            
            // Inline Spend Trend Curve Graph
            HeroSpendTrendGraph(points: trendGraphPoints, filter: selectedTimeFilter)
                .padding(.top, 4)
                .padding(.bottom, 2)
        }
    }
    
    // MARK: - 4. 3-Column Metric Breakdown Row
    private var threeColumnMetricsRow: some View {
        HStack(spacing: 0) {
            metricColumn(
                value: currentMonthExpenseTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                unit: "Expenses",
                sublabel: "\(currentMonthExpenseTxs.count) txs"
            )
            
            Spacer()
            
            let incTotal = currentMonthIncomeTxs.reduce(0) { $0 + $1.amount }
            metricColumn(
                value: "+\(incTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))",
                unit: "Income",
                sublabel: "\(currentMonthIncomeTxs.count) txs",
                isPositive: true
            )
            
            Spacer()
            
            metricColumn(
                value: "\(completedGoalPercentage)%",
                unit: "Savings Rate",
                sublabel: "\(store.accounts.count) accounts"
            )
        }
        .padding(.vertical, 4)
    }
    
    private func metricColumn(value: String, unit: String, sublabel: String, isPositive: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(hideBalance ? "••••" : value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(isPositive ? Color(hex: "#30D158") : store.cardTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(unit)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(store.cardTextPrimary.opacity(0.85))
            
            Text(sublabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(store.cardTextSecondary)
        }
    }
    
    // MARK: - 5. Retained Monthly Cashflow Split Card (Dark Artistic Contrast Card)
    private var monthlyCashflowCard: some View {
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            if let selectedTab = selectedTab {
                selectedTab.wrappedValue = .analytics
            }
        }) {
            VStack(spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    // Left Column: Spent This Month
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            let expenseBadges = expenseCategoryBadges
                            if !expenseBadges.isEmpty {
                                OverlappingBadgeCluster(
                                    items: expenseBadges.prefix(3).map { info in
                                        BadgeItem(icon: info.icon, color: info.color)
                                    }
                                )
                            } else {
                                SpendyIconBadge(
                                    sfSymbol: "cart.fill",
                                    color: Color(hex: "#FF453A"),
                                    size: .small,
                                    style: .circle
                                )
                            }
                            
                            Text("Expenses")
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.65))
                                .lineLimit(1)
                        }
                        
                        Text(hideBalance ? "••••" : currentMonthExpenseTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                            .font(.system(size: 17.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                        
                        Text("\(currentMonthExpenseTxs.count) this month")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.40))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Vertical Separator
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: 50)
                    
                    // Right Column: Income This Month
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            let incomeBadges = incomeIconInfos
                            if !incomeBadges.isEmpty {
                                OverlappingBadgeCluster(
                                    items: incomeBadges.prefix(3).map { info in
                                        BadgeItem(icon: info.icon, color: info.color)
                                    }
                                )
                            } else {
                                SpendyIconBadge(
                                    sfSymbol: "dollarsign.circle.fill",
                                    color: Color(hex: "#30D158"),
                                    size: .small,
                                    style: .circle
                                )
                            }
                            
                            Text("Income")
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.65))
                                .lineLimit(1)
                        }
                        
                        let incTotal = currentMonthIncomeTxs.reduce(0) { $0 + $1.amount }
                        Text(hideBalance ? "••••" : "+\(incTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                            .font(.system(size: 17.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: "#30D158"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                        
                        Text("\(currentMonthIncomeTxs.count) this month")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.40))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Bottom Cashflow Rate Status Bar
                let incTotal = currentMonthIncomeTxs.reduce(0) { $0 + $1.amount }
                let expTotal = currentMonthExpenseTotal
                let savings = incTotal - expTotal
                let savingsRate = incTotal > 0 ? max(0, min(100, Int((savings / incTotal) * 100))) : 0
                
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: "#30D158"))
                    
                    if incTotal > 0 {
                        Text("\(savingsRate)% Savings Rate · \(savings >= 0 ? "+" : "")\(savings.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) saved")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineLimit(1)
                    } else {
                        Text("\(currentMonthExpenseTxs.count) transactions logged this month")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.40))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(hex: "#141416"))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(PressableSpringButtonStyle())
    }
    
    // MARK: - 5. Budget Health & Pacing Card
    private var budgetHealthCard: some View {
        let budget = store.budget
        let target = store.budgetTargetAmount(for: budget.period)
        let spent = store.budgetCycleExpenses
        let isConfigured = budget.isActive && target > 0
        let percentSpent = isConfigured ? (spent / target) : 0.0
        let isExceeded = spent > target && isConfigured
        let remaining = max(0, target - spent)
        let overAmount = max(0, spent - target)
        
        let statusColor: Color = {
            if !isConfigured { return SpendyColors.primaryBlue }
            if isExceeded { return Color(hex: "#FF453A") }
            if percentSpent >= 0.85 { return Color(hex: "#FF9F0A") }
            return Color(hex: "#30D158")
        }()
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            if let selectedTab = selectedTab {
                selectedTab.wrappedValue = .budget
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(store.cardTextPrimary.opacity(0.08), lineWidth: 3.8)
                        .frame(width: 44, height: 44)
                    
                    if isConfigured {
                        Circle()
                            .trim(from: 0.0, to: min(1.0, CGFloat(percentSpent)))
                            .stroke(
                                statusColor,
                                style: StrokeStyle(lineWidth: 3.8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 44, height: 44)
                        
                        Text("\(Int(min(999, percentSpent * 100)))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(store.cardTextPrimary)
                    } else {
                        Image(systemName: "target")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(store.canvasBackgroundColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    if !isConfigured {
                        Text("Plan Monthly Budget")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(store.cardTextPrimary)
                        
                        Text("Track real-time pacing and safe daily spend")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(store.cardTextSecondary)
                            .lineLimit(1)
                    } else if isExceeded {
                        Text("Budget exceeded by \(hideBalance ? "••••" : overAmount.formattedCurrency(symbol: store.currencySymbol))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(hex: "#FF453A"))
                        
                        Text("Spent \(hideBalance ? "••••" : spent.formattedCurrency(symbol: store.currencySymbol)) of \(target.formattedCurrency(symbol: store.currencySymbol)) limit")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(store.cardTextSecondary)
                            .lineLimit(1)
                    } else {
                        Text("\(hideBalance ? "••••" : remaining.formattedCurrency(symbol: store.currencySymbol)) available")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(store.cardTextPrimary)
                        
                        let daysLeft = store.budgetDaysLeft
                        let dailySafe = store.safeDailyAllowance
                        Text("Safe daily allowance: \(hideBalance ? "••••" : dailySafe.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day · \(daysLeft)d left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(store.cardTextSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(store.cardTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(store.cardChipBackground)
            }
        }
        .buttonStyle(PressableSpringButtonStyle())
    }
    
    // MARK: - 6. Smart Insights Carousel
    private var smartInsightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(store.canvasBackgroundColor)
                Text("Smart Insights")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(store.cardTextPrimary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(allDashboardInsightCards) { insight in
                        SharedInsightCard(
                            title: insight.title,
                            value: insight.value,
                            subtitle: insight.subtitle,
                            icon: insight.icon,
                            color: insight.color,
                            action: {
                                if let catId = insight.categoryId,
                                   let cat = store.categories.first(where: { $0.id == catId }) {
                                    selectedCategoryForSheet = cat
                                } else if insight.family == "budget" || insight.id == "set_budget" {
                                    if let selectedTab = selectedTab {
                                        selectedTab.wrappedValue = .budget
                                    }
                                } else if insight.family == "subscription" {
                                    if let selectedTab = selectedTab {
                                        selectedTab.wrappedValue = .manage
                                    }
                                } else if insight.family == "onboarding" {
                                    showAddTransaction = true
                                } else if insight.family == "analytics" {
                                    if let selectedTab = selectedTab {
                                        selectedTab.wrappedValue = .analytics
                                    }
                                }
                            }
                        )
                        .frame(width: 175)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    // MARK: - 7. Accounts Unified Card Section
    private var accountsUnifiedCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                showAccountsHub = true
            }) {
                HStack {
                    Text("Accounts")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(store.cardTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(store.cardTextSecondary)
                }
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 14) {
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    showAccountsHub = true
                }) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Balance")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(store.cardTextSecondary)
                            
                            Text(hideBalance ? "••••••" : store.totalBalance.formattedCurrency(symbol: store.currencySymbol))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(store.cardTextPrimary)
                        }
                        
                        Spacer()
                        
                        let isPositiveTrend = store.netWorthChangePercentage >= 0
                        AccountsMiniSparkline(isPositive: isPositiveTrend)
                            .frame(width: 100, height: 36)
                    }
                }
                .buttonStyle(.plain)
                
                Divider()
                    .overlay(store.cardDividerColor)
                
                VStack(spacing: 14) {
                    ForEach(store.accounts) { acc in
                        let bal = store.balance(for: acc.id)
                        
                        Button(action: {
                            HapticsManager.shared.trigger(.selection)
                            selectedAccountForSheet = acc
                        }) {
                            HStack(spacing: 14) {
                                SpendyIconBadge(
                                    sfSymbol: acc.sfSymbol.isEmpty ? acc.type.defaultSymbol : acc.sfSymbol,
                                    color: acc.color,
                                    size: .medium,
                                    style: .circle
                                )
                                
                                Text(acc.label)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(store.cardTextPrimary)
                                
                                Spacer()
                                
                                Text(hideBalance ? "••••" : bal.formattedCurrency(symbol: store.currencySymbol))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(store.cardTextPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(store.cardChipBackground)
            }
        }
    }
    
    // MARK: - 8. Recent Activity Section
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(store.cardTextPrimary)
                
                Spacer()
                
                if !displayedTransactions.isEmpty {
                    Text("\(displayedTransactions.count) items")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(store.cardTextSecondary)
                }
            }
            
            VStack(spacing: 14) {
                if displayedTransactions.isEmpty {
                    emptyRecentActivityView
                } else {
                    ForEach(Array(visibleTransactions.enumerated()), id: \.element.id) { index, tx in
                        transactionRow(tx)
                        
                        if index < visibleTransactions.count - 1 {
                            Divider()
                                .overlay(store.cardDividerColor)
                        }
                    }
                    
                    if displayedTransactions.count > 5 {
                        Divider()
                            .overlay(store.cardDividerColor)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showAllTransactions.toggle()
                            }
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            HStack {
                                Text(showAllTransactions ? "Show less" : "All transactions (\(displayedTransactions.count))")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(store.cardTextPrimary)
                                
                                Spacer()
                                
                                Image(systemName: showAllTransactions ? "chevron.up" : "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(store.cardTextSecondary)
                            }
                            .padding(.top, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(store.cardChipBackground)
            }
        }
    }
    
    private func transactionRow(_ tx: Transaction) -> some View {
        let cat = store.categories.first(where: { $0.id == tx.categoryId })
        let acc = store.accounts.first(where: { $0.id == tx.accountId })
        let subscription = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == tx.subscriptionId?.lowercased() })
        
        let iconSymbol = subscription?.sfSymbol ?? (cat?.sfSymbol ?? "cart.fill")
        let iconColor = subscription?.color ?? (cat?.color ?? Color(hex: "#34C759"))
        
        return Button(action: {
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
                        .foregroundStyle(store.cardTextPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        if let acc = acc {
                            HStack(spacing: 4) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(acc.color)
                                        .frame(width: 14, height: 14)
                                    Image(systemName: acc.sfSymbol.isEmpty ? acc.type.defaultSymbol : acc.sfSymbol)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                
                                Text(acc.label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(store.cardTextSecondary)
                            }
                        }
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(store.cardTextSecondary.opacity(0.6))
                        
                        Text(tx.date.formattedRelative)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(store.cardTextSecondary)
                    }
                }
                
                Spacer()
                
                Text(formattedRowAmount(tx))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tx.type == .income ? Color(hex: "#30D158") : store.cardTextPrimary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
    
    private func formattedRowAmount(_ tx: Transaction) -> String {
        if hideBalance { return "••••" }
        let sym = store.currencySymbol
        switch tx.type {
        case .expense: return "-\(tx.amount.formattedCurrency(symbol: sym))"
        case .income: return "+\(tx.amount.formattedCurrency(symbol: sym))"
        case .transfer: return "\(tx.amount.formattedCurrency(symbol: sym))"
        }
    }
    
    private var emptyRecentActivityView: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray.fill")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.gray)
                .padding(.top, 8)
            
            Text("No transactions logged yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black)
            
            Text("Tap + to add your first transaction.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - Computed Properties for Insight Cards & Badges
    private var allDashboardInsightCards: [InsightCardViewModel] {
        var cards: [InsightCardViewModel] = []
        let totalExpense = currentMonthExpenseTotal
        let expTxs = currentMonthExpenseTxs
        
        if !expTxs.isEmpty {
            var catTotals: [String: (total: Double, count: Int)] = [:]
            for tx in expTxs {
                let cur = catTotals[tx.categoryId, default: (0.0, 0)]
                catTotals[tx.categoryId] = (cur.total + tx.amount, cur.count + 1)
            }
            if let topEntry = catTotals.max(by: { $0.value.total < $1.value.total }),
               let topCat = store.categories.first(where: { $0.id == topEntry.key }) {
                let catPct = totalExpense > 0 ? Int((topEntry.value.total / totalExpense) * 100) : 0
                cards.append(
                    InsightCardViewModel(
                        id: "top_category_\(topCat.id)",
                        title: topCat.label,
                        icon: topCat.sfSymbol,
                        color: Color(hex: topCat.colorHex),
                        value: hideBalance ? "••••" : topEntry.value.total.formattedCurrency(symbol: store.currencySymbol, decimals: 0),
                        subtitle: "\(topEntry.value.count) \(topEntry.value.count == 1 ? "expense" : "expenses") · \(catPct)% of spend",
                        categoryId: topCat.id,
                        family: "category"
                    )
                )
            }
        }
        
        if store.budget.isActive && store.budgetTargetAmount(for: store.budget.period) > 0 {
            let budgetTarget = store.budgetTargetAmount(for: store.budget.period)
            let spent = store.budgetCycleExpenses
            let isOver = spent > budgetTarget
            
            cards.append(
                InsightCardViewModel(
                    id: "safe_daily",
                    title: "Daily Allowance",
                    icon: isOver ? "exclamationmark.shield.fill" : "shield.lefthalf.filled",
                    color: isOver ? Color(hex: "#FF453A") : Color(hex: "#30D158"),
                    value: hideBalance ? "••••" : "\(store.safeDailyAllowance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day",
                    subtitle: isOver ? "Budget exceeded · Restrict daily spend" : "\(store.budgetDaysLeft) days remaining in cycle",
                    family: "budget"
                )
            )
        }
        
        return cards
    }
    
    private var currentMonthExpenseTxs: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return displayedTransactions.filter {
            $0.type == .expense &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
    }
    
    private var currentMonthExpenseTotal: Double {
        currentMonthExpenseTxs.reduce(0) { $0 + $1.amount }
    }
    
    private var expenseCategoryBadges: [(icon: String, color: Color)] {
        var totals: [String: Double] = [:]
        for tx in currentMonthExpenseTxs {
            totals[tx.categoryId, default: 0] += tx.amount
        }
        let sorted = totals.sorted(by: { $0.value > $1.value })
        return sorted.prefix(3).compactMap { (catId, _) in
            guard let cat = store.categories.first(where: { $0.id == catId }) else { return nil }
            return (cat.sfSymbol, Color(hex: cat.colorHex))
        }
    }
    
    private var currentMonthIncomeTxs: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return store.transactions.filter {
            $0.type == .income &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
    }
    
    private var incomeIconInfos: [(icon: String, color: Color)] {
        var seen = Set<String>()
        var results: [(icon: String, color: Color)] = []
        for tx in currentMonthIncomeTxs {
            guard !seen.contains(tx.categoryId) else { continue }
            seen.insert(tx.categoryId)
            let cat = store.categories.first(where: { $0.id == tx.categoryId })
            let icon = cat?.sfSymbol ?? "dollarsign.circle.fill"
            let color = Color(hex: cat?.colorHex ?? "#30D158")
            results.append((icon, color))
            if results.count >= 3 { break }
        }
        return results
    }
}

// MARK: - Pressable Spring Button Style
private struct PressableSpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.70), value: configuration.isPressed)
    }
}
