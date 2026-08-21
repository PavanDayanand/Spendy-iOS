//
//  TransactionDetailSheet.swift
//  Spendy
//
//  Rich Transaction Detail Drawer with Monochrome Styling, Edit, Delete, and Thermal Receipt Preview
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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                // Subtle Monochrome Top Glow
                LinearGradient(
                    colors: [
                        SpendyColors.textPrimary.opacity(0.15),
                        SpendyColors.textPrimary.opacity(0.04),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Top Header Bar
                        HStack {
                            // Circular Close Button ✕
                            GlassCircleButton(
                                icon: "xmark",
                                size: 44,
                                iconSize: 14,
                                foregroundColor: SpendyColors.textPrimary,
                                haptic: .selection,
                                accessibilityLabel: "Close"
                            ) {
                                dismiss()
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                // Edit Button ✎
                                GlassCircleButton(
                                    icon: "pencil",
                                    size: 44,
                                    iconSize: 14,
                                    foregroundColor: SpendyColors.textPrimary,
                                    haptic: .light,
                                    accessibilityLabel: "Edit Transaction"
                                ) {
                                    dismiss()
                                    onEdit(transaction)
                                }
                                
                                // Delete Button 🗑
                                GlassCircleButton(
                                    icon: "trash.fill",
                                    size: 44,
                                    iconSize: 14,
                                    tintColor: SpendyColors.expenseRed,
                                    foregroundColor: SpendyColors.expenseRed,
                                    haptic: .warning,
                                    accessibilityLabel: "Delete Transaction"
                                ) {
                                    showDeleteConfirm = true
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                        // Hero Amount & Category Badge
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(category?.colorHex == "#18181B" ? Color.black : Color(uiColor: .dynamic(light: UIColor(white: 0.85, alpha: 1), dark: UIColor(white: 0.2, alpha: 1))))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: category?.sfSymbol ?? "tag.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(category?.colorHex == "#18181B" ? Color.white : SpendyColors.textPrimary)
                            }
                            
                            VStack(spacing: 4) {
                                Text(formattedAmountText)
                                    .font(.system(size: 38, weight: .heavy))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Text(transaction.title.isEmpty ? (category?.label ?? "Transaction") : transaction.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(SpendyColors.textSecondary)
                            }
                        }
                        
                        // Details Card
                        VStack(spacing: 14) {
                            detailRow(
                                icon: "tag.fill",
                                iconColor: SpendyColors.textPrimary,
                                label: "Category",
                                value: category?.label ?? "General"
                            )
                            
                            Divider().overlay(SpendyColors.separator)
                            
                            if transaction.type == .transfer {
                                detailRow(
                                    icon: "arrow.up.arrow.down",
                                    iconColor: SpendyColors.textPrimary,
                                    label: "Transfer Route",
                                    value: "\(account?.label ?? "Account") → \(toAccount?.label ?? "Account")"
                                )
                            } else {
                                detailRow(
                                    icon: "creditcard.fill",
                                    iconColor: SpendyColors.textPrimary,
                                    label: "Account",
                                    value: account?.label ?? "Cash"
                                )
                            }
                            
                            Divider().overlay(SpendyColors.separator)
                            
                            detailRow(
                                icon: "calendar",
                                iconColor: SpendyColors.textPrimary,
                                label: "Date & Time",
                                value: transaction.date.formatted(date: .abbreviated, time: .shortened)
                            )
                            
                            if let note = transaction.notes, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Divider().overlay(SpendyColors.separator)
                                
                                detailRow(
                                    icon: "text.alignleft",
                                    iconColor: SpendyColors.textPrimary,
                                    label: "Note",
                                    value: note
                                )
                            }
                        }
                        .padding(18)
                        .background {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(SpendyColors.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                                }
                        }
                        
                        // Receipt ID Footer
                        Text("TXID • \(transaction.id.uuidString.prefix(8).uppercased())")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .confirmationDialog(
                "Delete Transaction?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    store.deleteTransaction(id: transaction.id)
                    HapticsManager.shared.trigger(.warning)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this transaction? This cannot be undone.")
            }
        }
        .presentationDetents([.medium, .large])
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
    
    private func detailRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
        }
    }
}
