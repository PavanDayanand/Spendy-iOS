import SwiftUI
import WidgetKit

struct SpendyWeekWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.spendyWidgetGlassPreview) private var glassPreview
    let snapshot: SpendyWidgetSnapshot
    var previewFamily: WidgetFamily? = nil

    var body: some View {
        let resolved = previewFamily ?? family
        let total = snapshot.weeklySpending.reduce(0) { $0 + $1.amount }
        Group {
            if resolved == .systemMedium {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last 7 days").font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SpendyWidgetPalette.secondary)
                        Spacer(minLength: 0)
                        SpendyWidgetAmount(amount: total, symbol: snapshot.currencySymbol, size: 34)
                        Spacer(minLength: 0)
                        Text("\(SpendyWidgetFormat.compactAmount(total / 7, symbol: snapshot.currencySymbol)) daily avg")
                            .font(.system(size: 11)).foregroundStyle(SpendyWidgetPalette.secondary)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    SpendyWeekBars(days: snapshot.weeklySpending, accentHex: "", height: 68)
                        .frame(maxWidth: .infinity)
                }
            } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Last 7 days").font(.system(size: 12, weight: .semibold)).foregroundStyle(SpendyWidgetPalette.secondary)
                SpendyWidgetAmount(amount: total, symbol: snapshot.currencySymbol, size: resolved == .systemSmall ? 30 : 40)
                Spacer(minLength: 0)
                SpendyWeekBars(days: snapshot.weeklySpending, accentHex: "", height: resolved == .systemSmall || resolved == .systemMedium ? 38 : 110)
                if resolved == .systemLarge || resolved == .systemExtraLarge {
                    Divider().padding(.vertical, 8)
                    HStack {
                        Text("Daily average").font(.caption).foregroundStyle(SpendyWidgetPalette.secondary)
                        Spacer()
                        SpendyWidgetAmount(amount: total / 7, symbol: snapshot.currencySymbol, size: 20)
                    }
                }
            }
            }
        }
        .spendyWidgetChrome(transparent: glassPreview)
        .widgetURL(URL(string: "spendy://analytics"))
        .accessibilityElement(children: .combine)
    }
}
