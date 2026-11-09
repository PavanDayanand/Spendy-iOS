import SwiftUI

/// Transaction content shared by Home, the transaction browser, and entity activity.
struct TransactionRowView: View {
    let transaction: Transaction
    var amountsHidden = false
    var showsCategory = false
    @Environment(ExpenseStore.self) private var store

    var body: some View {
        let category = store.displayCategory(for: transaction)
        let account = store.account(for: transaction.accountId)
        let subscription = store.subscriptions.first {
            $0.id.uuidString.lowercased() == transaction.subscriptionId?.lowercased()
        }
        SpendyListRow {
            SpendyIconBadge(sfSymbol: subscription?.sfSymbol ?? category.sfSymbol,
                color: subscription?.color ?? category.color, size: .medium, style: .circle,
                monogramName: subscription?.name ?? category.label)
        } content: {
            VStack(alignment: .leading, spacing: 3) {
                Text(store.displayTitle(for: transaction))
                    .font(AppTypography.rowTitle)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(2)
                Text(transaction.type == .transfer ? store.transferAccountRoute(for: transaction)
                    : showsCategory ? category.label : account.label)
                    .font(.footnote)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(2)
                if let notes = transaction.notes, !notes.isEmpty {
                    Text(notes).font(.caption)
                        .foregroundStyle(SpendyColors.textTertiary)
                        .lineLimit(1)
                }
            }
        } value: {
            VStack(alignment: .trailing, spacing: 3) {
                Text(amountsHidden ? "••••" : amountText)
                    .spendyRowAmount()
                    .foregroundStyle(transaction.type == .income ? SpendyColors.incomeGreen : SpendyColors.textPrimary)
                    .accessibilityLabel(amountsHidden ? "Amount hidden" : amountText)
                Text(transaction.date.formattedRelative)
                    .font(.caption)
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .accessibilityElement(children: .combine)
    }

    private var amountText: String {
        let amount = transaction.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 2)
        return transaction.type == .income ? "+" + amount : amount
    }
}
