//
//  AccountsView.swift
//  Spendy
//
//  Compact balance summary and grouped account directory.
//

import SwiftUI

struct AccountsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .title) private var balanceFontSize = 28.0
    
    var isSettingsPage: Bool = false
    var onDismiss: (() -> Void)? = nil
    var topControlsNamespace: Namespace.ID? = nil
    var sharedNavigationHeader: AnalyticsNavigationHeaderState? = nil
    
    @State private var showAddAccount: Bool = false
    @State private var editingAccount: Account? = nil
    @State private var selectedAccountForAnalytics: Account? = nil
    
    private var sortedAccounts: [Account] {
        store.accounts.sorted { $0.order < $1.order }
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
                    VStack(alignment: .leading, spacing: 20) {
                        balanceAmount
                        if store.insightsEnabled && !sortedAccounts.isEmpty {
                            SpendyInsightSummary(moments: accountInsights)
                                .padding(.horizontal, 4)
                        }
                        accountsList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
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
    
    // MARK: - Balance
    private var thisMonthFlow: (income: Double, expenses: Double) {
        let now = Date()
        let calendar = Calendar.current
        let transactions = store.transactions.filter {
            $0.date <= now && calendar.isDate($0.date, equalTo: now, toGranularity: .month)
                && $0.amount.isFinite && $0.amount >= 0
        }
        return (
            transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount },
            transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        )
    }

    private var balanceAmount: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total balance")
                .font(.subheadline)
                .foregroundStyle(SpendyColors.textSecondary)
            Text(store.totalBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 2))
                .font(.system(size: balanceFontSize, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(SpendyColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("accounts-total-balance")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var accountInsights: [InsightMoment] {
        var moments: [InsightMoment] = []
        let balances = sortedAccounts.map { (account: $0, balance: store.balance(for: $0.id)) }
        let belowZero = balances.filter { $0.balance < 0 }
        if let lowest = belowZero.min(by: { $0.balance < $1.balance }) {
            moments.append(InsightMoment(
                id: "accounts-below-zero", candidateId: "accounts-below-zero",
                kind: .warning, family: .spending, surface: .analytics,
                headline: "\(lowest.account.label) has a negative balance",
                supportingText: "Recorded balance: \(lowest.balance.formattedCurrency(symbol: store.currencySymbol, decimals: 2)). This can include money owed.",
                emphasis: [.highlight(lowest.account.label)],
                attentionPriority: 1, attentionLabel: "Negative balance"
            ))
        }

        let (income, expenses) = thisMonthFlow
        if income > 0 || expenses > 0 {
            moments.append(InsightMoment(
                id: "accounts-month-flow", candidateId: "accounts-month-flow",
                kind: .observation, family: .income, surface: .analytics,
                headline: "Money in and out this month",
                supportingText: "\(income.formattedCurrency(symbol: store.currencySymbol, decimals: 2)) recorded income · \(expenses.formattedCurrency(symbol: store.currencySymbol, decimals: 2)) recorded expenses. Transfers between accounts are excluded."
            ))
        }

        let positiveTotal = balances.reduce(0) { $0 + max(0, $1.balance) }
        if balances.count > 1, positiveTotal > 0,
           let largest = balances.max(by: { $0.balance < $1.balance }) {
            let share = (largest.balance / positiveTotal * 100).formatted(.number.precision(.fractionLength(0)))
            moments.append(InsightMoment(
                id: "accounts-largest-balance", candidateId: "accounts-largest-balance",
                kind: .observation, family: .spending, surface: .analytics,
                headline: "\(largest.account.label) has your largest balance",
                supportingText: "\(share)% of your positive recorded balances.",
                emphasis: [.highlight(largest.account.label)]
            ))
        }

        if moments.isEmpty {
            moments.append(InsightMoment(
                id: "accounts-recorded-balance", candidateId: "accounts-recorded-balance",
                kind: .observation, family: .spending, surface: .analytics,
                headline: "Your recorded account balance",
                supportingText: "\(store.totalBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 2)) across your accounts, based on opening balances and recorded transactions."
            ))
        }
        return moments
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
                    background: isSettingsPage ? SpendyColors.settingsCardBackground : SpendyColors.cardBackground,
                    iconWidth: 44) { account in
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
            SpendyRowContent(spacing: 12, iconWidth: 44) {
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
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
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
        .accessibilityLabel("\(account.label), \(account.type.rawValue), \(bal.formattedCurrency(symbol: store.currencySymbol, decimals: 2))")
        .accessibilityIdentifier("account-row-\(account.id)")
    }
}
