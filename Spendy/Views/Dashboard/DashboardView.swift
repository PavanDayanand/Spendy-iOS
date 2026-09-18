//
//  DashboardView.swift
//  Spendy
//
//  Clean Minimal Home Dashboard:
//  - Top Bar: Profile Avatar (Left) + Top Action Toggles (Stats, Currency, Privacy, Budget)
//  - Account Dropdown Selector (Below Top Toggles)
//  - Hero Spend Section: Monthly Spend Card + On-Screen 6-Month Bar Chart with Interactive Scrubbing
//  - Interactive Bottom Transactions Drawer: Comic Sticker Count Badge, High-Performance Drag & Character Moments
//

import SwiftUI

// MARK: - Bar Chart Data Point
struct MinimalBarPoint: Identifiable, Equatable {
    let id: String
    let label: String
    let amount: Double
}

// MARK: - Spend Trend Point (Shared with SparklineView)
struct SpendTrendPoint: Identifiable, Equatable {
    let id: Int
    let label: String
    let amount: Double
}

// MARK: - On-Screen Hero Spend Bar Chart Component with Interactive Scrubbing
struct HeroSpendBarChart: View {
    let dataPoints: [MinimalBarPoint]
    @Binding var scrubbedPoint: MinimalBarPoint?
    @Binding var isScrubbing: Bool
    var barColor: Color = SpendyColors.textPrimary
    var gridColor: Color = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.12),
        dark: UIColor(white: 1.0, alpha: 0.18)
    ))
    
    public init(
        dataPoints: [MinimalBarPoint],
        scrubbedPoint: Binding<MinimalBarPoint?> = .constant(nil),
        isScrubbing: Binding<Bool> = .constant(false),
        barColor: Color = SpendyColors.textPrimary
    ) {
        self.dataPoints = dataPoints
        self._scrubbedPoint = scrubbedPoint
        self._isScrubbing = isScrubbing
        self.barColor = barColor
    }
    
    private var maxAmount: Double {
        let maxVal = dataPoints.map(\.amount).max() ?? 0
        if maxVal <= 0 { return 300_000 }
        let magnitude = pow(10, floor(log10(maxVal)))
        let normalized = maxVal / magnitude
        let step: Double
        if normalized <= 1.2 { step = 1.5 }
        else if normalized <= 2.5 { step = 3.0 }
        else if normalized <= 5.0 { step = 6.0 }
        else { step = 10.0 }
        return step * magnitude
    }
    
    private var yAxisLevels: [Double] {
        let maxVal = maxAmount
        return [maxVal, maxVal * (2.0 / 3.0), maxVal * (1.0 / 3.0), 0]
    }
    
    private func barLayout(chartWidth: CGFloat) -> (barWidth: CGFloat, spacing: CGFloat, cornerRadius: CGFloat) {
        let count = CGFloat(max(1, dataPoints.count))
        let spacing: CGFloat
        if count >= 10 {
            spacing = 3
        } else if count >= 6 {
            spacing = 6
        } else {
            spacing = max(4, chartWidth * 0.03)
        }
        let barWidth = min(48, max(4, (chartWidth - spacing * (count + 1)) / count))
        let cornerRadius = min(12, max(2, barWidth * 0.42))
        return (barWidth, spacing, cornerRadius)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let chartWidth = max(10, geo.size.width - 65) // Reserve 65pt for Y-axis labels on right
                let chartHeight = geo.size.height
                let layout = barLayout(chartWidth: chartWidth)
                let barWidth = layout.barWidth
                let spacing = layout.spacing
                let cornerRadius = layout.cornerRadius
                
                ZStack(alignment: .topLeading) {
                    // 1. Horizontal Grid Lines & Right-aligned Y-Axis Labels
                    VStack(spacing: 0) {
                        ForEach(Array(yAxisLevels.enumerated()), id: \.offset) { index, level in
                            HStack(spacing: 8) {
                                // Horizontal Grid Line
                                Rectangle()
                                    .fill(gridColor)
                                    .frame(height: 0.8)
                                
                                // Y-Axis Label
                                Text(formatAxisNumber(level))
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .monospacedDigit()
                                    .foregroundStyle(SpendyColors.textSecondary)
                                    .frame(width: 50, alignment: .leading)
                            }
                            
                            if index < yAxisLevels.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    .frame(height: chartHeight)
                    
                    // 2. Solid Rounded Vertical Bars
                    HStack(spacing: spacing) {
                        Spacer(minLength: 0)
                        
                        ForEach(dataPoints) { point in
                            let isSelected = scrubbedPoint?.id == point.id
                            let isAnySelected = scrubbedPoint != nil
                            let ratio = maxAmount > 0 ? CGFloat(min(1.0, max(0.0, point.amount / maxAmount))) : 0.0
                            let barH = point.amount > 0 ? max(4, ratio * (chartHeight - 4)) : 0
                            
                            VStack {
                                Spacer(minLength: 0)
                                
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(barColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1.5)
                                    )
                                    .shadow(
                                        color: isSelected ? Color.white.opacity(0.4) : Color.clear,
                                        radius: 8,
                                        y: 0
                                    )
                                    .frame(width: barWidth, height: barH)
                                    .scaleEffect(isSelected ? 1.06 : 1.0, anchor: .bottom)
                                    .opacity(isAnySelected && !isSelected ? 0.30 : 1.0)
                            }
                            .frame(width: barWidth, height: chartHeight)
                            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
                            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isAnySelected)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(width: chartWidth, height: chartHeight)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            // Only scrub horizontally if not dragging vertically
                            if abs(value.translation.width) >= abs(value.translation.height) {
                                isScrubbing = true
                                if let closest = closestPoint(to: value.location.x, chartWidth: chartWidth) {
                                    if closest.id != scrubbedPoint?.id {
                                        HapticsManager.shared.trigger(.selection)
                                        withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.85)) {
                                            scrubbedPoint = closest
                                        }
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            isScrubbing = false
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                scrubbedPoint = nil
                            }
                        }
                )
            }
            .frame(height: 150)
            
            // 3. X-Axis Labels Row (Matching Chart Width)
            HStack(spacing: 0) {
                ForEach(dataPoints) { point in
                    let isSelected = scrubbedPoint?.id == point.id
                    Text(point.label)
                        .font(.system(size: 12, weight: isSelected ? .bold : .semibold, design: isSelected ? .monospaced : .default))
                        .monospacedDigit()
                        .foregroundStyle(
                            isSelected ? SpendyColors.textPrimary : (scrubbedPoint != nil ? SpendyColors.textTertiary : SpendyColors.textSecondary)
                        )
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
            }
            .padding(.trailing, 65) // Align with chart area
            .padding(.top, 4)
        }
    }
    
    private func closestPoint(to locationX: CGFloat, chartWidth: CGFloat) -> MinimalBarPoint? {
        guard !dataPoints.isEmpty else { return nil }
        let layout = barLayout(chartWidth: chartWidth)
        let barWidth = layout.barWidth
        let spacing = layout.spacing
        
        var closest: MinimalBarPoint? = nil
        var minDistance: CGFloat = .infinity
        
        for (index, point) in dataPoints.enumerated() {
            let barCenterX = spacing + CGFloat(index) * (barWidth + spacing) + barWidth / 2
            let distance = abs(locationX - barCenterX)
            if distance < minDistance {
                minDistance = distance
                closest = point
            }
        }
        return closest
    }
    
    private func formatAxisNumber(_ num: Double) -> String {
        if num <= 0 { return "0" }
        if num >= 1_000_000 {
            let m = num / 1_000_000
            return m.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(m))M" : String(format: "%.1fM", m)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: num)) ?? "\(Int(num))"
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @Environment(ExpenseStore.self) private var store
    @Binding var showAddTransaction: Bool
    var selectedTab: Binding<AppTab>? = nil
    var isSheetExpandedBinding: Binding<Bool>? = nil
    var isSubpageActiveBinding: Binding<Bool>? = nil
    
    // Sheets & Navigation State
    @State private var showSettings: Bool = false
    @State private var settingsInitialDestination: SettingsDestination? = nil
    @State private var showAnalyticsView: Bool = false
    @State private var showCurrencyConverter: Bool = false
    @State private var showBudgetHub: Bool = false
    @State private var showSubscriptionsHub: Bool = false
    @State private var initialSubscriptionIdForHub: String? = nil
    @State private var showAccounts: Bool = false
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var selectedCategoryForSheet: Category? = nil
    @State private var selectedAccountForSheet: Account? = nil
    
    @Namespace private var topControlsNamespace
    
    // Filter, Privacy & Expand State
    @State private var selectedAccountId: String = "all"
    @State private var hideBalance: Bool = false
    @State private var showAllTransactionsSheet: Bool = false
    @State private var showEditBudgetSheet: Bool = false
    @State private var showHomeConfigSheet: Bool = false
    @State private var scrubbedBarPoint: MinimalBarPoint? = nil
    @State private var isScrubbingChart: Bool = false
    
    // MARK: - Interactive Split Dashboard Drawer State
    @State private var internalSheetExpanded: Bool = false
    @State private var sheetDragOffsetY: CGFloat = 0
    
    private var isSubpageActive: Bool {
        showBudgetHub ||
        showAccounts ||
        showAllTransactionsSheet ||
        showSubscriptionsHub ||
        showAnalyticsView ||
        selectedCategoryForSheet != nil ||
        selectedAccountForSheet != nil
    }
    
    private var isSheetExpanded: Bool {
        isSheetExpandedBinding?.wrappedValue ?? internalSheetExpanded
    }
    
    private func setExpandedState(_ expanded: Bool) {
        if let binding = isSheetExpandedBinding {
            binding.wrappedValue = expanded
        }
        internalSheetExpanded = expanded
    }
    @State private var drawerFilterCategoryId: String? = nil
    @State private var drawerFilterAccountId: String? = nil
    @State private var drawerFilterType: TransactionType? = nil
    
    private var hasActiveFilters: Bool {
        drawerFilterCategoryId != nil || drawerFilterAccountId != nil || drawerFilterType != nil
    }
    
    private func clearDrawerFilters() {
        drawerFilterCategoryId = nil
        drawerFilterAccountId = nil
        drawerFilterType = nil
    }
    
    private var drawerCategoryButtonLabel: String {
        if let catId = drawerFilterCategoryId, let cat = store.categories.first(where: { $0.id == catId }) {
            return cat.label
        }
        return "Categories"
    }
    
    private var drawerAccountButtonLabel: String {
        if let accId = drawerFilterAccountId, let acc = store.accounts.first(where: { $0.id == accId }) {
            return acc.label
        }
        return "Accounts"
    }
    
    private var drawerTypeButtonLabel: String {
        switch drawerFilterType {
        case .expense: return "Expenses"
        case .income: return "Income"
        case .transfer: return "Transfers"
        case .none: return "All Types"
        }
    }
    
    // MARK: - Dynamic Filtered Transactions
    private var displayedTransactions: [Transaction] {
        var txs = store.filteredTransactions(for: selectedAccountId)
        
        if let catId = drawerFilterCategoryId {
            txs = txs.filter { $0.categoryId == catId }
        }
        
        if let accId = drawerFilterAccountId {
            txs = txs.filter { $0.accountId == accId || $0.toAccountId == accId }
        }
        
        if let type = drawerFilterType {
            txs = txs.filter { $0.type == type }
        }
        
        return txs.sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Date Grouped Tuples: (DateTitle, GroupNetTotal, [Transaction])
    private var drawerGroupedTransactions: [(String, Double, [Transaction])] {
        let calendar = Calendar.current
        var groups: [String: [Transaction]] = [:]
        var order: [String] = []
        
        for tx in displayedTransactions {
            let key: String
            if calendar.isDateInToday(tx.date) {
                key = "Today"
            } else if calendar.isDateInYesterday(tx.date) {
                key = "Yesterday"
            } else {
                key = SpendyDateFormatterCache.dayMonth.string(from: tx.date)
            }
            
            if groups[key] == nil {
                order.append(key)
            }
            groups[key, default: []].append(tx)
        }
        
        return order.map { key in
            let txs = groups[key] ?? []
            let netTotal = txs.reduce(0.0) { sum, tx in
                switch tx.type {
                case .expense: return sum - tx.amount
                case .income: return sum + tx.amount
                case .transfer: return sum
                }
            }
            return (key, netTotal, txs)
        }
    }
    
    private func formattedGroupNetTotal(_ net: Double) -> String {
        if hideBalance { return "••••" }
        let sym = store.currencySymbol
        let absFormatted = abs(net).formattedCurrency(symbol: sym)
        if net > 0 {
            return "+\(absFormatted)"
        } else if net < 0 {
            return "-\(absFormatted)"
        } else {
            return absFormatted
        }
    }
    
    private var todayTransactionsCount: Int {
        let calendar = Calendar.current
        return displayedTransactions.filter { calendar.isDateInToday($0.date) }.count
    }
    
    private var drawerHeaderTitle: String {
        let calendar = Calendar.current
        let hasTodayTxs = displayedTransactions.contains { calendar.isDateInToday($0.date) }
        if hasTodayTxs {
            return "Today"
        } else if isSheetExpanded {
            return "Transactions"
        } else {
            return "Recent"
        }
    }
    
    private var visibleTransactions: [Transaction] {
        Array(displayedTransactions.prefix(3))
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
    
    private var currentMonthSpent: Double {
        let calendar = Calendar.current
        let now = Date()
        return displayedTransactions
            .filter { $0.type == .expense && calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Last 6 Months Historical Spend Points for Bar Chart
    private var barChartDataPoints: [MinimalBarPoint] {
        let calendar = Calendar.current
        let now = Date()
        let expenses = displayedTransactions.filter { $0.type == .expense }
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        
        return (0..<6).reversed().compactMap { offset -> MinimalBarPoint? in
            guard let targetDate = calendar.date(byAdding: .month, value: -offset, to: now) else { return nil }
            let year = calendar.component(.year, from: targetDate)
            let month = calendar.component(.month, from: targetDate)
            
            let sum = expenses.filter {
                calendar.component(.year, from: $0.date) == year &&
                calendar.component(.month, from: $0.date) == month
            }.reduce(0) { $0 + $1.amount }
            
            let label = monthFormatter.string(from: targetDate)
            return MinimalBarPoint(id: "\(year)-\(month)", label: label, amount: sum)
        }
    }
    
    // Ambient Header Glow Color (Account accent if selected, else Profile accent)
    private var ambientHeaderColor: Color {
        if selectedAccountId != "all", let acc = store.accounts.first(where: { $0.id == selectedAccountId }) {
            return acc.color
        }
        if let hex = store.profileColorHex, !hex.isEmpty {
            return Color(hex: hex)
        }
        if !store.topGradientColorHex.isEmpty {
            return Color(hex: store.topGradientColorHex)
        }
        return Color(hex: "#007AFF")
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let totalHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
                let topInset = geometry.safeAreaInsets.top
                let bottomInset = geometry.safeAreaInsets.bottom
                
                ZStack(alignment: .topLeading) {
                    LiquidMeshBackground()
                        .ignoresSafeArea()
                    
                    // 1. Fixed Top Canvas (50% Screen Area)
                    VStack(alignment: .leading, spacing: 14) {
                        // Top Bar: Profile (Left) + Action Toggles (Right: Stats, Converter, Eye, Budget)
                        headerBar
                            .padding(.top, topInset + 4)
                        
                        // Account Dropdown Selector (Below Top Toggles)
                        accountDropdownSelector
                        
                        // Hero Spend Section with On-Screen Month Bar Chart
                        heroSpendBarSection
                            .padding(.top, 2)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    if showCurrencyConverter {
                        Color(uiColor: .dynamic(
                            light: UIColor(white: 0.0, alpha: 0.25),
                            dark: UIColor(white: 0.0, alpha: 0.55)
                        ))
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                                showCurrencyConverter = false
                            }
                        }
                        
                        VStack {
                            FloatingCurrencyConverterView(isPresented: $showCurrencyConverter)
                                .padding(.horizontal, 20)
                                .padding(.top, topInset + 60)
                            Spacer()
                        }
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                        .ignoresSafeArea(edges: .top)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(10)
                    }
                    
                    // 2. Interactive Bottom Transactions Drawer (Solid Opaque Surface)
                    recentTransactionsDrawer(
                        totalHeight: totalHeight,
                        topInset: topInset,
                        bottomInset: bottomInset
                    )
                }
                .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings, onDismiss: {
                settingsInitialDestination = nil
            }) {
                SettingsView(initialDestination: settingsInitialDestination)
                    .presentationBackground(SpendyColors.settingsBackground)
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showEditBudgetSheet) {
                EditBudgetSheet(isEditing: store.budget.isActive)
            }
            .sheet(isPresented: $showHomeConfigSheet) {
                HomeConfigurationSheet()
            }
            .fullScreenCover(item: $editingTransaction) { tx in
                AddTransactionView(transactionToEdit: tx)
            }
            .sheet(item: $inspectingTransaction) { tx in
                TransactionDetailSheet(transaction: tx) { txToEdit in
                    inspectingTransaction = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        editingTransaction = txToEdit
                    }
                }
            }
            .navigationDestination(isPresented: $showAnalyticsView) {
                AnalyticsView(
                    selectedTab: selectedTab,
                    topControlsNamespace: topControlsNamespace
                )
            }
            .navigationDestination(isPresented: $showBudgetHub) {
                BudgetView(topControlsNamespace: topControlsNamespace)
            }
            .navigationDestination(isPresented: $showSubscriptionsHub) {
                SubscriptionsView(
                    initialSelectedSubscriptionId: initialSubscriptionIdForHub,
                    topControlsNamespace: topControlsNamespace
                )
            }
            .navigationDestination(isPresented: $showAccounts) {
                AccountsView(topControlsNamespace: topControlsNamespace)
            }
            .navigationDestination(isPresented: $showAllTransactionsSheet) {
                AllTransactionsView()
            }
            .navigationDestination(item: $selectedCategoryForSheet) { category in
                CategoryAnalyticsSheet(
                    category: category,
                    topControlsNamespace: topControlsNamespace,
                    backButtonMorphID: "topControl_left",
                    periodControlMorphID: "accountDropdownCapsule"
                )
            }
            .navigationDestination(item: $selectedAccountForSheet) { account in
                AccountAnalyticsSheet(
                    account: account,
                    topControlsNamespace: topControlsNamespace,
                    backButtonMorphID: "topControl_left",
                    periodControlMorphID: "accountDropdownCapsule"
                )
            }
            .onChange(of: isSubpageActive) { _, active in
                withAnimation(AppMotion.fluidSpring) {
                    isSubpageActiveBinding?.wrappedValue = active
                }
            }
            .onAppear {
                isSubpageActiveBinding?.wrappedValue = isSubpageActive
            }
        }
    }
    
    // MARK: - 1. Top Header Bar (Profile Left + Action Toggles Right)
    private var profileDisplayName: String {
        let name = store.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Personal" : name
    }
    
    @ViewBuilder
    private var profileAvatarView: some View {
        let profColorHex = store.profileColorHex ?? store.topGradientColorHex
        let avatarSize: CGFloat = 34
        
        ZStack {
            if let imgData = store.profileImageData, let uiImage = UIImage(data: imgData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
            } else if let symbol = store.profileIconSymbol, !symbol.isEmpty {
                Circle()
                    .fill(Color(hex: profColorHex))
                    .frame(width: avatarSize, height: avatarSize)
                
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.inverseText)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: profColorHex), SpendyColors.accentCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: avatarSize, height: avatarSize)
                
                let initial = store.userName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1).uppercased()
                Text(initial.isEmpty ? "P" : String(initial))
                    .font(.system(size: 14, weight: .heavy, design: .default))
                    .foregroundStyle(SpendyColors.inverseText)
            }
        }
        .shadow(color: Color.black.opacity(0.18), radius: 2, y: 1)
    }
    
    private var headerBar: some View {
        HStack(alignment: .center) {
            // Profile / Account Capsule Pill on Top-Left (Opens Settings)
            Button(action: {
                HapticsManager.shared.trigger(.light)
                settingsInitialDestination = nil
                showSettings = true
            }) {
                HStack(spacing: 8) {
                    profileAvatarView
                    
                    Text(profileDisplayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.leading, 5)
                .padding(.trailing, 14)
                .frame(height: 44)
                .nativeLiquidGlassCapsule(isInteractive: true)
                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(ProfilePillPressStyle())
            .accessibilityLabel("Profile, \(profileDisplayName). Opens settings.")
            .glassMorphID("topControl_left", in: topControlsNamespace)
            
            Spacer()
            
            // Top Right Action Toggles (Stats, Currency, Privacy, Budget)
            GlassButtonGroup(spacing: 10) {
                // 1. Stats / Analytics Button (Slides in like Budget)
                GlassCircleButton(
                    icon: SFIcons.tabAnalytics,
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: "Analytics and statistics"
                ) {
                    HapticsManager.shared.trigger(.selection)
                    showAnalyticsView = true
                }
                
                // 2. Currency Converter Button
                GlassCircleButton(
                    icon: "arrow.left.arrow.right",
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: "Currency converter"
                ) {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        showCurrencyConverter = true
                    }
                }
                
                // 3. Privacy Eye Toggle Button
                GlassCircleButton(
                    icon: hideBalance ? SFIcons.eyeSlash : SFIcons.eye,
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: hideBalance ? "Show balance" : "Hide balance"
                ) {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.25)) {
                        hideBalance.toggle()
                    }
                }
                
                // 4. Budget Hub Button
                GlassCircleButton(
                    icon: "target",
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: "Budget"
                ) {
                    HapticsManager.shared.trigger(.selection)
                    showBudgetHub = true
                }
            }
            .matchedGeometryEffect(id: "topControl_right", in: topControlsNamespace)
        }
    }
    
    // MARK: - 2. Account Selector Dropdown Menu Chip
    private var accountDropdownSelector: some View {
        SpendyGlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                Menu {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { selectedAccountId = "all" }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        HStack {
                            Text("All Accounts")
                            if selectedAccountId == "all" {
                                Image(systemName: "checkmark")
                            }
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
                                if selectedAccountId == acc.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        showAccounts = true
                    }) {
                        Label("Manage Accounts...", systemImage: "creditcard")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedAccountSymbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.primaryBlue)
                        
                        Text(selectedAccountLabel)
                            .font(.system(size: 13.5, weight: .bold, design: .default))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .nativeLiquidGlassCapsule(isInteractive: true)
                    .glassMorphID("accountDropdownCapsule", in: topControlsNamespace)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
    }
    
    // MARK: - 3. Hero Spend Section with On-Screen Month Bar Chart
    private var heroSpendBarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Label
            Group {
                if let scrubbed = scrubbedBarPoint {
                    Text("Spent in \(scrubbed.label) • Drag to inspect")
                        .font(AppTypography.itemTitle)
                        .foregroundStyle(SpendyColors.textPrimary)
                } else {
                    Text("Spent this month")
                        .font(AppTypography.itemTitle)
                        .foregroundStyle(SpendyColors.textSecondary)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: scrubbedBarPoint?.id)
            
            // Large Amount Text with Vertical Gradient
            let displayAmount = scrubbedBarPoint?.amount ?? currentMonthSpent
            
            if hideBalance {
                Text("••••••")
                    .spendyNumberFont(size: 42, weight: .heavy, tracking: -1.0)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .padding(.bottom, 6)
            } else {
                SpendyGradientText(
                    displayAmount.formattedCurrency(symbol: store.currencySymbol, decimals: 2),
                    size: 42,
                    weight: .heavy,
                    tracking: -1.0,
                    colors: SpendyGradientPresets.electricBlueToWhite
                )
                .padding(.bottom, 6)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: scrubbedBarPoint?.id)
            }
            
            // On-Screen Bar Chart with Interactive Scrubbing (Last 6 Months)
            HeroSpendBarChart(
                dataPoints: barChartDataPoints,
                scrubbedPoint: $scrubbedBarPoint,
                isScrubbing: $isScrubbingChart
            )
            .padding(.top, 2)
        }
    }
    
    // MARK: - 4. Interactive Bottom Transactions Drawer
    private func recentTransactionsDrawer(totalHeight: CGFloat, topInset: CGFloat, bottomInset: CGFloat) -> some View {
        let restingOffset = totalHeight * 0.55
        let expandedOffset = max(topInset + 10, 56)
        let currentOffset = currentDrawerOffset(totalHeight: totalHeight, topInset: topInset)
        let drawerAvailableHeight = max(100, totalHeight - expandedOffset)
        
        return VStack(spacing: 0) {
            // Drag Indicator & Header Zone (Always draggable & tappable)
            VStack(spacing: 0) {
                // Centered Capsule Grab Handle
                Capsule()
                    .fill(Color.secondary.opacity(0.40))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                
                // Header Row (Large 28pt Bold Title + Die-Cut Sticker Badge on Right)
                HStack(alignment: .center) {
                    Text(drawerHeaderTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if isSheetExpanded && hasActiveFilters {
                            Button(action: {
                                HapticsManager.shared.trigger(.selection)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    clearDrawerFilters()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Clear")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(SpendyColors.textSecondary)
                                .padding(.horizontal, 10)
                                .frame(height: 34)
                                .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Large Die-Cut Cartoon Sticker Badge
                        let count = todayTransactionsCount > 0 ? todayTransactionsCount : displayedTransactions.count
                        let badgePalette: SpendyComicPalette = todayTransactionsCount > 0 ? .cyberGold : .fire
                        
                        SpendyComicBadge(
                            "\(count)",
                            palette: badgePalette,
                            size: .medium,
                            rotationAngle: -6
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, isSheetExpanded ? 10 : 8)
                
                // Integrated 44pt Standard Filter Bar (Revealed on Drag / Expand)
                if isSheetExpanded {
                    drawerFilterBar
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(sheetDragGesture(restingOffset: restingOffset, expandedOffset: expandedOffset))
            
            // Transaction List Content
            if displayedTransactions.isEmpty {
                emptyRecentActivityView
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                Spacer(minLength: 0)
            } else if !isSheetExpanded {
                // Collapsed Solid State: Show only the transactions that fit cleanly ABOVE the floating dock
                let collapsedTxs = Array(displayedTransactions.prefix(3))
                VStack(spacing: 0) {
                    ForEach(Array(collapsedTxs.enumerated()), id: \.element.id) { index, tx in
                        transactionRow(tx)
                        
                        if index < collapsedTxs.count - 1 {
                            Rectangle()
                                .fill(SpendyColors.separator.opacity(0.6))
                                .frame(height: 0.5)
                                .padding(.leading, 64)
                                .padding(.trailing, 16)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
                
                Spacer(minLength: 0)
            } else {
                // Expanded Full State: Scrollable view with all categorized/date-grouped transactions
                ScrollView(showsIndicators: true) {
                    LazyVStack(spacing: 0) {
                        ForEach(drawerGroupedTransactions, id: \.0) { groupTitle, groupNet, txs in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(groupTitle.uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(SpendyColors.textTertiary)
                                        .tracking(1.2)
                                    
                                    Spacer()
                                    
                                    Text(formattedGroupNetTotal(groupNet))
                                        .spendyNumberFont(size: 13, weight: .semibold, tracking: -0.2)
                                        .foregroundStyle(SpendyColors.textSecondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                .padding(.bottom, 4)
                                
                                ForEach(Array(txs.enumerated()), id: \.element.id) { index, tx in
                                    transactionRow(tx)
                                    
                                    if index < txs.count - 1 {
                                        Rectangle()
                                            .fill(SpendyColors.separator.opacity(0.6))
                                            .frame(height: 0.5)
                                            .padding(.leading, 64)
                                            .padding(.trailing, 16)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, bottomInset + 100) // Clearance for floating dock when scrolled
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: drawerAvailableHeight)
        .background {
            // Smooth Stable Rounded Surface with dynamic top/bottom corner radii
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(SpendyColors.separator.opacity(0.8), lineWidth: 0.8)
                }
                .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: -4)
        }
        .padding(.horizontal, isSheetExpanded ? 0 : 8)
        .offset(y: currentOffset)
    }
    
    // MARK: - Drawer Horizontal Filter Bar
    private var drawerFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 1. [Categories] Menu
                Menu {
                    Button("All Categories") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterCategoryId = nil
                        }
                    }
                    Divider()
                    ForEach(store.categories) { cat in
                        Button(cat.label) {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                drawerFilterCategoryId = cat.id
                            }
                        }
                    }
                } label: {
                    let isCatSelected = drawerFilterCategoryId != nil
                    HStack(spacing: 8) {
                        Image(systemName: isCatSelected ? (store.category(for: drawerFilterCategoryId ?? "").sfSymbol) : "circle.grid.2x2")
                            .font(.system(size: 14, weight: .semibold))
                        Text(drawerCategoryButtonLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isCatSelected ? .white.opacity(0.8) : SpendyColors.textTertiary)
                    }
                    .foregroundStyle(isCatSelected ? .white : SpendyColors.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .nativeLiquidGlassCapsule(isInteractive: true, tint: isCatSelected ? SpendyColors.primaryBlue : nil)
                }
                .buttonStyle(.plain)
                
                // 2. [Accounts] Menu
                Menu {
                    Button("All Accounts") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterAccountId = nil
                        }
                    }
                    Divider()
                    ForEach(store.accounts) { acc in
                        Button(acc.label) {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                drawerFilterAccountId = acc.id
                            }
                        }
                    }
                } label: {
                    let isAccSelected = drawerFilterAccountId != nil
                    HStack(spacing: 8) {
                        Image(systemName: isAccSelected ? (store.account(for: drawerFilterAccountId ?? "").sfSymbol.isEmpty ? "building.columns" : store.account(for: drawerFilterAccountId ?? "").sfSymbol) : "building.columns")
                            .font(.system(size: 14, weight: .semibold))
                        Text(drawerAccountButtonLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isAccSelected ? .white.opacity(0.8) : SpendyColors.textTertiary)
                    }
                    .foregroundStyle(isAccSelected ? .white : SpendyColors.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .nativeLiquidGlassCapsule(isInteractive: true, tint: isAccSelected ? SpendyColors.primaryBlue : nil)
                }
                .buttonStyle(.plain)
                
                // 3. [Type] Menu (Expenses, Income, Transfers)
                Menu {
                    Button("All Types") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterType = nil
                        }
                    }
                    Button("Expenses") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterType = .expense
                        }
                    }
                    Button("Income") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterType = .income
                        }
                    }
                    Button("Transfers") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            drawerFilterType = .transfer
                        }
                    }
                } label: {
                    let isTypeSelected = drawerFilterType != nil
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                        Text(drawerTypeButtonLabel)
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isTypeSelected ? .white.opacity(0.8) : SpendyColors.textTertiary)
                    }
                    .foregroundStyle(isTypeSelected ? .white : SpendyColors.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .nativeLiquidGlassCapsule(isInteractive: true, tint: isTypeSelected ? SpendyColors.primaryBlue : nil)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func sheetDragGesture(restingOffset: CGFloat, expandedOffset: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                // Only track vertical movement to prevent hijacking horizontal chart scrubbing
                if abs(value.translation.width) > abs(value.translation.height) && abs(value.translation.height) < 8 {
                    return
                }
                sheetDragOffsetY = value.translation.height
            }
            .onEnded { value in
                let translation = value.translation.height
                let velocity = value.velocity.height
                
                // Tap detection if dragged less than 5pt
                if abs(translation) < 5 {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(AppMotion.fluidSpring) {
                        setExpandedState(!isSheetExpanded)
                        sheetDragOffsetY = 0
                    }
                    return
                }
                
                let startBase = isSheetExpanded ? expandedOffset : restingOffset
                let currentPos = startBase + translation
                let midpoint = (restingOffset + expandedOffset) / 2
                
                let targetExpanded: Bool
                if velocity < -350 {
                    targetExpanded = true
                } else if velocity > 350 {
                    targetExpanded = false
                } else {
                    targetExpanded = currentPos < midpoint
                }
                
                HapticsManager.shared.trigger(.selection)
                withAnimation(AppMotion.fluidSpring) {
                    setExpandedState(targetExpanded)
                    sheetDragOffsetY = 0
                }
            }
    }
    
    private func currentDrawerOffset(totalHeight: CGFloat, topInset: CGFloat) -> CGFloat {
        let restingOffset = totalHeight * 0.55
        let expandedOffset = max(topInset + 10, 56)
        let baseOffset = isSheetExpanded ? expandedOffset : restingOffset
        let rawOffset = baseOffset + sheetDragOffsetY
        
        if rawOffset < expandedOffset {
            let overshoot = expandedOffset - rawOffset
            return expandedOffset - sqrt(max(0, overshoot)) * 2.5
        } else if rawOffset > restingOffset {
            let overshoot = rawOffset - restingOffset
            return restingOffset + sqrt(max(0, overshoot)) * 2.5
        }
        return rawOffset
    }
    
    // MARK: - Transaction Row Item (Matches Exact Visual Design)
    private func transactionRow(_ tx: Transaction) -> some View {
        let cat = store.category(for: tx.categoryId)
        let acc = store.account(for: tx.accountId)
        
        return Button(action: {
            HapticsManager.shared.trigger(.light)
            inspectingTransaction = tx
        }) {
            HStack(spacing: 12) {
                // Category Icon Badge matching exact reference design
                SpendyIconBadge(
                    sfSymbol: cat.sfSymbol,
                    color: cat.color,
                    size: .medium,
                    style: .circle,
                    monogramName: cat.label
                )
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(tx.title.isEmpty ? cat.label : tx.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(acc.label)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        if let notes = tx.notes, !notes.isEmpty {
                            Text("• \(notes)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(SpendyColors.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Amount Value
                if hideBalance {
                    Text("••••")
                        .spendyNumberFont(size: 16, weight: .semibold, tracking: -0.2)
                        .foregroundStyle(SpendyColors.textSecondary)
                } else {
                    let formatted = tx.amount.formattedCurrency(symbol: store.currencySymbol)
                    Text(tx.type == .income ? "+\(formatted)" : formatted)
                        .spendyNumberFont(size: 16, weight: .semibold, tracking: -0.2)
                        .foregroundStyle(rowAmountColor(tx))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func rowAmountColor(_ tx: Transaction) -> Color {
        switch tx.type {
        case .expense:
            return SpendyColors.textPrimary
        case .income:
            return SpendyColors.incomeGreen
        case .transfer:
            return SpendyColors.textSecondary
        }
    }
    
    // MARK: - Empty State View
    private var emptyRecentActivityView: some View {
        VStack(spacing: 16) {
            SpendyCharacterMomentCard(
                sticker: store.activeCompanionSticker,
                speechText: hasActiveFilters ? "Nothing matches these filters. Clear them to see your spends!" : "Oh, the thrill of staring at zero expenses. Tap + to log your first spend.",
                kicker: store.activeCompanionSticker.title,
                stickerSize: 92
            )
            .padding(.top, 12)
            
            if hasActiveFilters {
                Button("Reset Filters") {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(AppMotion.snappySpring) {
                        clearDrawerFilters()
                    }
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(SpendyColors.primaryBlue)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Profile Pill Press Style
private struct ProfilePillPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
