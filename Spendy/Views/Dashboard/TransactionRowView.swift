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
        let category = store.displayCategory(for: transaction)
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
                    style: .circle,
                    monogramName: category.label
                )
            }
        } titleContent: {
            VStack(alignment: .leading, spacing: 3) {
                Text(store.displayTitle(for: transaction))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 5) {
                    SpendyMiniColorChip(
                        sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                        color: account.color,
                        monogramName: account.label
                    )
                    
                    Text(transaction.type == .transfer ? store.transferAccountRoute(for: transaction) : account.label)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
            }
        } trailingContent: {
            VStack(alignment: .trailing, spacing: 3) {
                Text(amountText)
                    .spendyNumberFont(size: 16, weight: .bold, tracking: -0.4)
                    .foregroundStyle(amountColor)
                
                Text(transaction.date.formattedRelative)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
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
