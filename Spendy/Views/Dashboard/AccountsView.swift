//
//  AccountsView.swift
//  Spendy
//
//  Accounts dashboard: black canvas, summary card with real money-in/out,
//  swipeable insights, and a single grouped account list.
//

import SwiftUI

private struct AccountInsight: Identifiable {
    let id: String
    let headline: String
    let supporting: String
    let isWarning: Bool
    let account: Account?
}

struct AccountsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var isSettingsPage: Bool = false
    var onDismiss: (() -> Void)? = nil
    var topControlsNamespace: Namespace.ID? = nil
    var sharedNavigationHeader: AnalyticsNavigationHeaderState? = nil
    
    @State private var showAddAccount: Bool = false
    @State private var editingAccount: Account? = nil
    @State private var selectedAccountForAnalytics: Account? = nil
    @State private var insightPage: String?
    
    private var sortedAccounts: [Account] {
        store.accounts.sorted { $0.order < $1.order }
    }
    
    private var thisMonthFlow: (inflow: Double, outflow: Double) {
        let calendar = Calendar.current
        let now = Date()
        let txs = store.transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
                && calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
        let inflow = txs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let outflow = txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return (inflow, outflow)
    }
    
    private var overdrawnAccounts: [Account] {
        sortedAccounts.filter { store.balance(for: $0.id) < 0 }
    }
    
    private var cardInsights: [AccountInsight] {
        var items: [AccountInsight] = []
        
        if let worst = overdrawnAccounts.min(by: { store.balance(for: $0.id) < store.balance(for: $1.id) }) {
            let bal = store.balance(for: worst.id)
            items.append(AccountInsight(
                id: "overdrawn_\(worst.id)",
                headline: "\(worst.label) is overdrawn",
                supporting: abs(bal).formattedCurrency(symbol: store.currencySymbol, decimals: 0) + " below zero",
                isWarning: true,
                account: worst
            ))
        }
        
        let flow = thisMonthFlow
        let net = flow.inflow - flow.outflow
        if flow.inflow > 0 || flow.outflow > 0 {
            items.append(AccountInsight(
                id: "month_flow",
                headline: net >= 0 ? "You're ahead this month" : "You're behind this month",
                supporting: "+\(flow.inflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) in · −\(flow.outflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) out",
                isWarning: net < 0,
                account: nil
            ))
        }
        
        if let largest = sortedAccounts.max(by: { store.balance(for: $0.id) < store.balance(for: $1.id) }),
           store.balance(for: largest.id) > 0,
           store.totalBalance > 0 {
            let share = (store.balance(for: largest.id) / store.totalBalance) * 100
            if share >= 40 {
                items.append(AccountInsight(
                    id: "largest_\(largest.id)",
                    headline: "\(largest.label) holds most of your money",
                    supporting: String(format: "%.0f%% of total balance", share),
                    isWarning: false,
                    account: largest
                ))
            }
        }
        
        return Array(items.prefix(5))
    }
    
    private var groupedCardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(isSettingsPage ? SpendyColors.settingsCardBackground : SpendyColors.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(SpendyColors.separator, lineWidth: 0.8)
            }
    }
    
    var body: some View {
        ZStack {
            (isSettingsPage ? SpendyColors.settingsBackground : SpendyColors.appBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {

                if sharedNavigationHeader != nil {
                    Color.clear.frame(height: 50).accessibilityHidden(true)
                } else if topControlsNamespace != nil {
                    topHeaderBar
                }
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard
                            .padding(.horizontal, 20)
                            .padding(.top, topControlsNamespace != nil ? 8 : 12)
                        
                        if !cardInsights.isEmpty {
                            insightCard
                                .padding(.horizontal, 20)
                        }
                        
                        accountsList
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(sharedNavigationHeader != nil || topControlsNamespace != nil ? .hidden : .visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if sharedNavigationHeader == nil && topControlsNamespace == nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.shared.trigger(.selection)
                        showAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Add Account")
                }
            }
        }
        .sheet(isPresented: $showAddAccount) {
            AddAccountSheet()
        }
        .sheet(item: $editingAccount) { acc in
            AddAccountSheet(accountToEdit: acc)
        }
        .navigationDestination(item: $selectedAccountForAnalytics) { acc in
            AccountAnalyticsSheet(account: acc, isSettingsPage: isSettingsPage,
                topControlsNamespace: topControlsNamespace, sharedNavigationHeader: sharedNavigationHeader)
        }
        .onAppear { configureNavigationHeader() }
        .onChange(of: selectedAccountForAnalytics?.id) { _, _ in configureNavigationHeader() }
    }

    private func configureNavigationHeader() {
        // A returning parent must not overwrite a child's header during a cancelled pop.
        guard selectedAccountForAnalytics == nil else { return }
        let backAction = onDismiss
        let dismissAction = dismiss
        let addAccount = $showAddAccount
        sharedNavigationHeader?.show(title: "Accounts", onBack: {
            if let backAction { backAction() } else { dismissAction() }
        }, primaryAction: StackHeaderAction(id: "accounts-add", title: "Add Account", symbol: "plus") {
            addAccount.wrappedValue = true
        })
    }
    
    // MARK: - Header (pushed from Home)
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
                morphID: "topControl_left",
                namespace: topControlsNamespace
            ) {
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }
            
            Spacer()
            
            Text("Accounts")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            GlassCircleButton(
                icon: "plus",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .light,
                accessibilityLabel: "Add Account"
            ) {
                showAddAccount = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
    
    private var netWorthSparklinePoints: [CGFloat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayCount = 14
        
        var running = store.totalBalance
        var values: [Double] = []
        var cursor = today
        
        for _ in 0..<dayCount {
            values.append(running)
            let dayStart = cursor
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            let dayTxs = store.transactions.filter {
                $0.date >= dayStart && $0.date < dayEnd && $0.type != .transfer
            }
            for tx in dayTxs {
                if tx.type == .income {
                    running -= tx.amount
                } else if tx.type == .expense {
                    running += tx.amount
                }
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor), previous < cursor else { break }
            cursor = previous
        }
        
        values.reverse()
        guard values.count >= 2 else { return [0.5, 0.5] }
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 1
        let span = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal)
        return values.map { CGFloat(($0 - minVal) / span) }
    }
    
    private var sparklineColor: Color {
        guard let first = netWorthSparklinePoints.first, let last = netWorthSparklinePoints.last else {
            return SpendyColors.textPrimary
        }
        if last >= first { return SpendyColors.incomeGreen }
        return SpendyColors.expenseRed
    }
    
    // MARK: - Summary card
    private var summaryCard: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Total balance")
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Text(store.totalBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 2))
                    .font(.system(size: 32, weight: .heavy, design: .default))
                    .monospacedDigit()
                    .tracking(-1.0)
                    .foregroundStyle(store.totalBalance < 0 ? SpendyColors.expenseRed : SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .contentTransition(.numericText())
                
                summaryMetaLine
            }
            
            Spacer(minLength: 8)
            
            SparklineView(
                points: netWorthSparklinePoints,
                color: sparklineColor,
                style: .area,
                height: 48,
                lineWidth: 2.2,
                showEndpoint: true
            )
            .frame(width: 112, height: 48)
            .accessibilityHidden(true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { groupedCardBackground }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total balance \(store.totalBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 2))")
    }
    
    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SpendyInsightBrandMark(style: .kicker, showsPersonalization: false)
            insightPager
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { groupedCardBackground }
    }
    
    private var summaryMetaLine: some View {
        let flow = thisMonthFlow
        return HStack(spacing: 6) {
            if flow.inflow > 0 || flow.outflow > 0 {
                Text("+\(flow.inflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) in")
                    .font(AppTypography.footnoteMedium)
                    .foregroundStyle(SpendyColors.incomeGreen)
                Text("·")
                    .foregroundStyle(SpendyColors.textTertiary)
                Text("−\(flow.outflow.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) out")
                    .font(AppTypography.footnoteMedium)
                    .foregroundStyle(SpendyColors.textSecondary)
            } else {
                Text("\(sortedAccounts.count) \(sortedAccounts.count == 1 ? "account" : "accounts")")
                    .font(AppTypography.footnoteMedium)
                    .foregroundStyle(SpendyColors.textSecondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    
    private var insightPager: some View {
        VStack(spacing: 8) {
            if cardInsights.count == 1, let only = cardInsights.first {
                insightRow(only)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(cardInsights) { item in
                            insightRow(item)
                                .containerRelativeFrame(.horizontal)
                                .clipped()
                                .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $insightPage)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("accounts-insight-pager")
                .onChange(of: insightPage) { _, _ in
                    HapticsManager.shared.trigger(.selection)
                }
                
                HStack(spacing: 5) {
                    ForEach(cardInsights) { item in
                        Capsule()
                            .fill(item.id == (insightPage ?? cardInsights.first?.id) ? SpendyColors.textPrimary : SpendyColors.textTertiary.opacity(0.35))
                            .frame(width: item.id == (insightPage ?? cardInsights.first?.id) ? 12 : 5, height: 5)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            }
        }
        .onChange(of: cardInsights.map(\.id)) { _, _ in
            insightPage = cardInsights.first?.id
        }
        .accessibilityHint(cardInsights.count > 1 ? "Swipe left or right for more insights" : "")
    }
    
    private func insightRow(_ item: AccountInsight) -> some View {
        Group {
            if let account = item.account {
                Button {
                    HapticsManager.shared.trigger(.selection)
                    selectedAccountForAnalytics = account
                } label: {
                    insightContent(item)
                }
                .buttonStyle(.plain)
            } else {
                insightContent(item)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("accounts-insight-\(item.id)")
    }

    private func insightContent(_ item: AccountInsight) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.account.map { $0.sfSymbol.isEmpty ? $0.type.defaultSymbol : $0.sfSymbol } ?? "arrow.left.arrow.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
                .frame(width: 22, height: 22)
                .padding(.top, 1)
                .symbolRenderingMode(.monochrome)

            VStack(alignment: .leading, spacing: 3) {
                ShinyHeadlineText(
                    headline: item.headline,
                    emphasis: item.account.map { [.highlight($0.label)] } ?? [.highlight("ahead"), .highlight("behind")],
                    font: .subheadline.weight(.semibold),
                    emphasisFont: .subheadline.bold()
                )
                .fixedSize(horizontal: false, vertical: true)

                InsightSupportingText(text: item.supporting, emphasis: [])
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.top, 4)
                .opacity(item.account == nil ? 0 : 1)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
        .contentShape(Rectangle())
    }
    
    // MARK: - Grouped list
    private var accountsList: some View {
        Group {
            if sortedAccounts.isEmpty {
                SpendyPlainEmptyState(
                    title: "No accounts yet",
                    message: "Add a wallet, bank, or savings account to start tracking",
                    icon: "creditcard",
                    actionTitle: "Add account"
                ) {
                    showAddAccount = true
                }
            } else {
                SpendyGroupedList(items: sortedAccounts,
                    background: isSettingsPage ? SpendyColors.settingsCardBackground : SpendyColors.cardBackground) { account in
                    accountRow(account)
                }
            }
        }
    }
    
    private func accountRow(_ account: Account) -> some View {
        let bal = store.balance(for: account.id)
        
        return Button {
            HapticsManager.shared.trigger(.selection)
            selectedAccountForAnalytics = account
        } label: {
            SpendyListRow {
                SpendyIconBadge(
                    sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                    color: account.color,
                    size: .medium,
                    style: .rounded(),
                    monogramName: account.label
                )
                
            } content: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(account.label)
                        .font(AppTypography.rowTitle)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(account.type.rawValue)
                        .font(AppTypography.footnoteMedium)
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                }
            } value: {
                Text(bal.formattedCurrency(symbol: store.currencySymbol, decimals: 2))
                    .spendyRowAmount()
                    .foregroundStyle(bal < 0 ? SpendyColors.expenseRed : SpendyColors.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                HapticsManager.shared.trigger(.light)
                selectedAccountForAnalytics = account
            } label: {
                Label("View Analytics", systemImage: "chart.bar.xaxis")
            }
            Button {
                HapticsManager.shared.trigger(.light)
                editingAccount = account
            } label: {
                Label("Edit Account", systemImage: "pencil")
            }
        }
        .accessibilityLabel("\(account.label), \(account.type.rawValue), \(bal.formattedCurrency(symbol: store.currencySymbol, decimals: 2))")
        .accessibilityIdentifier("account-row-\(account.id)")
    }
}
