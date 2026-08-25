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
        let subscription = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == transaction.subscriptionId?.lowercased() })
        let tintColor = subscription?.color ?? category.color
        
        let accent = subscription != nil ? Color(hex: subscription!.colorHex) : nil
        
        SpendyRowCard(
            accentColor: accent,
            cornerRadius: 16,
            paddingHorizontal: 14,
            paddingVertical: 12
        ) {
            // Icon Badge: Unified SpendyIconBadge for Subscription (if linked) or Category
            if let sub = subscription {
                SpendyIconBadge(
                    sfSymbol: sub.sfSymbol,
                    color: Color(hex: sub.colorHex),
                    size: .medium,
                    style: .circle
                )
            } else {
                SpendyIconBadge(
                    sfSymbol: category.sfSymbol,
                    color: category.color,
                    size: .medium,
                    style: .circle
                )
            }
        } titleContent: {
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(account.label)
                    Text("•")
                    Text(transaction.date.formattedRelative)
                }
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.5))
            }
        } trailingContent: {
            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(.system(size: 17, weight: .medium).monospacedDigit())
                    .foregroundStyle(amountColor)
                
                if let toId = transaction.toAccountId, transaction.type == .transfer {
                    let toAccount = store.account(for: toId)
                    Text("→ \(toAccount.label)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SpendyColors.transferBlue)
                }
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
