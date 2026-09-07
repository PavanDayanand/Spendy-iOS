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
        
        let accent = subscription.map { Color(hex: $0.colorHex) }
        
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
                    style: .circle,
                    monogramName: sub.name
                )
            } else {
                SpendyIconBadge(
                    sfSymbol: category.sfSymbol,
                    color: category.color,
                    size: .medium,
                    style: .rounded(),
                    monogramName: category.label
                )
            }
        } titleContent: {
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 5) {
                    Image(systemName: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(SpendyColors.isMonoMode ? SpendyColors.inverseText : .white)
                        .frame(width: 14, height: 14)
                        .background(
                            SpendyColors.isMonoMode ? SpendyColors.textPrimary : account.color,
                            in: RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        )
                        .shadow(color: (SpendyColors.isMonoMode ? SpendyColors.textPrimary : account.color).opacity(0.35), radius: 1, x: 0, y: 0)
                    
                    Text(account.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
            }
        } trailingContent: {
            VStack(alignment: .trailing, spacing: 3) {
                Text(amountText)
                    .spendyNumberFont(size: 16, weight: .bold, tracking: -0.4)
                    .foregroundStyle(amountColor)
                
                if let toId = transaction.toAccountId, transaction.type == .transfer {
                    let toAccount = store.account(for: toId)
                    Text("→ \(toAccount.label)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SpendyColors.transferBlue)
                } else {
                    Text(transaction.date.formattedRelative)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
        }
    }
    
    private var amountText: String {
        transaction.amount.formattedCurrency(symbol: store.currencySymbol)
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .expense:
            return SpendyColors.textPrimary
        case .income:
            return SpendyColors.incomeGreen
        case .transfer:
            return SpendyColors.transferBlue
        }
    }
}
