//
//  TransactionDetailSheet.swift
//  Spendy
//
//  Rich Transaction Detail Drawer with Category Glow, Edit, Delete, and Thermal Receipt Preview
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
    
    private var categoryColor: Color {
        category?.color ?? SpendyColors.primaryBlue
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                // Vibrant Top Category Glow
                LinearGradient(
                    colors: [
                        categoryColor.opacity(0.35),
                        categoryColor.opacity(0.12),
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
                            Button(action: {
                                HapticsManager.shared.trigger(.selection)
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .nativeLiquidGlassCircle(isInteractive: true)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                // Edit Button ✎
                                Button(action: {
                                    HapticsManager.shared.trigger(.light)
                                    dismiss()
                                    onEdit(transaction)
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 44, height: 44)
                                        .nativeLiquidGlassCircle(isInteractive: true)
                                }
                                .buttonStyle(.plain)
                                
                                // Delete Button 🗑
                                Button(action: {
                                    HapticsManager.shared.trigger(.warning)
                                    showDeleteConfirm = true
                                }) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(SpendyColors.expenseRed)
                                        .frame(width: 44, height: 44)
                                        .nativeLiquidGlassCircle(isInteractive: true, tint: SpendyColors.expenseRed)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 10)
                        
                        // Hero Amount & Category Badge
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(categoryColor)
                                    .frame(width: 64, height: 64)
                                    .shadow(color: categoryColor.opacity(0.45), radius: 14, y: 4)
                                
                                Image(systemName: category?.sfSymbol ?? "tag.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(spacing: 4) {
                                Text(formattedAmountText)
                                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text(transaction.title.isEmpty ? (category?.label ?? "Transaction") : transaction.title)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.70))
                            }
                        }
                        
                        // Details Card
                        VStack(spacing: 14) {
                            detailRow(
                                icon: "tag.fill",
                                iconColor: categoryColor,
                                label: "Category",
                                value: category?.label ?? "General"
                            )
                            
                            Divider().overlay(Color.white.opacity(0.06))
                            
                            if transaction.type == .transfer {
                                detailRow(
                                    icon: "arrow.up.arrow.down",
                                    iconColor: SpendyColors.transferBlue,
                                    label: "Transfer Route",
                                    value: "\(account?.label ?? "Account") → \(toAccount?.label ?? "Account")"
                                )
                            } else {
                                detailRow(
                                    icon: "creditcard.fill",
                                    iconColor: SpendyColors.primaryBlue,
                                    label: "Account",
                                    value: account?.label ?? "Cash"
                                )
                            }
                            
                            Divider().overlay(Color.white.opacity(0.06))
                            
                            detailRow(
                                icon: "calendar",
                                iconColor: SpendyColors.warningOrange,
                                label: "Date & Time",
                                value: transaction.date.formatted(date: .abbreviated, time: .shortened)
                            )
                            
                            if let note = transaction.notes, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Divider().overlay(Color.white.opacity(0.06))
                                
                                detailRow(
                                    icon: "text.alignleft",
                                    iconColor: Color(hex: "#AF52DE"),
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
                                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                }
                        }
                        
                        // Receipt ID Footer
                        Text("TXID • \(transaction.id.uuidString.prefix(8).uppercased())")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.30))
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
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
