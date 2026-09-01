//
//  TransactionDetailSheet.swift
//  Spendy
//
//  Native Apple Floating Glass Sheet Card with Category/Subscription Ambient Header Gradient,
//  Refined Hero Display, Structured Details Container Card, & Perfectly Aligned Top Action Buttons (✕, ✎, 🗑)
//

import SwiftUI

struct TransactionDetailSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let initialTransaction: Transaction
    var onEdit: ((Transaction) -> Void)?
    
    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @Namespace private var sheetNamespace
    
    init(transaction: Transaction, onEdit: ((Transaction) -> Void)? = nil) {
        self.initialTransaction = transaction
        self.onEdit = onEdit
    }
    
    private var transaction: Transaction {
        store.transactions.first(where: { $0.id == initialTransaction.id }) ?? initialTransaction
    }
    
    private var category: Category? {
        store.categories.first(where: { $0.id == transaction.categoryId })
    }
    
    private var account: Account? {
        store.accounts.first(where: { $0.id == transaction.accountId })
    }
    
    private var toAccount: Account? {
        guard let toId = transaction.toAccountId else { return nil }
        return store.accounts.first(where: { $0.id == toId })
    }
    
    private var subscription: Subscription? {
        store.subscriptions.first(where: { $0.id.uuidString.lowercased() == transaction.subscriptionId?.lowercased() })
    }
    
    private var themeColor: Color {
        if let sub = subscription { return Color(hex: sub.colorHex) }
        if let cat = category { return Color(hex: cat.colorHex) }
        if transaction.type == .income { return SpendyColors.incomeGreen }
        return SpendyColors.primaryBlue
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .expense:  return SpendyColors.textPrimary
        case .income:   return SpendyColors.incomeGreen
        case .transfer: return SpendyColors.textPrimary
        }
    }
    
    private var typeBadgeTitle: String {
        if subscription != nil { return "Subscription" }
        switch transaction.type {
        case .expense:  return "Expense"
        case .income:   return "Income"
        case .transfer: return "Transfer"
        }
    }
    
    private var typeBadgeIcon: String {
        if subscription != nil { return "repeat" }
        switch transaction.type {
        case .expense:  return "arrow.down.right"
        case .income:   return "arrow.up.left"
        case .transfer: return "arrow.left.arrow.right"
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // MARK: - Ambient Theme Gradient Glow (At top of sheet, fades smoothly to base)
            SpendyAmbientHeaderBackground(color: themeColor, height: 320, opacity: 0.30)
            
            // MARK: - Scrollable Content (offset below the floating top bar)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Spacer to clear the floating topActionBar (44pt button + 20pt top inset + 8pt gap)
                    Spacer().frame(height: 64)
                    
                    // MARK: - 1. Hero Section
                    heroSection
                    
                    // MARK: - 2. Structured Details Card
                    detailsCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            
            // MARK: - Pinned Floating Top Bar (✕, ✎, 🗑)
            topActionBar
                .padding(.horizontal, 20)
                .padding(.top, 20)
        }
        .background(Color.clear)
        .alert("Delete Transaction?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                HapticsManager.shared.trigger(.warning)
                store.deleteTransaction(id: transaction.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this transaction? This cannot be undone.")
        }
        .presentationDetents([.height(500), .medium, .large])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showEditSheet) {
            AddTransactionView(transactionToEdit: transaction)
        }
        .onChange(of: store.transactions) { _, newTransactions in
            if !newTransactions.contains(where: { $0.id == initialTransaction.id }) {
                dismiss()
            }
        }
    }

    
    // MARK: - Top Action Bar
    @ViewBuilder
    private var topActionBar: some View {
        HStack {
            // Close Button ✕ (Left)
            GlassCircleButton(
                icon: SFIcons.close,
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close",
                morphID: "closeButton",
                namespace: sheetNamespace
            ) {
                dismiss()
            }
            
            Spacer()
            
            // More Options Menu ••• (Right)
            Menu {
                Button {
                    HapticsManager.shared.trigger(.selection)
                    if let onEdit = onEdit {
                        onEdit(transaction)
                    } else {
                        showEditSheet = true
                    }
                } label: {
                    Label("Edit Transaction", systemImage: "pencil")
                }
                
                Button {
                    HapticsManager.shared.trigger(.light)
                    let copy = Transaction(
                        id: UUID(),
                        title: transaction.title,
                        amount: transaction.amount,
                        type: transaction.type,
                        categoryId: transaction.categoryId,
                        accountId: transaction.accountId,
                        toAccountId: transaction.toAccountId,
                        date: Date(),
                        notes: transaction.notes,
                        subscriptionId: transaction.subscriptionId
                    )
                    store.addTransaction(copy)
                    dismiss()
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                Button {
                    HapticsManager.shared.trigger(.light)
                    UIPasteboard.general.string = "\(transaction.amount)"
                } label: {
                    Label("Copy Amount", systemImage: "doc.on.clipboard")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    HapticsManager.shared.trigger(.warning)
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Transaction", systemImage: "trash")
                }
            } label: {
                GlassCircleButton(
                    icon: "ellipsis",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .light,
                    accessibilityLabel: "Transaction Options",
                    morphID: "moreButton",
                    namespace: sheetNamespace
                ) { }
            }
        }
    }

    // MARK: - Hero Section
    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 10) {
            // Main Avatar Badge with soft ambient shadow
            if let sub = subscription {
                SpendyIconBadge(
                    sfSymbol: sub.sfSymbol,
                    color: Color(hex: sub.colorHex),
                    size: .large,
                    style: .circle
                )
                .shadow(color: Color(hex: sub.colorHex).opacity(0.35), radius: 12, y: 4)
            } else {
                SpendyIconBadge(
                    sfSymbol: category?.sfSymbol ?? (transaction.type == .income ? "arrow.down.left" : "tag.fill"),
                    color: category != nil ? Color(hex: category!.colorHex) : themeColor,
                    size: .large,
                    style: .circle
                )
                .shadow(color: (category != nil ? Color(hex: category!.colorHex) : themeColor).opacity(0.35), radius: 12, y: 4)
            }
            
            // Title
            Text(transaction.title.isEmpty ? (category?.label ?? typeBadgeTitle) : transaction.title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
            
            // Hero Formatted Amount & Type Pill
            VStack(spacing: 6) {
                Text(formattedAmountText)
                    .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                    .foregroundStyle(amountColor)
                    .contentTransition(.numericText())
                
                HStack(spacing: 5) {
                    Image(systemName: typeBadgeIcon)
                        .font(.system(size: 10, weight: .bold))
                    Text(subscription != nil ? "Subscription • \(subscription!.cycle.rawValue.capitalized)" : typeBadgeTitle)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(themeColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4.5)
                .background(themeColor.opacity(0.14), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(themeColor.opacity(0.24), lineWidth: 0.8)
                )
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Structured Details Card Container
    @ViewBuilder
    private var detailsCard: some View {
        VStack(spacing: 0) {
            // Row 1: Category Row
            cardRow(icon: "tag.fill", label: "Category") {
                HStack(spacing: 8) {
                    SpendyIconBadge(
                        sfSymbol: category?.sfSymbol ?? "tag.fill",
                        color: category != nil ? Color(hex: category!.colorHex) : SpendyColors.primaryBlue,
                        size: .small,
                        style: .circle
                    )
                    Text(category?.label ?? "General")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            
            rowDivider
            
            // Row 2: Account / Route Row
            if transaction.type == .transfer {
                cardRow(icon: "arrow.up.arrow.down", label: "Route") {
                    HStack(spacing: 6) {
                        Text(account?.label ?? "Account")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Text(toAccount?.label ?? "Account")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                }
            } else {
                cardRow(icon: "creditcard.fill", label: "Account") {
                    HStack(spacing: 8) {
                        SpendyIconBadge(
                            sfSymbol: account?.sfSymbol.isEmpty == false ? account!.sfSymbol : (account?.type.defaultSymbol ?? "building.columns.fill"),
                            color: account != nil ? Color(hex: account!.colorHex) : SpendyColors.incomeGreen,
                            size: .small,
                            style: .circle
                        )
                        Text(account?.label ?? "Cash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                }
            }
            
            rowDivider
            
            // Row 3: Date & Time Row
            cardRow(icon: "calendar", label: "Date & Time") {
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            
            // Row 4: Note Row (if present)
            if let note = transaction.notes, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                rowDivider
                
                cardRow(icon: "text.alignleft", label: "Note") {
                    Text(note)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(3)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    private var rowDivider: some View {
        Divider()
            .overlay(SpendyColors.separator.opacity(0.6))
            .padding(.leading, 48)
    }
    
    private var formattedAmountText: String {
        let sym = store.currencySymbol
        switch transaction.type {
        case .expense:
            return "-\(transaction.amount.formattedCurrency(symbol: sym))"
        case .income:
            return "+\(transaction.amount.formattedCurrency(symbol: sym))"
        case .transfer:
            return "\(transaction.amount.formattedCurrency(symbol: sym))"
        }
    }
    
    @ViewBuilder
    private func cardRow<V: View>(icon: String, label: String, @ViewBuilder valueView: () -> V) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SpendyColors.chipBackground)
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Spacer()
            
            valueView()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
