import SwiftUI

struct SpendingBreakdownRow: View {
    let item: AnalyticsBreakdownItem
    let isIncome: Bool
    let currencySymbol: String
    let tint: Color

    var body: some View {
        SpendyListRow {
            SpendyIconBadge(sfSymbol: item.sfSymbol, color: tint,
                size: .medium, style: .circle, monogramName: item.label)
        } content: {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.label).font(AppTypography.rowTitle)
                Text("\(item.txCount) \(isIncome ? (item.txCount == 1 ? "income transaction" : "income transactions") : (item.txCount == 1 ? "expense" : "expenses"))")
                    .font(.footnote).foregroundStyle(SpendyColors.textSecondary)
            }
        } value: {
            VStack(alignment: .trailing, spacing: 3) {
                Text(item.amount.formattedCurrency(symbol: currencySymbol, decimals: 2))
                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                HStack(spacing: 5) {
                    Circle().fill(tint).frame(width: 6, height: 6)
                    Text(item.percentage.formatted(.number.precision(.fractionLength(1))) + "%")
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(SpendyColors.textSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .foregroundStyle(SpendyColors.textPrimary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.label), \(item.txCount) transactions, \(item.amount.formattedCurrency(symbol: currencySymbol, decimals: 2)), \(item.percentage.formatted(.number.precision(.fractionLength(1)))) percent")
    }
}
