//
//  TransactionRowView.swift
//  Spendy
//
//  Transaction Row Item with Pure SF Symbols and Native Styling
//

import SwiftUI

struct TransactionRowView: View {
    var transaction: Transaction
    @Environment(ExpenseStore.self) private var store
    
    var body: some View {
        let category = store.category(for: transaction.categoryId)
        let account = store.account(for: transaction.accountId)
        
        HStack(spacing: 12) {
            // SF Symbol Category Icon Badge
            CategoryIconBadge(
                sfSymbol: category.sfSymbol,
                tintColor: category.color,
                size: .medium
            )
            
            // Transaction Info
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(account.label)
                    Text("•")
                    Text(transaction.date.formattedRelative)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Signed Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(.system(.body, weight: .bold))
                    .foregroundStyle(amountColor)
                
                if let toId = transaction.toAccountId, transaction.type == .transfer {
                    let toAccount = store.account(for: toId)
                    Text("→ \(toAccount.label)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SpendyColors.transferBlue)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                }
        }
    }
    
    private var amountText: String {
        switch transaction.type {
        case .expense:
            return "-\(transaction.amount.formattedCurrency(symbol: store.currencySymbol))"
        case .income:
            return "+\(transaction.amount.formattedCurrency(symbol: store.currencySymbol))"
        case .transfer:
            return transaction.amount.formattedCurrency(symbol: store.currencySymbol)
        }
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .expense:
            return .white
        case .income:
            return SpendyColors.incomeGreen
        case .transfer:
            return SpendyColors.transferBlue
        }
    }
}
