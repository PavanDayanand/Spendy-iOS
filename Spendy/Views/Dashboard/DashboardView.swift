//
//  DashboardView.swift
//  Spendy
//
//  Clean Minimal Home Dashboard:
//  - Top Bar: Profile Avatar (Left) + 3 Action Toggles (Right: Currency, Privacy, Subscriptions)
//  - Account Dropdown Selector (Below Top Toggles)
//  - Hero Spend Section: Spend Total + On-Screen Bar Chart with Gridlines & Y/X-Axes
//  - Classic Recent Transactions Section: Category Badges, Account Tags, Amounts & Details
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

// MARK: - On-Screen Hero Spend Bar Chart Component (Matching Screenshot, Uncarded)
struct HeroSpendBarChart: View {
    let dataPoints: [MinimalBarPoint]
    var barColor: Color = SpendyColors.textPrimary
    var gridColor: Color = Color(uiColor: .dynamic(
        light: UIColor(white: 0.0, alpha: 0.12),
        dark: UIColor(white: 1.0, alpha: 0.18)
    ))
    
    private var maxAmount: Double {
        let maxVal = dataPoints.map(\.amount).max() ?? 0
        if maxVal <= 0 { return 300_000 }
        // Round up to nearest clean step (e.g. 300k, 200k, 100k)
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
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let chartWidth = geo.size.width - 65 // Reserve 65pt for Y-axis labels on right
                let chartHeight = geo.size.height
                let barCount = CGFloat(max(1, dataPoints.count))
                let barWidth: CGFloat = min(48, max(28, (chartWidth / barCount) * 0.55))
                let spacing = (chartWidth - (barWidth * barCount)) / (barCount + 1)
                
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
                                    .font(.system(size: 11, weight: .semibold, design: .default))
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
                            let ratio = maxAmount > 0 ? CGFloat(min(1.0, max(0.0, point.amount / maxAmount))) : 0.0
                            let barH = max(4, ratio * (chartHeight - 4))
                            
                            VStack {
                                Spacer(minLength: 0)
                                
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(barColor)
                                    .frame(width: barWidth, height: barH)
                            }
                            .frame(width: barWidth, height: chartHeight)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(width: chartWidth, height: chartHeight)
                }
            }
            .frame(height: 150)
            
            // 3. X-Axis Labels Row (Matching Chart Width)
            HStack(spacing: 0) {
                ForEach(dataPoints) { point in
                    Text(point.label)
                        .font(.system(size: 12, weight: .semibold, design: .default))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.trailing, 65) // Align with chart area
            .padding(.top, 4)
        }
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
    
    // Sheets & Navigation State
    @State private var showSettings: Bool = false
    @State private var settingsInitialDestination: SettingsDestination? = nil
    @State private var showCurrencyConverter: Bool = false
    @State private var showSubscriptionsHub: Bool = false
    @State private var showSmartInsightsSheet: Bool = false
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
    
    // MARK: - Dynamic Filtered Transactions
    private var displayedTransactions: [Transaction] {
        store.filteredTransactions(for: selectedAccountId)
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
    
    private var totalSpentAllTime: Double {
        displayedTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    // 4-Year Historical Spend Points for Bar Chart
    private var barChartDataPoints: [MinimalBarPoint] {
        let calendar = Calendar.current
        let expenses = displayedTransactions.filter { $0.type == .expense }
        let currentYear = calendar.component(.year, from: Date())
        let years = (currentYear - 3...currentYear).map { $0 }
        
        return years.map { year in
            let sum = expenses.filter { calendar.component(.year, from: $0.date) == year }.reduce(0) { $0 + $1.amount }
            return MinimalBarPoint(id: "\(year)", label: "\(year)", amount: sum)
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
            ZStack {
                LiquidMeshBackground(color: ambientHeaderColor)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedAccountId)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // 1. Top Bar: Profile (Left) + 3 Action Toggles (Right)
                        headerBar
                            .padding(.top, 4)
                        
                        // 2. Account Dropdown Selector (Below Top Toggles)
                        accountDropdownSelector
                        
                        // 3. Hero Spend Section with On-Screen Bar Chart
                        heroSpendBarSection
                            .padding(.top, 6)
                        
                        // 4. Horizontal Daily Burn / Allowance Pacing Card (No heading)
                        dailyBurnHorizontalCard
                            .padding(.top, 2)
                        
                        // 5. Smart Insights Section (Above Accounts & Transactions)
                        smartInsightsSection
                            .padding(.top, 6)
                        
                        // 6. Accounts Section (Unified Grouped Card on Home)
                        accountsUnifiedCardSection
                            .padding(.top, 6)
                        
                        // 7. Classic Recent Transactions Section
                        recentTransactionsSection
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom floating tab bar
                }
                
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
                    
                    GeometryReader { geometry in
                        VStack {
                            FloatingCurrencyConverterView(isPresented: $showCurrencyConverter)
                                .padding(.horizontal, 20)
                                .padding(.top, geometry.safeAreaInsets.top + 60)
                            Spacer()
                        }
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .ignoresSafeArea(edges: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings, onDismiss: {
                settingsInitialDestination = nil
            }) {
                SettingsView(initialDestination: settingsInitialDestination)
                    .presentationBackground(SpendyColors.settingsBackground)
                    .presentationDragIndicator(.hidden)
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
            .navigationDestination(isPresented: $showSubscriptionsHub) {
                SubscriptionsView(topControlsNamespace: topControlsNamespace)
            }
            .navigationDestination(isPresented: $showAccounts) {
                AccountsView(topControlsNamespace: topControlsNamespace)
            }
            .navigationDestination(isPresented: $showSmartInsightsSheet) {
                SmartInsightsSheet()
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
        }
    }
    
    // MARK: - 1. Top Header Bar (Profile Left + 3 Action Toggles Right)
    private var headerBar: some View {
        HStack(alignment: .center) {
            // Profile / Account Button on Top-Left (Opens Settings)
            Button(action: {
                HapticsManager.shared.trigger(.light)
                settingsInitialDestination = nil
                showSettings = true
            }) {
                ZStack {
                    let profColorHex = store.profileColorHex ?? store.topGradientColorHex
                    if let imgData = store.profileImageData, let uiImage = UIImage(data: imgData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(SpendyColors.separator, lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                    } else if let symbol = store.profileIconSymbol, !symbol.isEmpty {
                        Circle()
                            .fill(Color(hex: profColorHex))
                            .frame(width: 44, height: 44)
                            .shadow(color: Color(hex: profColorHex).opacity(0.35), radius: 4, y: 2)
                        
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .semibold))
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
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.15), radius: 6, y: 2)
                        
                        Text(store.userName.prefix(1).uppercased().isEmpty ? "P" : String(store.userName.prefix(1).uppercased()))
                            .font(.system(size: 17, weight: .heavy, design: .default))
                            .foregroundStyle(SpendyColors.inverseText)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Account and Settings")
            .glassMorphID("topControl_left", in: topControlsNamespace)
            
            Spacer()
            
            // Top Right 3 Action Toggles (Currency, Privacy, Subscriptions)
            GlassButtonGroup(spacing: 10) {
                // 1. Currency Converter Button
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
                
                // 2. Privacy Eye Toggle Button
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
                
                // 3. Subscriptions Hub Button
                GlassCircleButton(
                    icon: SFIcons.subscriptions,
                    size: 44,
                    iconSize: 16,
                    accessibilityLabel: "Subscriptions"
                ) {
                    HapticsManager.shared.trigger(.selection)
                    showSubscriptionsHub = true
                }
            }
            .matchedGeometryEffect(id: "topControl_right", in: topControlsNamespace)
        }
    }
    
    // MARK: - 2. Account Selector Dropdown Menu Chip (Below Top Toggles)
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
    
    // MARK: - 3. Hero Spend Section with On-Screen Bar Chart (Matching Screenshot, Uncarded)
    private var heroSpendBarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Label: "Spent all time"
            Text("Spent all time")
                .font(AppTypography.itemTitle)
                .foregroundStyle(SpendyColors.textSecondary)
            
            // Large Amount Text (e.g. ₹258,406.00)
            Text(hideBalance ? "••••••" : totalSpentAllTime.formattedCurrency(symbol: store.currencySymbol, decimals: 2))
                .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                .foregroundStyle(SpendyColors.textPrimary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.bottom, 6)
            
            // On-Screen Bar Chart with Gridlines & Y/X-Axes (No card wrapper)
            HeroSpendBarChart(dataPoints: barChartDataPoints)
                .padding(.top, 2)
        }
    }
    
    // MARK: - 4. Smart Insights Section (Above Recent Transactions)
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
    
    // MARK: - 4. Horizontal Daily Burn / Allowance Pacing Card (Matching Transaction Card Style)
    private var dailyBurnHorizontalCard: some View {
        let budgetTarget = store.budgetTargetAmount(for: store.budget.period)
        let spent = store.budgetCycleExpenses
        let isBudgetActive = store.budget.isActive && budgetTarget > 0
        let isOver = isBudgetActive && spent > budgetTarget
        
        let iconSymbol = isBudgetActive ? (isOver ? "exclamationmark.shield.fill" : "gauge.with.dots.needle.bottom.50percent") : "target"
        let iconColor: Color = isBudgetActive ? (isOver ? Color(hex: "#FF453A") : Color(hex: "#30D158")) : SpendyColors.primaryBlue
        
        let titleText = isBudgetActive ? "Daily Burn" : "Daily Allowance"
        let valueText = isBudgetActive ? (hideBalance ? "••••" : "\(store.safeDailyAllowance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/day") : "Set Limit"
        let subtitleText = isBudgetActive ? (isOver ? "Budget exceeded · Restrict daily spend" : "\(store.budgetDaysLeft) days remaining in cycle") : "Plan your monthly limit & unlock safe daily allowance"
        
        let progress: Double = budgetTarget > 0 ? min(1.0, spent / budgetTarget) : 0.0
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            if let selectedTab = selectedTab {
                selectedTab.wrappedValue = .budget
            }
        }) {
            HStack(spacing: 14) {
                // Left Icon Avatar / Badge (44x44 circular matching transaction card)
                SpendyIconBadge(
                    sfSymbol: iconSymbol,
                    color: iconColor,
                    size: .medium,
                    style: .circle
                )
                
                // Content area
                VStack(alignment: .leading, spacing: 6) {
                    // Row 1: Title (Left) + Value (Right)
                    HStack(alignment: .firstTextBaseline) {
                        Text(titleText)
                            .font(.system(size: 15.5, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        Spacer()
                        
                        Text(valueText)
                            .spendyNumberFont(size: 16.5, weight: .bold, tracking: -0.4)
                            .foregroundStyle(iconColor)
                    }
                    
                    if isBudgetActive {
                        // Row 2: Clean Colored Progress Bar (No repeated numbers)
                        GeometryReader { geo in
                            let trackWidth = geo.size.width
                            let barWidth = max(0, min(trackWidth, trackWidth * CGFloat(progress)))
                            
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(SpendyColors.cardBackgroundSecondary)
                                    .frame(height: 5)
                                
                                Capsule()
                                    .fill(iconColor)
                                    .frame(width: barWidth, height: 5)
                            }
                        }
                        .frame(height: 5)
                        .padding(.vertical, 1)
                    }
                    
                    // Row 3: Subtitle / Days remaining in cycle
                    Text(subtitleText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(titleText), \(valueText), \(subtitleText)")
    }
    
    // MARK: - 5. Smart Insights Curated Engine (Up to 5 Intelligent Actionable Cards)
    private var allDashboardInsightCards: [InsightCardViewModel] {
        InsightsEngine.getDashboardCuratedCards(
            transactions: displayedTransactions,
            budget: store.budget,
            categories: store.categories,
            subscriptions: store.subscriptions,
            currencySymbol: store.currencySymbol,
            hideBalance: hideBalance
        )
    }
    
    @ViewBuilder
    private var smartInsightsSection: some View {
        if !allDashboardInsightCards.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Smart Insight")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        showSmartInsightsSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Text("View all")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(SpendyColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(allDashboardInsightCards) { insight in
                            renderDashboardInsightCard(insight)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    // MARK: - Polymorphic Insight Card Renderer (Strictly Unified 175pt Width × 188pt Height)
    @ViewBuilder
    private func renderDashboardInsightCard(_ insight: InsightCardViewModel) -> some View {
        let cardAction: () -> Void = {
            if let catId = insight.categoryId,
               let cat = store.categories.first(where: { $0.id == catId }) {
                selectedCategoryForSheet = cat
            } else if insight.family == "budget" || insight.id == "set_budget" {
                if let selectedTab = selectedTab {
                    selectedTab.wrappedValue = .budget
                }
            } else if insight.family == "subscription" || insight.id == "subscriptions_track" {
                showSubscriptionsHub = true
            } else if insight.family == "analytics" || insight.family == "spotlight" || insight.family == "habit" || insight.family == "velocity" {
                if let selectedTab = selectedTab {
                    selectedTab.wrappedValue = .analytics
                }
            }
        }
        
        if insight.isSpotlight, let peakIdx = insight.peakDayIndex {
            SpotlightBarCard(
                title: insight.title,
                peakDayName: insight.value,
                peakDayIndex: peakIdx,
                action: cardAction
            )
            .frame(width: 175)
        } else {
            CategoryCard(
                title: insight.title,
                value: insight.value,
                subtitle: insight.subtitle,
                icon: insight.icon,
                color: insight.color,
                tagText: insight.tagText,
                tagColor: insight.tagColor,
                action: cardAction
            )
            .frame(width: 175)
        }
    }
    
    // MARK: - 6. Accounts Section (Unified Grouped Card on Home)
    private var accountsUnifiedCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                showAccounts = true
            }) {
                HStack {
                    Text("Accounts")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(store.accounts.count)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 14) {
                // Top: Total Net Worth / Balance & Sparkline
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    showAccounts = true
                }) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Balance")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                            
                            Text(hideBalance ? "••••••" : store.totalBalance.formattedCurrency(symbol: store.currencySymbol))
                                .spendyNumberFont(size: 22, weight: .bold, tracking: -0.5)
                                .foregroundStyle(SpendyColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        // Sparkline Trend Curve
                        let isPositive = store.netWorthChangePercentage >= 0
                        TrendSparkline(isPositive: isPositive)
                            .frame(width: 80, height: 32)
                    }
                }
                .buttonStyle(.plain)
                
                Divider()
                    .overlay(SpendyColors.separator)
                
                // Account Rows
                VStack(spacing: 12) {
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
                                    .font(.system(size: 15.5, weight: .semibold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Spacer()
                                
                                Text(hideBalance ? "••••" : bal.formattedCurrency(symbol: store.currencySymbol))
                                    .spendyNumberFont(size: 15.5, weight: .bold, tracking: -0.3)
                                    .foregroundStyle(SpendyColors.textPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - 7. Unified Grouped Recent Transactions Section
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent transactions")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            if visibleTransactions.isEmpty {
                emptyRecentActivityView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(visibleTransactions.enumerated()), id: \.element.id) { index, tx in
                        transactionRow(tx)
                    }
                    
                    // Bottom "All transactions" link button inside the card
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        showAllTransactionsSheet = true
                    }) {
                        HStack {
                            Text("All transactions")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(SpendyColors.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(SpendyColors.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
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
                // Circular Category / Subscription Icon Badge
                SpendyIconBadge(
                    sfSymbol: iconSymbol,
                    color: iconColor,
                    size: .medium,
                    style: .circle
                )
                
                // Middle: Category / Title + Subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(tx.title.isEmpty ? (cat?.label ?? "Expense") : tx.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    if let acc = acc {
                        HStack(spacing: 5) {
                            Image(systemName: acc.sfSymbol.isEmpty ? acc.type.defaultSymbol : acc.sfSymbol)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 14, height: 14)
                                .background(acc.color, in: Circle())
                            
                            Text(acc.label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text(tx.date.formattedRelative)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Right: Amount
                Text(formattedRowAmount(tx))
                    .spendyNumberFont(size: 16.5, weight: .bold, tracking: -0.5)
                    .foregroundStyle(rowAmountColor(tx))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tx.title.isEmpty ? (cat?.label ?? "Transaction") : tx.title), \(tx.type == .income ? "Income" : (tx.type == .transfer ? "Transfer" : "Expense")), \(tx.amount.formattedCurrency(symbol: store.currencySymbol)), \(acc?.label ?? ""), \(tx.date.formattedRelative)")
        .contextMenu {
            Button {
                HapticsManager.shared.trigger(.light)
                editingTransaction = tx
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                HapticsManager.shared.trigger(.light)
                let copy = Transaction(
                    id: UUID(),
                    title: tx.title,
                    amount: tx.amount,
                    type: tx.type,
                    categoryId: tx.categoryId,
                    accountId: tx.accountId,
                    toAccountId: tx.toAccountId,
                    date: Date(),
                    notes: tx.notes,
                    subscriptionId: tx.subscriptionId
                )
                store.addTransaction(copy)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Button {
                HapticsManager.shared.trigger(.light)
                UIPasteboard.general.string = "\(tx.amount)"
            } label: {
                Label("Copy Amount", systemImage: "doc.on.clipboard")
            }
            
            Divider()
            
            Button(role: .destructive) {
                HapticsManager.shared.trigger(.warning)
                withAnimation(AppMotion.snappySpring) {
                    store.deleteTransaction(id: tx.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func rowAmountColor(_ tx: Transaction) -> Color {
        switch tx.type {
        case .expense: return SpendyColors.textPrimary
        case .income: return SpendyColors.incomeGreen
        case .transfer: return SpendyColors.primaryBlue
        }
    }
    
    private func formattedRowAmount(_ tx: Transaction) -> String {
        if hideBalance { return "••••" }
        let sym = store.currencySymbol
        return tx.amount.formattedCurrency(symbol: sym)
    }
    
    private var emptyRecentActivityView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SpendyColors.primaryBlue.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(SpendyColors.primaryBlue)
            }
            .padding(.top, 4)
            
            VStack(spacing: 4) {
                Text("No transactions logged yet")
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Text("Start tracking your daily expenses and income")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                showAddTransaction = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add Transaction")
                        .font(.system(size: 13, weight: .bold, design: .default))
                }
                .foregroundStyle(SpendyColors.inverseText)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(SpendyColors.primaryBlue))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
