import SwiftUI
import WidgetKit

struct SpendyCategoryRanking: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        VStack(spacing: 14) {
            ForEach(snapshot.categorySpending.prefix(4)) { category in
                HStack(spacing: 10) {
                    WidgetCategoryBadge(symbol: category.sfSymbol, colorHex: "", name: category.name, size: 32)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(category.name).lineLimit(1)
                            Spacer(minLength: 4)
                            Text(SpendyWidgetFormat.compactAmount(category.amount, symbol: snapshot.currencySymbol))
                                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyWidgetPalette.text)
                        GeometryReader { geometry in
                            Capsule().fill(SpendyWidgetPalette.text.opacity(0.10))
                                .overlay(alignment: .leading) {
                                    Capsule().fill(SpendyWidgetPalette.text)
                                        .frame(width: geometry.size.width * min(1, category.amount / max(1, snapshot.monthTotal)))
                                        .widgetAccentable()
                                }
                        }.frame(height: 4)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}
