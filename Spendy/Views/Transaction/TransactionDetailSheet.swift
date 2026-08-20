//
//  TransactionDetailSheet.swift
//  Spendy
//
//  Native iOS Transaction Details Modal Sheet
//

import SwiftUI

struct TransactionDetailSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var transaction: Transaction
    @State private var showDeleteConfirm: Bool = false
    
    var body: some View {
        let category = store.category(for: transaction.categoryId)
        let account = store.account(for: transaction.accountId)
        
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero Amount & Icon
                        VStack(spacing: 12) {
                            CategoryIconBadge(
                                sfSymbol: category.sfSymbol,
                                tintColor: category.color,
                                size: .large
                            )
                            
                            Text(transaction.title)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text(amountFormatted)
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .foregroundStyle(amountColor)
                            
                            Text(transaction.type.title.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(transaction.type.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background {
                                    Capsule().fill(transaction.type.color.opacity(0.15))
                                }
                        }
                        .padding(.vertical, 16)
                        
                        // Metadata Details Card
                        VStack(spacing: 1) {
                            detailRow(label: "Category", icon: category.sfSymbol, color: category.color, value: category.label)
                            Divider().overlay(Color.white.opacity(0.06))
                            
                            detailRow(label: "Account", icon: account.sfSymbol, color: account.color, value: account.label)
                            
                            if let toId = transaction.toAccountId, transaction.type == .transfer {
                                let toAcc = store.account(for: toId)
                                Divider().overlay(Color.white.opacity(0.06))
                                detailRow(label: "To Account", icon: toAcc.sfSymbol, color: toAcc.color, value: toAcc.label)
                            }
                            
                            Divider().overlay(Color.white.opacity(0.06))
                            detailRow(label: "Date", icon: SFIcons.calendar, color: SpendyColors.primaryBlue, value: transaction.date.formattedFullDate)
                            
                            Divider().overlay(Color.white.opacity(0.06))
                            detailRow(label: "Time", icon: "clock.fill", color: SpendyColors.accentCyan, value: transaction.date.formattedTime)
                            
                            if let notes = transaction.notes, !notes.isEmpty {
                                Divider().overlay(Color.white.opacity(0.06))
                                detailRow(label: "Notes", icon: "note.text", color: SpendyColors.warningOrange, value: notes)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        }
                        
                        // Delete Button
                        Button(action: {
                            HapticsManager.shared.trigger(.warning)
                            showDeleteConfirm = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: SFIcons.delete)
                                    .font(.system(size: 15, weight: .bold))
                                Text("Delete Transaction")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(SpendyColors.expenseRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(SpendyColors.cardBackground)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(SpendyColors.expenseRed.opacity(0.2), lineWidth: 0.8)
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Delete this transaction?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    store.deleteTransaction(id: transaction.id)
                    dismiss()
                }
            }
        }
        .presentationDetents([.fraction(0.85), .large])
    }
    
    private func detailRow(label: String, icon: String, color: Color, value: String) -> some View {
        HStack(spacing: 12) {
            CategoryIconBadge(sfSymbol: icon, tintColor: color, size: .small)
            
            Text(label)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(14)
        .background(SpendyColors.cardBackground)
    }
    
    private var amountFormatted: String {
        switch transaction.type {
        case .expense: return "-\(transaction.amount.formattedCurrency(symbol: store.currencySymbol))"
        case .income: return "+\(transaction.amount.formattedCurrency(symbol: store.currencySymbol))"
        case .transfer: return transaction.amount.formattedCurrency(symbol: store.currencySymbol)
        }
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .expense: return .white
        case .income: return SpendyColors.incomeGreen
        case .transfer: return SpendyColors.transferBlue
        }
    }
}
