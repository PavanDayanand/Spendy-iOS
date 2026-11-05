import SwiftUI
import Charts

/// Native proportional sectors, with a small opening and rounded, petal-like wedges.
struct SpendingMixChart: View {
    let items: [AnalyticsBreakdownItem]
    let currencySymbol: String
    let isIncome: Bool
    @State private var selectedAngle: Double?

    private var slices: [AnalyticsBreakdownItem] {
        let positive = items.filter { $0.amount > 0 }
        guard positive.count > 7 else { return positive }
        let tail = positive.dropFirst(7)
        return Array(positive.prefix(7)) + [AnalyticsBreakdownItem(
            id: "mix-other", label: "Other", sfSymbol: "ellipsis", colorHex: "#8E8E93",
            txCount: tail.reduce(0) { $0 + $1.txCount },
            amount: tail.reduce(0) { $0 + $1.amount },
            percentage: tail.reduce(0) { $0 + $1.percentage })]
    }

    private var selectedItem: AnalyticsBreakdownItem? {
        guard let selectedAngle else { return nil }
        var cumulative = 0.0
        return slices.first { item in
            cumulative += item.amount
            return selectedAngle < cumulative
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Chart(slices) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.20),
                    angularInset: slices.count > 1 ? 3 : 0
                )
                .cornerRadius(10)
                .foregroundStyle(Color(hex: item.colorHex))
                .opacity(selectedItem == nil || selectedItem?.id == item.id ? 1 : 0.35)
                .annotation(position: .overlay) {
                    if item.percentage >= 5 {
                        Image(systemName: item.sfSymbol)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 2)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel(item.label)
                .accessibilityValue("\(item.amount.formattedCurrency(symbol: currencySymbol, decimals: 2)), \(item.percentage.formatted(.number.precision(.fractionLength(1)))) percent")
            }
            .chartLegend(.hidden)
            .chartAngleSelection(value: $selectedAngle)
            .frame(height: 250)
            .accessibilityLabel(isIncome ? "Income by category" : "Spending by category")

            if let item = selectedItem {
                VStack(spacing: 4) {
                    Text(item.label).font(.subheadline.weight(.semibold))
                    Text("\(item.amount.formattedCurrency(symbol: currencySymbol, decimals: 2)) · \(item.percentage.formatted(.number.precision(.fractionLength(1))))%")
                        .font(.subheadline.monospacedDigit())
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            } else {
                Text("Touch a segment to see its share")
                    .font(.caption)
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            if items.filter({ $0.amount > 0 }).count > 7 {
                Text("Smaller groups are combined as Other")
                    .font(.caption2)
                    .foregroundStyle(SpendyColors.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .onChange(of: items.map(\.id)) { _, _ in selectedAngle = nil }
    }
}
