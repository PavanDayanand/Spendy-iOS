//
//  AllTransactionsView.swift
//  Spendy
//
//  Clean Full-Screen Transactions View:
//  - Top Sticky Layer: Liquid Glass Circular Back Button + "All Transactions" Title + 3 Liquid Glass Filter Toggles (Floating on Top Layer)
//  - Individual Transaction Cards with SpendyIconBadge, Title, Mini Bank Indicator & Formatted Amount
//  - Lowered Floating Liquid Glass Search Bar + Liquid Glass Quick Add (+) Button on Bottom Layer
//

import SwiftUI

struct AllTransactionsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var usesSharedHeader: Bool = false
    var areFiltersExpanded: Bool = true
    var onDismiss: (() -> Void)? = nil
    var topControlsNamespace: Namespace.ID? = nil
    
    // Optional chart scope stays applied even when the browser filters change.
    var spendingScope: SpendingScope? = nil
    var scopeStart: Date? = nil
    var scopeEnd: Date? = nil
    var scopeAccountID: String? = nil
    var scopeTitle: String? = nil

    // Search & Filters
    @State private var pinnedHeaderHeight: CGFloat = 116
    @State private var searchQuery: String = ""
    @State private var selectedCategoryIDs: Set<String>? = nil
    @State private var showsCategoryFilter = false
    @State private var showsAccountFilter = false
    @State private var selectedAccountId: String? = nil
    @State private var selectedTransactionType: TransactionType? = nil
    @FocusState private var isSearchFocused: Bool
    @Namespace private var allTransactionsNamespace
    
    // Sheets
    @State private var pendingTransactionEdit: Transaction? = nil
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var showAddTransaction: Bool = false
    
    // MARK: - Filtered Transactions
    private var filteredTransactions: [Transaction] {
        var txs = store.transactions.filter { spendingScope?.contains($0) ?? true }
        if let scopeStart, let scopeEnd {
            txs = txs.filter { $0.type == .expense && $0.date >= scopeStart && $0.date < scopeEnd && $0.date <= (spendingScope?.referenceDate ?? Date()) && $0.amount.isFinite && $0.amount >= 0 }
        }
        if let scopeAccountID, scopeAccountID != "all" {
            txs = txs.filter { $0.accountId == scopeAccountID }
        }
        
        // 1. Type Filter
        if let type = selectedTransactionType {
            txs = txs.filter { $0.type == type }
        }
        
        // 2. Category Filter
        if let selectedCategoryIDs {
            txs = txs.filter { $0.type != .transfer && selectedCategoryIDs.contains($0.categoryId) }
        }
        
        // 3. Account Filter
        if let accId = selectedAccountId {
            txs = txs.filter { $0.accountId == accId || $0.toAccountId == accId }
        }
        
        // 4. Search Query
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            txs = txs.filter { tx in
                let cat = store.displayCategory(for: tx)
                let acc = store.account(for: tx.accountId)
                return store.displayTitle(for: tx).lowercased().contains(query) ||
                       (tx.notes?.lowercased().contains(query) ?? false) ||
                       cat.label.lowercased().contains(query) ||
                       acc.label.lowercased().contains(query)
            }
        }
        
        return txs.sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Date Grouped Tuples: (DateTitle, GroupNetTotal, [Transaction])
    private var groupedTransactions: [(String, Double, [Transaction])] {
        let calendar = Calendar.current
        var groups: [String: [Transaction]] = [:]
        var order: [String] = []
        
        for tx in filteredTransactions {
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
    
    // MARK: - Labels
    private var categoryFilterItems: [AnalyticsBreakdownItem] {
        store.categories.filter { (spendingScope?.categoryIDs?.contains($0.id) ?? true) && (scopeStart == nil || $0.type == .expense) }.map {
            AnalyticsBreakdownItem(id: $0.id, label: $0.label, sfSymbol: $0.sfSymbol,
                colorHex: $0.colorHex, txCount: 0, amount: 0, percentage: 0)
        }
    }

    private var categoryButtonLabel: String {
        if let selectedCategoryIDs {
            if selectedCategoryIDs.count == 1, let id = selectedCategoryIDs.first { return store.category(for: id).label }
            return "Categories · \(selectedCategoryIDs.count)"
        }
        if let ids = spendingScope?.categoryIDs { return "Categories · \(ids.count)" }
        return "Categories"
    }

    private var accountButtonLabel: String {
        if let accId = selectedAccountId, let acc = store.accounts.first(where: { $0.id == accId }) {
            return acc.label
        }
        if let ids = spendingScope?.accountIDs {
            if ids.count == 1, let id = ids.first { return store.account(for: id).label }
            return "Accounts · \(ids.count)"
        }
        return "Accounts"
    }
    
    private var typeButtonLabel: String {
        if scopeStart != nil || spendingScope != nil { return "Expenses" }
        switch selectedTransactionType {
        case .expense: return "Expenses"
        case .income: return "Income"
        case .transfer: return "Transfers"
        case .none: return "All Types"
        }
    }
    
    private var pinnedHeader: some View {
        VStack(spacing: 0) {
            if usesSharedHeader {
                Color.clear.frame(height: 56)
                    .accessibilityHidden(true)
            } else {
                topHeaderBar
            }
            if let scopeStart, let scopeEnd {
                VStack(spacing: 3) {
                    Text("Expenses · \(spendingScope?.accountIDs != nil ? accountButtonLabel : (store.accounts.first { $0.id == scopeAccountID }?.label ?? "All accounts"))")
                    if let ids = spendingScope?.categoryIDs { Text("\(ids.count) selected categories") }
                    Text(scopeStart.formatted(.dateTime.day().month(.abbreviated).year()) + " – " + scopeEnd.addingTimeInterval(-0.000001).formatted(.dateTime.day().month(.abbreviated).year()))
                }
                .font(.caption).foregroundStyle(SpendyColors.textSecondary)
                .padding(.vertical, 6)
            }

            // Horizontal Scrollable Liquid Glass Filter Capsules
            if areFiltersExpanded {
                horizontalFilterBar
                    .padding(.vertical, 8)
                    .transition(.opacity)
                    .accessibilityIdentifier("transaction-filters")
            }
        }
        .animation(reduceMotion ? nil : AppMotion.fluidSpring, value: areFiltersExpanded)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { pinnedHeaderHeight = $0 }

    }

    // MARK: - Body
    var body: some View {
        GeometryReader { viewport in
            ZStack {
                // Clean Background
                SpendyColors.appBackground
                    .ignoresSafeArea()
            
                ZStack(alignment: .top) {
                    // Scrollable Content Layer
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            // Grouped Transactions List
                            if filteredTransactions.isEmpty {
                                emptyStateView
                                    .frame(minHeight: max(0, viewport.size.height - pinnedHeaderHeight - 110))
                                    .frame(maxWidth: .infinity)
                            } else {
                                LazyVStack(spacing: 20) {
                                    ForEach(groupedTransactions, id: \.0) { groupTitle, groupNet, txs in
                                        VStack(alignment: .leading, spacing: 10) {
                                            // Section Header: Date (Left) & Group Total (Right)
                                            HStack {
                                                Text(groupTitle)
                                                    .font(AppTypography.subheadlineSemibold)
                                                    .foregroundStyle(SpendyColors.textSecondary)
                                            
                                                Spacer()
                                            
                                                Text(formattedGroupNetTotal(groupNet))
                                                    .spendyNumberFont(size: 14, weight: .medium, tracking: -0.2)
                                                    .foregroundStyle(SpendyColors.textTertiary)
                                            }
                                            .padding(.horizontal, 4)
                                        
                                            // Individual Transaction Cards (Matching Category Card Design)
                                            VStack(spacing: 12) {
                                                ForEach(txs) { tx in
                                                    transactionCard(tx)
                                                        .accessibilityIdentifier("spending-transaction-\(tx.id)")
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 2)
                                .padding(.bottom, 110) // Clearance for floating bottom search & add bar
                            }
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .safeAreaBar(edge: .top, spacing: 0) {
                        // Keep the live filters in their existing overlay, while registering
                        // its measured height for the system's scroll-edge treatment.
                        Color.clear.frame(height: pinnedHeaderHeight).accessibilityHidden(true)
                    }
                    .scrollEdgeEffectStyle(.soft, for: .top)
                    .accessibilityIdentifier("allTransactionsViewport")

                    pinnedHeader.zIndex(1)

                }
            
                // Floating Bottom Liquid Glass Search Bar + Quick Add (+) Button on Top Layer
                VStack {
                    Spacer()
                    floatingBottomBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
                .zIndex(100)
            }
        }
        .navigationTitle(scopeTitle ?? "All Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
        .fullScreenCover(item: $editingTransaction) { tx in
            AddTransactionView(transactionToEdit: tx)
        }
        .sheet(isPresented: $showsCategoryFilter) {
            SpendingBreakdownFilter(items: categoryFilterItems, byCategory: true, selectedIDs: $selectedCategoryIDs)
        }
        .sheet(isPresented: $showsAccountFilter) {
            ReceiptAccountPicker(selectedAccountId: Binding(
                get: { selectedAccountId ?? "all" },
                set: { selectedAccountId = $0 == "all" ? nil : $0 }
            ), title: "Accounts",
                accounts: store.accounts.filter { spendingScope?.accountIDs?.contains($0.id)
                    ?? (scopeAccountID == nil || scopeAccountID == "all" || scopeAccountID == $0.id) },
                currencySymbol: store.currencySymbol, showsAllAccounts: true)
        }
        .sheet(item: $inspectingTransaction, onDismiss: {
            editingTransaction = pendingTransactionEdit
            pendingTransactionEdit = nil
        }) { tx in
            TransactionDetailSheet(transaction: tx) { txToEdit in
                pendingTransactionEdit = txToEdit
                inspectingTransaction = nil
            }
        }
    }
    
    private var topHeaderBar: some View {
        HStack {
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 15,
                accessibilityLabel: "Back",
                morphID: "topControl_left",
                namespace: topControlsNamespace
            ) {
                if let onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }
            Spacer()
            Text(scopeTitle ?? "All Transactions")
                .font(.headline)
                .foregroundStyle(SpendyColors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - 2. Horizontal Scrollable Liquid Glass Filter Capsules (On Top Layer)
    private var horizontalFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Shared searchable, multi-select category picker.
                Button { showsCategoryFilter = true } label: {
                    let isCatSelected = selectedCategoryIDs != nil || spendingScope?.categoryIDs != nil
                    SpendyFilterControl(title: categoryButtonLabel, systemImage: "circle.grid.2x2",
                        isSelected: isCatSelected,
                        selectedSymbol: (selectedCategoryIDs ?? spendingScope?.categoryIDs)?.first.map { store.category(for: $0).sfSymbol },
                        selectionCount: (selectedCategoryIDs ?? spendingScope?.categoryIDs)?.count ?? 0,
                        size: .small)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("transactions-filter-category")
                
                // Match the category control with the existing account picker drawer.
                Button { showsAccountFilter = true } label: {
                    let isAccSelected = selectedAccountId != nil || spendingScope?.accountIDs != nil
                        || (scopeAccountID != nil && scopeAccountID != "all")
                    SpendyFilterControl(title: accountButtonLabel, systemImage: "building.columns",
                        isSelected: isAccSelected,
                        selectedSymbol: selectedAccountId.map { store.account(for: $0).sfSymbol }
                            ?? spendingScope?.accountIDs?.first.map { store.account(for: $0).sfSymbol }
                            ?? scopeAccountID.map { store.account(for: $0).sfSymbol },
                        selectionCount: selectedAccountId != nil ? 1 : spendingScope?.accountIDs?.count ?? 1,
                        size: .small)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("transactions-filter-account")
                
                // 3. [Type] Liquid Glass Menu (Expenses, Income, Transfers)
                Menu {
                    Picker("Transaction Type", selection: $selectedTransactionType) {
                        Text("All Types").tag(nil as TransactionType?)
                        Label("Expenses", systemImage: TransactionType.expense.sfSymbol).tag(Optional(TransactionType.expense))
                        if scopeStart == nil && spendingScope == nil {
                            Label("Income", systemImage: TransactionType.income.sfSymbol).tag(Optional(TransactionType.income))
                            Label("Transfers", systemImage: TransactionType.transfer.sfSymbol).tag(Optional(TransactionType.transfer))
                        }
                    }
                } label: {
                    let isTypeSelected = selectedTransactionType != nil || spendingScope != nil || scopeStart != nil
                    SpendyFilterControl(title: typeButtonLabel, systemImage: "arrow.up.arrow.down",
                        isSelected: isTypeSelected,
                        selectedSymbol: selectedTransactionType?.sfSymbol ?? "arrow.up.right",
                        size: .small)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("transactions-filter-type")
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 16)
        }
        .accessibilityIdentifier("transactionFilters")
    }
    
    // MARK: - 3. Individual Transaction Card (Matching Category Card Design)
    private func transactionCard(_ tx: Transaction) -> some View {
        let cat: Category? = store.displayCategory(for: tx)
        let acc = store.accounts.first(where: { $0.id == tx.accountId })
        let subscription = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == tx.subscriptionId?.lowercased() })
        
        let iconSymbol = subscription?.sfSymbol ?? (cat?.sfSymbol ?? "cart.fill")
        let iconColor = subscription?.color ?? (cat?.color ?? Color(hex: "#FF5924"))
        let iconName = subscription?.name ?? cat?.label ?? tx.title
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            inspectingTransaction = tx
        }) {
            HStack(spacing: 14) {
                // Category / Subscription Icon Avatar Badge
                SpendyIconBadge(
                    sfSymbol: iconSymbol,
                    color: iconColor,
                    size: .medium,
                    style: .circle,
                    monogramName: iconName
                )
                
                // Title and Account Pill Indicator
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.displayTitle(for: tx))
                        .font(AppTypography.rowTitle)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    if let acc = acc {
                        HStack(spacing: 5) {
                            SpendyMiniColorChip(
                                sfSymbol: acc.sfSymbol.isEmpty ? acc.type.defaultSymbol : acc.sfSymbol,
                                color: acc.color,
                                monogramName: acc.label
                            )
                            
                            Text(tx.type == .transfer ? store.transferAccountRoute(for: tx) : acc.label)
                                .font(AppTypography.footnoteMedium)
                                .foregroundStyle(SpendyColors.textSecondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text(tx.date.formattedRelative)
                            .font(AppTypography.footnoteMedium)
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Formatted Amount and Relative Date
                VStack(alignment: .trailing, spacing: 3) {
                    Text(formattedRowAmountWithSign(tx))
                        .spendyNumberFont(size: 17, weight: .bold, tracking: -0.5)
                        .foregroundStyle(rowAmountColor(tx))
                    
                    Text(tx.date.formattedRelative)
                        .font(AppTypography.captionMedium)
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
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
        .accessibilityLabel("\(store.displayTitle(for: tx)), \(tx.type == .transfer ? store.displayCategory(for: tx).label : ""), \(tx.type == .income ? "Income" : (tx.type == .transfer ? "Transfer" : "Expense")), \(tx.amount.formattedCurrency(symbol: store.currencySymbol)), \(acc?.label ?? ""), \(tx.date.formattedRelative)")
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
    
    private func formattedRowAmountWithSign(_ tx: Transaction) -> String {
        let sym = store.currencySymbol
        let amtStr = tx.amount.formattedCurrency(symbol: sym)
        switch tx.type {
        case .expense: return amtStr
        case .income: return "+\(amtStr)"
        case .transfer: return amtStr
        }
    }
    
    private func formattedGroupNetTotal(_ net: Double) -> String {
        let sym = store.currencySymbol
        let absFormatted = abs(net).formattedCurrency(symbol: sym, decimals: 0)
        if net < 0 {
            return "-\(absFormatted)"
        } else if net > 0 {
            return "+\(absFormatted)"
        } else {
            return absFormatted
        }
    }
    
    // MARK: - 4. Floating Bottom Liquid Glass Search Bar + Liquid Glass Quick Add (+) Button
    private var floatingBottomBar: some View {
        let isSearchActive = isSearchFocused || !searchQuery.isEmpty
        return SpendyGlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                // Liquid Glass Search Capsule (Smoothly expands to full width when focused or containing text)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    TextField("Search transactions", text: $searchQuery)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                    
                    if isSearchActive {
                        Button {
                            HapticsManager.shared.trigger(.tick)
                            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.82)) {
                                searchQuery = ""
                                isSearchFocused = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(SpendyColors.textTertiary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, isSearchActive ? 4 : 16)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .nativeLiquidGlassCapsule(isInteractive: true)
                .glassMorphID("transactionsSearchCapsule", in: allTransactionsNamespace)
                
                if !isSearchActive {
                    // Liquid Glass Floating Quick Add Button (+)
                    Button {
                        HapticsManager.shared.trigger(.cardSnap)
                        showAddTransaction = true
                    } label: {
                        ZStack {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                                .frame(width: 50, height: 50)
                                .nativeLiquidGlassCircle(isInteractive: true)
                        }
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add Transaction")
                    .glassMorphID("transactionsAddButton", in: allTransactionsNamespace)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.82), value: isSearchActive)
        }
    }
    
    private var emptyStateView: some View {
        let hasFilters = !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedCategoryIDs != nil || selectedAccountId != nil || selectedTransactionType != nil
        let isScoped = spendingScope != nil || scopeStart != nil || scopeAccountID != nil
        return ContentUnavailableView {
            Label(hasFilters ? "No matching transactions" : "No transactions yet",
                  systemImage: hasFilters ? "magnifyingglass" : "list.bullet.rectangle")
        } description: {
            Text(hasFilters ? "Try clearing your search and filters."
                : isScoped ? "No transactions recorded for this selection." : "Add your first transaction to start tracking.")
        } actions: {
            if hasFilters || !isScoped {
                Button(hasFilters ? "Clear search and filters" : "Add transaction") {
                    if hasFilters {
                        searchQuery = ""
                        selectedCategoryIDs = nil
                        selectedAccountId = nil
                        selectedTransactionType = nil
                        isSearchFocused = false
                    } else { showAddTransaction = true }
                }
                .buttonStyle(.plain)
                .font(.body.weight(.semibold))
                .frame(minHeight: 44)
            }
        }
        .accessibilityIdentifier("transactions-empty-state")
    }

}

#Preview {
    AllTransactionsView()
        .environment(ExpenseStore())
}
