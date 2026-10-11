//
//  TransactionDetailSheet.swift
//  Spendy
//
//  View-transaction sheet, aligned with SubscriptionQuickActionSheet:
//  ambient header, close + edit, hero identity, one grouped details card.
//

import SwiftUI

struct TransactionDetailSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let initialTransaction: Transaction
    let onEdit: (Transaction) -> Void
    
    @State private var showDeleteConfirm: Bool = false
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    @State private var toastIcon: String = "checkmark.circle.fill"
    @State private var toastColor: Color = SpendyColors.incomeGreen
    @Namespace private var sheetNamespace
    
    init(transaction: Transaction, onEdit: @escaping (Transaction) -> Void) {
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
    
    private var typeBadgeTitle: String {
        if subscription != nil { return "Subscription" }
        switch transaction.type {
        case .expense: return "Expense"
        case .income: return "Income"
        case .transfer: return "Transfer"
        }
    }
    
    private var heroTitle: String {
        let title = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }
        if let sub = subscription { return sub.name }
        if let cat = category { return cat.label }
        return typeBadgeTitle
    }
    
    private var formattedAmountText: String {
        let formatted = transaction.amount.formattedCurrency(symbol: store.currencySymbol)
        switch transaction.type {
        case .income: return "+\(formatted)"
        case .expense, .transfer: return formatted
        }
    }
    
    private var accountSymbol: String {
        if let sym = account?.sfSymbol, !sym.isEmpty { return sym }
        return account?.type.defaultSymbol ?? "building.columns.fill"
    }
    
    private var toAccountSymbol: String {
        if let sym = toAccount?.sfSymbol, !sym.isEmpty { return sym }
        return toAccount?.type.defaultSymbol ?? "building.columns.fill"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            SpendyAmbientHeaderBackground(color: themeColor, height: 320, opacity: 0.30)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Spacer().frame(height: 56)
                    
                    heroSection
                        .padding(.top, 4)
                        .padding(.bottom, 6)
                    
                    detailsCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            
            topActionBar
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .spendyBarBackground()
            
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
        .presentationDetents([.height(500), .large])
        .presentationDragIndicator(.hidden)
        .onChange(of: store.transactions) { _, newTransactions in
            if !newTransactions.contains(where: { $0.id == initialTransaction.id }) {
                dismiss()
            }
        }
    }
    
    private var topActionBar: some View {
        HStack {
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
                
                GlassCircleButton(
                    icon: SFIcons.trash,
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
    
    private var heroSection: some View {
        VStack(spacing: 14) {
            if let sub = subscription {
                SubscriptionProgressRingBadge(subscription: sub, size: .large)
            } else {
                SpendyIconBadge(
                    sfSymbol: category?.sfSymbol ?? (transaction.type == .income ? "arrow.down.left" : "tag.fill"),
                    color: category.map { Color(hex: $0.colorHex) } ?? themeColor,
                    size: .large,
                    style: .circle,
                    monogramName: category?.label ?? heroTitle
                )
            }
            
            Text(formattedAmountText)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(SpendyColors.textPrimary)
                .contentTransition(.numericText())
        }
    }
    
    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(label: "Date") {
                Text(transaction.date.formatted(date: .long, time: .omitted))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .multilineTextAlignment(.trailing)
            }
            
            if transaction.type != .transfer {
                cardDivider
                detailRow(label: "Category") {
                    entityValue(
                        symbol: category?.sfSymbol ?? "tag.fill",
                        color: category.map { Color(hex: $0.colorHex) } ?? SpendyColors.primaryBlue,
                        name: category?.label ?? "General",
                        isCircle: true
                    )
                }
            }
            
            cardDivider
            
            if transaction.type == .transfer {
                detailRow(label: "From") {
                    entityValue(
                        symbol: accountSymbol,
                        color: account.map { Color(hex: $0.colorHex) } ?? SpendyColors.incomeGreen,
                        name: account?.label ?? "Cash"
                    )
                }
                if let to = toAccount {
                    cardDivider
                    detailRow(label: "To") {
                        entityValue(
                            symbol: toAccountSymbol,
                            color: Color(hex: to.colorHex),
                            name: to.label
                        )
                    }
                }
            } else {
                detailRow(label: "Account") {
                    entityValue(
                        symbol: accountSymbol,
                        color: account.map { Color(hex: $0.colorHex) } ?? SpendyColors.incomeGreen,
                        name: account?.label ?? "Cash"
                    )
                }
            }
            
            if let sub = subscription {
                cardDivider
                detailRow(label: "Subscription") {
                    entityValue(
                        symbol: sub.sfSymbol,
                        color: Color(hex: sub.colorHex),
                        name: sub.name,
                        isCircle: true
                    )
                }
            }
            
            if let note = transaction.notes, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cardDivider
                detailRow(label: "Note") {
                    Text(note)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(4)
                }
            }
        }
        .padding(.horizontal, 18)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    private var cardDivider: some View {
        Divider().background(SpendyColors.separator)
    }
    
    private func detailRow<Value: View>(label: String, @ViewBuilder value: () -> Value) -> some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Spacer(minLength: 12)
            
            value()
        }
        .padding(.vertical, 14)
    }
    
    private func entityValue(symbol: String, color: Color, name: String, isCircle: Bool = false) -> some View {
        HStack(spacing: 8) {
            SpendyIconBadge(
                sfSymbol: symbol,
                color: color,
                size: .small,
                style: isCircle ? .circle : .rounded(),
                monogramName: name
            )
            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
        }
    }
    
    private func handleEdit() {
        HapticsManager.shared.trigger(.selection)
        onEdit(transaction)
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
