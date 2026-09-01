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
        ZStack {
            // Clean Background
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Horizontal Scrollable Liquid Glass Filter Capsules
                horizontalFilterBar
                    .padding(.vertical, 8)
                
                // Scrollable Content Layer
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Grouped Transactions List
                        if filteredTransactions.isEmpty {
                            emptyStateView
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
        .navigationTitle("All Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: $showAddTransaction) {
            AddTransactionView()
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
    }
    
    // MARK: - 2. Horizontal Scrollable Liquid Glass Filter Capsules (On Top Layer)
    private var horizontalFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 1. [Categories] Liquid Glass Menu
                Menu {
                    Button("All Categories") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedCategoryId = nil
                        }
                    }
                    Divider()
                    ForEach(store.categories) { cat in
                        Button(cat.label) {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selectedCategoryId = cat.id
                            }
                        }
                    }
                } label: {
                    let isCatSelected = selectedCategoryId != nil
                    HStack(spacing: 6) {
                        Image(systemName: isCatSelected ? (store.category(for: selectedCategoryId ?? "").sfSymbol) : "circle.grid.2x2")
                            .font(.system(size: 13, weight: .semibold))
                        Text(categoryButtonLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isCatSelected ? .white.opacity(0.8) : SpendyColors.textTertiary)
                    }
                    .foregroundStyle(isCatSelected ? .white : SpendyColors.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .nativeLiquidGlassCapsule(isInteractive: true, tint: isCatSelected ? SpendyColors.primaryBlue : nil)
                }
                .buttonStyle(.plain)
                
                // 2. [Accounts] Liquid Glass Menu
                Menu {
                    Button("All Accounts") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedAccountId = nil
                        }
                    }
                    Divider()
                    ForEach(store.accounts) { acc in
                        Button(acc.label) {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selectedAccountId = acc.id
                            }
                        }
                    }
                } label: {
                    let isAccSelected = selectedAccountId != nil
                    HStack(spacing: 6) {
                        Image(systemName: isAccSelected ? (store.account(for: selectedAccountId ?? "").sfSymbol.isEmpty ? "building.columns" : store.account(for: selectedAccountId ?? "").sfSymbol) : "building.columns")
                            .font(.system(size: 13, weight: .semibold))
                        Text(accountButtonLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isAccSelected ? .white.opacity(0.8) : SpendyColors.textTertiary)
                    }
                    .foregroundStyle(isAccSelected ? .white : SpendyColors.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .nativeLiquidGlassCapsule(isInteractive: true, tint: isAccSelected ? SpendyColors.primaryBlue : nil)
                }
                .buttonStyle(.plain)
                
                // 3. [Type] Liquid Glass Menu (Expenses, Income, Transfers)
                Menu {
                    Button("All Types") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTransactionType = nil
                        }
                    }
                    Button("Expenses") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTransactionType = .expense
                        }
                    }
                    Button("Income") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTransactionType = .income
                        }
                    }
                    Button("Transfers") {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTransactionType = .transfer
                        }
                    }
                } label: {
                    let isTypeSelected = selectedTransactionType != nil
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                        Text(typeButtonLabel)
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isTypeSelected ? .white.opacity(0.8) : SpendyColors.textTertiary)
                    }
                    .foregroundStyle(isTypeSelected ? .white : SpendyColors.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .nativeLiquidGlassCapsule(isInteractive: true, tint: isTypeSelected ? SpendyColors.primaryBlue : nil)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 3. Individual Transaction Card (Matching Category Card Design)
    private func transactionCard(_ tx: Transaction) -> some View {
        let cat = store.categories.first(where: { $0.id == tx.categoryId })
        let acc = store.accounts.first(where: { $0.id == tx.accountId })
        let subscription = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == tx.subscriptionId?.lowercased() })
        
        let iconSymbol = subscription?.sfSymbol ?? (cat?.sfSymbol ?? "cart.fill")
        let iconColor = subscription?.color ?? (cat?.color ?? Color(hex: "#FF5924"))
        
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
                    style: .circle
                )
                
                // Title and Account Pill Indicator
                VStack(alignment: .leading, spacing: 3) {
                    Text(tx.title.isEmpty ? (cat?.label ?? "Expense") : tx.title)
                        .font(AppTypography.rowTitle)
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
                    
                    if tx.type == .transfer, let toId = tx.toAccountId, let toAcc = store.accounts.first(where: { $0.id == toId }) {
                        Text("→ \(toAcc.label)")
                            .font(AppTypography.captionMedium)
                            .foregroundStyle(SpendyColors.primaryBlue)
                    } else {
                        Text(tx.date.formattedRelative)
                            .font(AppTypography.captionMedium)
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
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
            Spacer().frame(height: 40)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 38))
                .foregroundStyle(SpendyColors.textTertiary)
            
            Text("No transactions found")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Text("Try searching for a different keyword or filter")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            Spacer().frame(height: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    AllTransactionsView()
        .environment(ExpenseStore())
}
