import SwiftUI

struct SpendingBreakdownRow: View {
    let item: AnalyticsBreakdownItem
    let isIncome: Bool
    let currencySymbol: String
    var tint: Color = SpendyColors.textPrimary

    var body: some View {
        HStack(spacing: 12) {
            SpendyIconBadge(sfSymbol: item.sfSymbol, color: tint,
                size: .medium, style: .circle, monogramName: item.label)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.label).font(AppTypography.rowTitle)
                Text("\(item.txCount) \(isIncome ? "income transactions" : (item.txCount == 1 ? "expense" : "expenses"))")
                    .font(AppTypography.footnoteMedium).foregroundStyle(SpendyColors.textSecondary)
            }
            Spacer(minLength: 4)
            Text(item.amount.formattedCurrency(symbol: currencySymbol, decimals: 2))
                .spendyRowAmount()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SpendyColors.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8) }
        .foregroundStyle(SpendyColors.textPrimary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.label), \(item.txCount) transactions, \(item.amount.formattedCurrency(symbol: currencySymbol, decimals: 2))")
    }
}
