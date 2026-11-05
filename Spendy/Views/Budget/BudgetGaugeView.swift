import SwiftUI

struct BudgetGaugeView: View {
    let spent: Double
    let target: Double
    let currencySymbol: String
    var periodTitle: String = "Monthly"
    var dateRangeString: String = ""

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var remaining: Double { target - spent }
    private var isExceeded: Bool { target > 0 && spent > target }
    private var amount: String {
        abs(remaining).formattedCurrency(symbol: currencySymbol, decimals: 0)
    }
    private var tint: Color {
        SpendyColors.isMonoMode ? SpendyColors.textPrimary
            : isExceeded ? SpendyColors.warningOrange : .blue
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(periodTitle) budget")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                Spacer(minLength: 0)
                Text(dateRangeString)
                    .font(.caption)
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            .accessibilityElement(children: .combine)

            ZStack {
                BudgetProgressArc(progress: target > 0 ? spent / target : nil, lineWidth: dynamicTypeSize.isAccessibilitySize ? 25 : 48)
                if !dynamicTypeSize.isAccessibilitySize {
                    remainingAmount
                        .padding(.horizontal, 60)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? 160 : 440)

            if dynamicTypeSize.isAccessibilitySize {
                remainingAmount
            }


        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 8)
    }

    private var remainingAmount: some View {
        VStack(spacing: 6) {
            Text(amount)
                .font(.largeTitle.scaled(by: 1.35).weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(isExceeded ? "over budget" : "left to spend")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SpendyColors.textSecondary)
            Text("of \(target.formattedCurrency(symbol: currencySymbol, decimals: 0))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(SpendyColors.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("budget-remaining-amount")
    }
}
