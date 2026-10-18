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
    
    @State private var showAddAccount: Bool = false
    @State private var editingAccount: Account? = nil
    @State private var selectedAccountForAnalytics: Account? = nil
    @State private var insightPage: Int = 0
    
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

                if topControlsNamespace != nil {
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
        .toolbar(topControlsNamespace != nil ? .hidden : .visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if topControlsNamespace == nil {
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
            AccountAnalyticsSheet(account: acc, isSettingsPage: isSettingsPage)
        }
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
            SpendyInsightBrandMark(style: .kicker)
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
                TabView(selection: $insightPage) {
                    ForEach(Array(cardInsights.enumerated()), id: \.element.id) { index, item in
                        insightRow(item)
                            .tag(index)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 58)
                .onChange(of: insightPage) { _, _ in
                    HapticsManager.shared.trigger(.selection)
                }
                
                HStack(spacing: 5) {
                    ForEach(0..<cardInsights.count, id: \.self) { index in
                        Capsule()
                            .fill(index == insightPage ? SpendyColors.textPrimary : SpendyColors.textTertiary.opacity(0.35))
                            .frame(width: index == insightPage ? 12 : 5, height: 5)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            }
        }
        .onChange(of: cardInsights.map(\.id)) { _, _ in
            insightPage = 0
        }
        .accessibilityHint(cardInsights.count > 1 ? "Swipe left or right for more insights" : "")
    }
    
    private func insightRow(_ item: AccountInsight) -> some View {
        Button {
            HapticsManager.shared.trigger(.selection)
            if let account = item.account {
                selectedAccountForAnalytics = account
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                if let account = item.account {
                    Image(systemName: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                        .frame(width: 22, height: 22)
                        .padding(.top, 1)
                        .symbolRenderingMode(.monochrome)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    ShinyHeadlineText(
                        headline: item.headline,
                        emphasis: item.account.map { [.highlight($0.label)] } ?? [.highlight("ahead"), .highlight("behind")],
                        font: .system(size: 15, weight: .semibold),
                        emphasisFont: .system(size: 15, weight: .bold)
                    )
                    .lineLimit(2)
                    
                    InsightSupportingText(text: item.supporting, emphasis: [])
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                if item.account != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                        .padding(.top, 4)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(item.account == nil)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(item.account == nil ? [] : .isButton)
    }
    
    // MARK: - Grouped list
    private var accountsList: some View {
        Group {
            if sortedAccounts.isEmpty {
                SpendyEmptyCardView(
                    icon: "creditcard",
                    iconColor: SpendyColors.primaryBlue,
                    title: "No accounts yet",
                    subtitle: "Add a wallet, bank, or savings account to start tracking",
                    actionTitle: "Add Account",
                    isEnclosedInCard: true
                ) {
                    showAddAccount = true
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedAccounts.enumerated()), id: \.element.id) { index, account in
                        accountRow(account)
                        if index < sortedAccounts.count - 1 {
                            Rectangle()
                                .fill(SpendyColors.separator.opacity(0.6))
                                .frame(height: 0.5)
                                .padding(.leading, 74)
                                .padding(.trailing, 16)
                        }
                    }
                }
                .background { groupedCardBackground }
            }
        }
    }
    
    private func accountRow(_ account: Account) -> some View {
        let bal = store.balance(for: account.id)
        
        return Button {
            HapticsManager.shared.trigger(.selection)
            selectedAccountForAnalytics = account
        } label: {
            HStack(alignment: .center, spacing: 14) {
                SpendyIconBadge(
                    sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                    color: account.color,
                    size: .medium,
                    style: .rounded(),
                    monogramName: account.label
                )
                
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
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(bal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 16.5, weight: .bold, design: .default))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .layoutPriority(1)
                    .foregroundStyle(bal < 0 ? SpendyColors.expenseRed : SpendyColors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
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
        .accessibilityLabel("\(account.label), \(account.type.rawValue), \(bal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
    }
}
