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
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    @State private var toastIcon: String = "checkmark.circle.fill"
    @State private var toastColor: Color = SpendyColors.incomeGreen
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
    
    private var formattedAmountText: String {
        let sym = store.currencySymbol
        switch transaction.type {
        case .expense:
            return transaction.amount.formattedCurrency(symbol: sym)
        case .income:
            return "+\(transaction.amount.formattedCurrency(symbol: sym))"
        case .transfer:
            return transaction.amount.formattedCurrency(symbol: sym)
        }
    }
    
    private var accountSymbol: String {
        if let sym = account?.sfSymbol, !sym.isEmpty {
            return sym
        }
        return account?.type.defaultSymbol ?? "building.columns.fill"
    }
    
    private var toAccountSymbol: String {
        if let sym = toAccount?.sfSymbol, !sym.isEmpty {
            return sym
        }
        return toAccount?.type.defaultSymbol ?? "building.columns.fill"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // MARK: - Scrollable Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Spacer to clear pinned top bar
                    Spacer().frame(height: 56)
                    
                    // MARK: - 1. Hero Section (Icon + Large Amount)
                    heroSection
                        .padding(.top, 4)
                        .padding(.bottom, 2)
                    
                    // MARK: - 2. Standalone Category Card
                    categoryCard
                    
                    // MARK: - 3. Structured Details Card (Date, Type, Account, Note)
                    detailsCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            
            // MARK: - Pinned Top Action Bar (✕ on Left, ✎ and 🗑 on Right)
            topActionBar
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            // MARK: - Floating Toast Feedback
            if showToast, let toast = toastMessage {
                feedbackToastView(message: toast, icon: toastIcon, color: toastColor)
                    .padding(.top, 64)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(200)
            }
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
        .presentationDetents([.height(540), .large])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $showEditSheet) {
            AddTransactionView(transactionToEdit: transaction)
        }
        .onChange(of: store.transactions) { _, newTransactions in
            if !newTransactions.contains(where: { $0.id == initialTransaction.id }) {
                dismiss()
            }
        }
    }
    
    // MARK: - Top Action Bar (✕ on Left, ✎ and 🗑 on Right)
    private var topActionBar: some View {
        HStack {
            // Close Button ✕ (Left, 44pt GlassCircleButton)
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
            
            HStack(spacing: 10) {
                // Edit Circle Button with Pen Icon (Right, 44pt GlassCircleButton)
                GlassCircleButton(
                    icon: SFIcons.edit,
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .selection,
                    accessibilityLabel: "Edit Transaction",
                    morphID: "editButton",
                    namespace: sheetNamespace
                ) {
                    handleEdit()
                }
                
                // Delete Circle Button with Trash Icon (Right, 44pt GlassCircleButton)
                GlassCircleButton(
                    icon: "trash",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .semibold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .warning,
                    accessibilityLabel: "Delete Transaction",
                    morphID: "deleteButton",
                    namespace: sheetNamespace
                ) {
                    showDeleteConfirm = true
                }
            }
        }
    }
    
    // MARK: - Hero Section (Circular Badge with Ambient Glow + Large Bold Amount)
    private var heroSection: some View {
        VStack(spacing: 14) {
            // Circular Avatar Badge with soft ambient glow
            ZStack {
                // Soft ambient diffused halo
                Circle()
                    .fill(themeColor.opacity(0.30))
                    .frame(width: 82, height: 82)
                    .blur(radius: 12)
                
                // Concentrated rim glow right outside the badge edge
                Circle()
                    .stroke(themeColor.opacity(0.40), lineWidth: 3.5)
                    .frame(width: 70, height: 70)
                    .blur(radius: 4.5)
                
                if let sub = subscription {
                    SubscriptionProgressRingBadge(
                        subscription: sub,
                        size: .large
                    )
                } else {
                    let catColor = category.map { Color(hex: $0.colorHex) } ?? themeColor
                    SpendyIconBadge(
                        sfSymbol: category?.sfSymbol ?? (transaction.type == .income ? "arrow.down.left" : "tag.fill"),
                        color: catColor,
                        size: .large,
                        style: .circle
                    )
                }
            }
            
            // Large Bold Amount
            Text(formattedAmountText)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(amountColor)
                .contentTransition(.numericText())
        }
    }
    
    // MARK: - Standalone Category Card
    @ViewBuilder
    private var categoryCard: some View {
        if transaction.type != .transfer {
            HStack {
                Text("Category")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    SpendyIconBadge(
                        sfSymbol: category?.sfSymbol ?? "tag.fill",
                        color: category.map { Color(hex: $0.colorHex) } ?? SpendyColors.primaryBlue,
                        size: .small,
                        style: .circle
                    )
                    
                    Text(category?.label ?? "General")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            .padding(.horizontal, 18)
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
    }
    
    // MARK: - Grouped Details Card (Date, Type, Account, Note, Subscription)
    private var detailsCard: some View {
        VStack(spacing: 0) {
            // Row 1: Date
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .frame(width: 22, alignment: .leading)
                    
                    Text("Date")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Spacer()
                
                Text(transaction.date.formatted(date: .long, time: .omitted))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.vertical, 14)
            
            Divider().background(SpendyColors.separator)
            
            // Row 2: Type
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .frame(width: 22, alignment: .leading)
                    
                    Text("Type")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Spacer()
                
                Text(typeBadgeTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.vertical, 14)
            
            Divider().background(SpendyColors.separator)
            
            // Row 3: Account (or Route for Transfer)
            if transaction.type == .transfer {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(width: 22, alignment: .leading)
                        
                        Text("From Account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        SpendyIconBadge(
                            sfSymbol: accountSymbol,
                            color: account.map { Color(hex: $0.colorHex) } ?? SpendyColors.incomeGreen,
                            size: .small,
                            style: .circle
                        )
                        
                        Text(account?.label ?? "Cash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                }
                .padding(.vertical, 12)
                
                if let to = toAccount {
                    Divider().background(SpendyColors.separator)
                    
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                                .frame(width: 22, alignment: .leading)
                            
                            Text("To Account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            SpendyIconBadge(
                                sfSymbol: toAccountSymbol,
                                color: Color(hex: to.colorHex),
                                size: .small,
                                style: .circle
                            )
                            
                            Text(to.label)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(SpendyColors.textPrimary)
                        }
                    }
                    .padding(.vertical, 12)
                }
            } else {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(width: 22, alignment: .leading)
                        
                        Text("Account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        SpendyIconBadge(
                            sfSymbol: accountSymbol,
                            color: account.map { Color(hex: $0.colorHex) } ?? SpendyColors.incomeGreen,
                            size: .small,
                            style: .circle
                        )
                        
                        Text(account?.label ?? "Cash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                }
                .padding(.vertical, 12)
            }
            
            // Row 4: Subscription (if linked)
            if let sub = subscription {
                Divider().background(SpendyColors.separator)
                
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "repeat")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(width: 22, alignment: .leading)
                        
                        Text("Subscription")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        SpendyIconBadge(
                            sfSymbol: sub.sfSymbol,
                            color: Color(hex: sub.colorHex),
                            size: .small,
                            style: .circle
                        )
                        
                        Text(sub.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                }
                .padding(.vertical, 12)
            }
            
            // Row 5: Custom Title (if different from Category)
            if !transaction.title.isEmpty && transaction.title.lowercased() != (category?.label ?? "").lowercased() {
                Divider().background(SpendyColors.separator)
                
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil.line")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(width: 22, alignment: .leading)
                        
                        Text("Title")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(transaction.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                .padding(.vertical, 14)
            }
            
            // Row 6: Note (if present)
            if let note = transaction.notes, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Divider().background(SpendyColors.separator)
                
                HStack(alignment: .top) {
                    HStack(spacing: 12) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(width: 22, alignment: .leading)
                        
                        Text("Note")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(note)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(4)
                }
                .padding(.vertical, 14)
            }
        }
        .padding(.horizontal, 18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Actions & Feedback
    private func handleEdit() {
        HapticsManager.shared.trigger(.selection)
        if let onEdit = onEdit {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onEdit(transaction)
            }
        } else {
            showEditSheet = true
        }
    }
    
    private func handleDuplicate() {
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
        showFeedback(message: "Transaction Duplicated", icon: "doc.on.doc.fill", color: SpendyColors.incomeGreen)
    }
    
    private func handleCopyAmount() {
        HapticsManager.shared.trigger(.light)
        UIPasteboard.general.string = "\(transaction.amount)"
        showFeedback(message: "Amount Copied", icon: "doc.on.clipboard.fill", color: SpendyColors.primaryBlue)
    }
    
    private func showFeedback(message: String, icon: String, color: Color) {
        toastMessage = message
        toastIcon = icon
        toastColor = color
        withAnimation(.easeInOut(duration: 0.25)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showToast = false
            }
        }
    }
    
    // MARK: - Toast Banner View
    private func feedbackToastView(message: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            
            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
        .overlay(
            Capsule()
                .stroke(SpendyColors.separator, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12, y: 6)
    }
}
