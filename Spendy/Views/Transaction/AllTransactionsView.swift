//
//  AllTransactionsView.swift
//  Spendy
//
//  Clean Full-Screen Transactions View:
//  - Top Bar: Working Circular Glass Back Button (Left) + "Transactions" Title (Center)
//  - Horizontal Scrolling Liquid Glass Filter Toggles: [Categories] [Accounts] [Type]
//  - Clean Solid Background (No weird grey boxes or gradient leaks)
//  - Individual Transaction Cards with Category Avatar, Title, Mini Bank Badge & Formatted Amount
//  - Lowered Floating Liquid Glass Search Bar + Liquid Glass Quick Add (+) Button
//

import SwiftUI

struct AllTransactionsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var onDismiss: (() -> Void)? = nil
    
    // Search & Filters
    @State private var searchQuery: String = ""
    @State private var selectedCategoryId: String? = nil
    @State private var selectedAccountId: String? = nil
    @State private var selectedTransactionType: TransactionType? = nil
    
    // Sheets
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    @State private var pendingEditTransaction: Transaction? = nil
    @State private var lastInspectedTransaction: Transaction? = nil
    @State private var showAddTransaction: Bool = false
    
    // MARK: - Filtered Transactions
    private var filteredTransactions: [Transaction] {
        var txs = store.transactions
        
        // 1. Type Filter
        if let type = selectedTransactionType {
            txs = txs.filter { $0.type == type }
        }
        
        // 2. Category Filter
        if let catId = selectedCategoryId {
            txs = txs.filter { $0.categoryId == catId }
        }
        
        // 3. Account Filter
        if let accId = selectedAccountId {
            txs = txs.filter { $0.accountId == accId || $0.toAccountId == accId }
        }
        
        // 4. Search Query
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            txs = txs.filter { tx in
                let cat = store.categories.first(where: { $0.id == tx.categoryId })
                let acc = store.accounts.first(where: { $0.id == tx.accountId })
                return tx.title.lowercased().contains(query) ||
                       (tx.notes?.lowercased().contains(query) ?? false) ||
                       (cat?.label.lowercased().contains(query) ?? false) ||
                       (acc?.label.lowercased().contains(query) ?? false)
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
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMM"
                key = formatter.string(from: tx.date)
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
    private var categoryButtonLabel: String {
        if let catId = selectedCategoryId, let cat = store.categories.first(where: { $0.id == catId }) {
            return cat.label
        }
        return "Categories"
    }
    
    private var accountButtonLabel: String {
        if let accId = selectedAccountId, let acc = store.accounts.first(where: { $0.id == accId }) {
            return acc.label
        }
        return "Accounts"
    }
    
    private var typeButtonLabel: String {
        switch selectedTransactionType {
        case .expense: return "Expenses"
        case .income: return "Income"
        case .transfer: return "Transfers"
        case .none: return "All Types"
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            // Clean Background
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Top Navigation Bar (Back Button + Title)
                topNavBar
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 10)
                
                // 2. Horizontal Scrollable Filter Capsules
                horizontalFilterBar
                    .padding(.bottom, 12)
                
                // 3. Transactions List
                if filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 20) {
                            ForEach(groupedTransactions, id: \.0) { groupTitle, groupNet, txs in
                                VStack(alignment: .leading, spacing: 10) {
                                    // Section Header: Date (Left) & Group Total (Right)
                                    HStack {
                                        Text(groupTitle)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(SpendyColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Text(formattedGroupNetTotal(groupNet))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(SpendyColors.textTertiary)
                                    }
                                    .padding(.horizontal, 4)
                                    
                                    // Individual Transaction Cards
                                    VStack(spacing: 10) {
                                        ForEach(txs) { tx in
                                            transactionCard(tx)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 2)
                        .padding(.bottom, 110) // Clearance for floating bottom search & add bar
                    }
                }
            }
            
            // 4. Floating Bottom Liquid Glass Search Bar + Quick Add (+) Button
            floatingBottomBar
                .padding(.horizontal, 16)
                .padding(.bottom, 0)
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
        .sheet(item: $editingTransaction, onDismiss: {
            if let last = lastInspectedTransaction {
                let fresh = store.transactions.first(where: { $0.id == last.id }) ?? last
                lastInspectedTransaction = nil
                pendingEditTransaction = fresh
            }
            if let pending = pendingEditTransaction {
                pendingEditTransaction = nil
                inspectingTransaction = pending
            }
        }) { tx in
            AddTransactionView(transactionToEdit: tx)
        }
        .sheet(item: $inspectingTransaction, onDismiss: {
            if let pending = pendingEditTransaction {
                pendingEditTransaction = nil
                editingTransaction = pending
            }
        }) { tx in
            TransactionDetailSheet(transaction: tx) { txToEdit in
                lastInspectedTransaction = tx
                pendingEditTransaction = txToEdit
                inspectingTransaction = nil
            }
        }
    }
    
    // MARK: - 1. Top Navigation Bar (Reliable Back Button)
    private var topNavBar: some View {
        HStack(alignment: .center) {
            // Circular Glass Back Button
            Button(action: {
                HapticsManager.shared.trigger(.light)
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(SpendyColors.cardBackground)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Circle().stroke(SpendyColors.separator, lineWidth: 1)
                        }
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            
            Spacer()
            
            // Center Title
            Text("Transactions")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            // Symmetrical Spacer
            Color.clear
                .frame(width: 44, height: 44)
        }
    }
    
    // MARK: - 2. Horizontal Scrollable Filter Capsules
    private var horizontalFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // [Categories] Menu
                Menu {
                    Button("All Categories") {
                        withAnimation { selectedCategoryId = nil }
                    }
                    Divider()
                    ForEach(store.categories) { cat in
                        Button(cat.label) {
                            withAnimation { selectedCategoryId = cat.id }
                        }
                    }
                } label: {
                    let isCatSelected = selectedCategoryId != nil
                    HStack(spacing: 6) {
                        Image(systemName: "circle.grid.2x2")
                            .font(.system(size: 13, weight: .semibold))
                        Text(categoryButtonLabel)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(isCatSelected ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background {
                        Capsule()
                            .fill(SpendyColors.cardBackground)
                            .overlay {
                                Capsule()
                                    .stroke(isCatSelected ? SpendyColors.textPrimary.opacity(0.85) : SpendyColors.separator, lineWidth: isCatSelected ? 1.4 : 0.8)
                            }
                    }
                }
                .buttonStyle(.plain)
                
                // [Accounts] Menu
                Menu {
                    Button("All Accounts") {
                        withAnimation { selectedAccountId = nil }
                    }
                    Divider()
                    ForEach(store.accounts) { acc in
                        Button(acc.label) {
                            withAnimation { selectedAccountId = acc.id }
                        }
                    }
                } label: {
                    let isAccSelected = selectedAccountId != nil
                    HStack(spacing: 6) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 13, weight: .semibold))
                        Text(accountButtonLabel)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(isAccSelected ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background {
                        Capsule()
                            .fill(SpendyColors.cardBackground)
                            .overlay {
                                Capsule()
                                    .stroke(isAccSelected ? SpendyColors.textPrimary.opacity(0.85) : SpendyColors.separator, lineWidth: isAccSelected ? 1.4 : 0.8)
                            }
                    }
                }
                .buttonStyle(.plain)
                
                // [Type] Menu (Expenses, Income, Transfers)
                Menu {
                    Button("All Types") {
                        withAnimation { selectedTransactionType = nil }
                    }
                    Button("Expenses") {
                        withAnimation { selectedTransactionType = .expense }
                    }
                    Button("Income") {
                        withAnimation { selectedTransactionType = .income }
                    }
                    Button("Transfers") {
                        withAnimation { selectedTransactionType = .transfer }
                    }
                } label: {
                    let isTypeSelected = selectedTransactionType != nil
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                        Text(typeButtonLabel)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(isTypeSelected ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background {
                        Capsule()
                            .fill(SpendyColors.cardBackground)
                            .overlay {
                                Capsule()
                                    .stroke(isTypeSelected ? SpendyColors.textPrimary.opacity(0.85) : SpendyColors.separator, lineWidth: isTypeSelected ? 1.4 : 0.8)
                            }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 3. Individual Transaction Card
    private func transactionCard(_ tx: Transaction) -> some View {
        let cat = store.categories.first(where: { $0.id == tx.categoryId })
        let acc = store.accounts.first(where: { $0.id == tx.accountId })
        let subscription = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == tx.subscriptionId?.lowercased() })
        
        let iconSymbol = subscription?.sfSymbol ?? (cat?.sfSymbol ?? "cart.fill")
        let iconColor = subscription?.color ?? (cat?.color ?? Color(hex: "#FF5924"))
        let accountColor = acc?.color ?? Color(hex: "#007AFF")
        let accountLetter = String((acc?.label ?? "A").prefix(1)).uppercased()
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            inspectingTransaction = tx
        }) {
            HStack(spacing: 14) {
                // Large Circular Category Icon
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconSymbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                // Title and Mini Bank Square Badge below
                VStack(alignment: .leading, spacing: 4) {
                    Text(tx.title.isEmpty ? (cat?.label ?? "Expense") : tx.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        // Mini square bank avatar with letter
                        ZStack {
                            RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                                .fill(accountColor)
                                .frame(width: 16, height: 16)
                            
                            Text(accountLetter)
                                .font(.system(size: 9.5, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        
                        Text(acc?.label ?? "Main Account")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Right aligned amount
                Text(formattedRowAmountWithSign(tx))
                    .spendyNumberFont(size: 18, weight: .heavy)
                    .foregroundStyle(rowAmountColor(tx))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                HapticsManager.shared.trigger(.warning)
                withAnimation(AppMotion.snappySpring) {
                    store.deleteTransaction(id: tx.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
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
        }
    }
    
    private func rowAmountColor(_ tx: Transaction) -> Color {
        switch tx.type {
        case .expense: return SpendyColors.textPrimary
        case .income: return Color(hex: "#30D158")
        case .transfer: return SpendyColors.primaryBlue
        }
    }
    
    private func formattedRowAmountWithSign(_ tx: Transaction) -> String {
        let sym = store.currencySymbol
        let amtStr = tx.amount.formattedCurrency(symbol: sym, decimals: 0)
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
        HStack(spacing: 10) {
            // Liquid Glass Search Capsule
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary)
                
                TextField("Search transactions", text: $searchQuery)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .submitLabel(.search)
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        HapticsManager.shared.trigger(.tick)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .nativeLiquidGlassCapsule(isInteractive: true)
            
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
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 38))
                .foregroundStyle(SpendyColors.textTertiary)
            
            Text("No transactions found")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Text("Try searching for a different keyword or filter")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
