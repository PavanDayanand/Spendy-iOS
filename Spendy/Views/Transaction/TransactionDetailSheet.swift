//
//  TransactionDetailSheet.swift
//  Spendy
//
//  Native Apple Floating Glass Sheet Card with Perfectly Aligned Top Corner Action Buttons (✕, ✎, 🗑)
//

import SwiftUI

struct TransactionDetailSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let transaction: Transaction
    var onEdit: (Transaction) -> Void
    
    @State private var showDeleteConfirm: Bool = false
    
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
        return SpendyColors.primaryBlue
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .expense:  return SpendyColors.textPrimary
        case .income:   return SpendyColors.incomeGreen
        case .transfer: return SpendyColors.textPrimary
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MARK: - Scrollable Content (offset below the floating top bar)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Spacer to clear the floating topActionBar (44pt button + 20pt top inset + 12pt gap)
                        Spacer().frame(height: 76)
                        
                        // MARK: - 2. Hero Section
                        heroSection
                        
                        Divider().overlay(SpendyColors.separator)
                        
                        // MARK: - 3. Details Rows
                        detailsList
                        
                        Divider().overlay(SpendyColors.separator)
                        
                        // MARK: - 4. Monospaced TXID Footer
                        Text("TXID • \(transaction.id.uuidString.prefix(8).uppercased())")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
                }
                
                // MARK: - 1. Floating Top Bar (pinned above content, below drag indicator)
                topActionBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
            .background(Color.clear)
            .navigationBarHidden(true)
            .confirmationDialog(
                "Delete Transaction?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    HapticsManager.shared.trigger(.warning)
                    store.deleteTransaction(id: transaction.id)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this transaction? This cannot be undone.")
            }
        }
        .presentationDetents([.height(525), .medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground {
            ZStack {
                SpendyColors.cardBackground
                SpendyAmbientHeaderBackground(color: themeColor, height: 260, opacity: 0.20)
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var topActionBar: some View {
        HStack {
            // Close Button ✕ — matches home page size: 44
            SpendyGlassEffectContainer(spacing: 0) {
                GlassCircleButton(
                    icon: "xmark",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .selection,
                    accessibilityLabel: "Close"
                ) {
                    dismiss()
                }
            }
            
            Spacer()
            
            // Edit ✎ + Delete 🗑 — matches home page size: 44
            SpendyGlassEffectContainer(spacing: 10) {
                GlassCircleButton(
                    icon: "pencil",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .light,
                    accessibilityLabel: "Edit Transaction"
                ) {
                    onEdit(transaction)
                }
                
                GlassCircleButton(
                    icon: "trash.fill",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    tintColor: SpendyColors.expenseRed.opacity(0.18),
                    foregroundColor: SpendyColors.expenseRed,
                    haptic: .warning,
                    accessibilityLabel: "Delete Transaction"
                ) {
                    showDeleteConfirm = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 10) {
            // Main Category / Subscription Icon Avatar (Centered Body)
            if let sub = subscription {
                SpendyIconBadge(
                    sfSymbol: sub.sfSymbol,
                    color: Color(hex: sub.colorHex),
                    size: .large,
                    style: .circle
                )
            } else {
                SpendyIconBadge(
                    sfSymbol: category?.sfSymbol ?? "tag.fill",
                    color: category != nil ? Color(hex: category!.colorHex) : SpendyColors.primaryBlue,
                    size: .large,
                    style: .circle
                )
            }
            
            // Title — date & category are in the detail rows below (no duplication)
            Text(transaction.title.isEmpty ? (category?.label ?? "Transaction") : transaction.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
            
            // Hero Amount — subscription badge only (category pill removed, shown in details)
            VStack(spacing: 4) {
                Text(formattedAmountText)
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(amountColor)
                
                if let sub = subscription {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 11, weight: .bold))
                        Text("Subscription • \(sub.cycle.rawValue.capitalized)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(themeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(themeColor.opacity(0.14), in: Capsule())
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private var detailsList: some View {
        VStack(spacing: 12) {
            // Category Row — SpendyIconBadge
            detailRow(icon: "tag.fill", label: "Category") {
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
            
            // Account Row — SpendyIconBadge
            if transaction.type == .transfer {
                detailRow(icon: "arrow.up.arrow.down", label: "Route") {
                    Text("\(account?.label ?? "Account") → \(toAccount?.label ?? "Account")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            } else {
                detailRow(icon: "creditcard.fill", label: "Account") {
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
            
            // Date & Time Row
            detailRow(icon: "calendar", label: "Date & Time") {
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            
            // Note Row (if present)
            if let note = transaction.notes, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                detailRow(icon: "text.alignleft", label: "Note") {
                    Text(note)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
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
    private func detailRow<V: View>(icon: String, label: String, @ViewBuilder valueView: () -> V) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
                .frame(width: 24, height: 24)
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Spacer()
            
            valueView()
        }
    }
}
