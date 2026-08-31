//
//  AllTransactionsSheet.swift
//  Spendy
//
//  Clean All Transactions Sheet with Live Search, Filter Chips,
//  Date Grouping, and Full Transaction History.
//

import SwiftUI

struct AllTransactionsSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    // State
    @State private var searchQuery: String = ""
    @State private var selectedType: TransactionTypeFilter = .all
    @State private var selectedCategoryId: String? = nil
    @State private var selectedAccountId: String? = nil
    @State private var inspectingTransaction: Transaction? = nil
    @State private var editingTransaction: Transaction? = nil
    
    enum TransactionTypeFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case expense = "Expenses"
        case income = "Income"
        case transfer = "Transfers"
        
        var id: String { rawValue }
    }
    
    private var filteredTransactions: [Transaction] {
        var txs = store.transactions
        
        // Filter by Type
        switch selectedType {
        case .all:
            break
        case .expense:
            txs = txs.filter { $0.type == .expense }
        case .income:
            txs = txs.filter { $0.type == .income }
        case .transfer:
            txs = txs.filter { $0.type == .transfer }
        }
        
        // Filter by Category
        if let catId = selectedCategoryId {
            txs = txs.filter { $0.categoryId == catId }
        }
        
        // Filter by Account
        if let accId = selectedAccountId {
            txs = txs.filter { $0.accountId == accId || $0.toAccountId == accId }
        }
        
        // Search query
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Search Bar
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    // Filter Chips Row
                    filterChipsRow
                        .padding(.horizontal, 16)
                    
                    // Transactions List
                    if filteredTransactions.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredTransactions) { tx in
                                    transactionRowCard(tx)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("All Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            .sheet(item: $inspectingTransaction) { tx in
                TransactionDetailSheet(transaction: tx) { txToEdit in
                    editingTransaction = txToEdit
                    inspectingTransaction = nil
                }
            }
            .sheet(item: $editingTransaction) { tx in
                AddTransactionView(transactionToEdit: tx)
                    .presentationBackground(SpendyColors.appBackground)
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
            
            TextField("Search notes, merchant, category, account...", text: $searchQuery)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .submitLabel(.search)
            
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    HapticsManager.shared.trigger(.tick)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SpendyColors.cardBackgroundSecondary)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Filter Chips Row
    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Type Filter Chips
                ForEach(TransactionTypeFilter.allCases) { type in
                    let isSelected = selectedType == type
                    Button {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(AppMotion.snappySpring) {
                            selectedType = type
                        }
                    } label: {
                        Text(type.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? SpendyColors.inverseText : SpendyColors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(isSelected ? SpendyColors.textPrimary : SpendyColors.cardBackground)
                                    .overlay {
                                        if !isSelected {
                                            Capsule().stroke(SpendyColors.separator, lineWidth: 0.8)
                                        }
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                }
                
                // Category Filter Dropdown
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
                    HStack(spacing: 4) {
                        Text(selectedCategoryLabel)
                            .font(.system(size: 13, weight: selectedCategoryId != nil ? .bold : .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(selectedCategoryId != nil ? SpendyColors.primaryBlue : SpendyColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(SpendyColors.cardBackground)
                            .overlay {
                                Capsule().stroke(selectedCategoryId != nil ? SpendyColors.primaryBlue : SpendyColors.separator, lineWidth: 0.8)
                            }
                    }
                }
                
                // Account Filter Dropdown
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
                    HStack(spacing: 4) {
                        Text(selectedAccountFilterLabel)
                            .font(.system(size: 13, weight: selectedAccountId != nil ? .bold : .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(selectedAccountId != nil ? SpendyColors.primaryBlue : SpendyColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(SpendyColors.cardBackground)
                            .overlay {
                                Capsule().stroke(selectedAccountId != nil ? SpendyColors.primaryBlue : SpendyColors.separator, lineWidth: 0.8)
                            }
                    }
                }
            }
        }
    }
    
    private var selectedCategoryLabel: String {
        if let catId = selectedCategoryId, let cat = store.categories.first(where: { $0.id == catId }) {
            return cat.label
        }
        return "Category"
    }
    
    private var selectedAccountFilterLabel: String {
        if let accId = selectedAccountId, let acc = store.accounts.first(where: { $0.id == accId }) {
            return acc.label
        }
        return "Account"
    }
    
    // MARK: - Transaction Row Card
    private func transactionRowCard(_ tx: Transaction) -> some View {
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
                // Circle Icon Badge
                SpendyIconBadge(
                    sfSymbol: iconSymbol,
                    color: iconColor,
                    size: .medium,
                    style: .circle
                )
                
                // Title & Account Pill
                VStack(alignment: .leading, spacing: 3) {
                    Text(tx.title.isEmpty ? (cat?.label ?? "Expense") : tx.title)
                        .font(.system(size: 15, weight: .bold))
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
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                // Amount & Date
                VStack(alignment: .trailing, spacing: 3) {
                    Text(formattedRowAmount(tx))
                        .spendyNumberFont(size: 16, weight: .bold)
                        .foregroundStyle(rowAmountColor(tx))
                    
                    Text(tx.date.formattedRelative)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
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
        case .income: return SpendyColors.incomeGreen
        case .transfer: return SpendyColors.primaryBlue
        }
    }
    
    private func formattedRowAmount(_ tx: Transaction) -> String {
        let sym = store.currencySymbol
        return tx.amount.formattedCurrency(symbol: sym)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(SpendyColors.textTertiary)
            
            Text("No transactions found")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Text("Try clearing your filters or search query")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
