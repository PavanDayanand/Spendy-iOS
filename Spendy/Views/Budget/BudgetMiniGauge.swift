import SwiftUI

struct BudgetMiniGauge: View {
    var progress: Double?

    var body: some View {
        BudgetProgressArc(progress: progress, lineWidth: 7)
            .overlay {
                Text(progress.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "—")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 8)
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .frame(width: 68, height: 68)
            .accessibilityHidden(true)
    }
}
