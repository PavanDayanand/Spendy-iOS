import SwiftUI

/// A quiet, dotted version of the Budget screen's 240-degree arc.
struct BudgetMiniGauge: View {
    var progress: Double?

    private let arc = 2.0 / 3.0
    private let dots = StrokeStyle(lineWidth: 3, lineCap: .round, dash: [0.5, 5])

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: arc)
                .stroke(SpendyColors.textPrimary.opacity(0.15), style: dots)
            if let progress {
                Circle()
                    .trim(from: 0, to: arc * min(max(progress, 0), 1))
                    .stroke(SpendyColors.textPrimary, style: dots)
            }
        }
        .rotationEffect(.degrees(150))
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
