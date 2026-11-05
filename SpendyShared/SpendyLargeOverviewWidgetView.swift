import SwiftUI
import WidgetKit

struct SpendyLargeOverviewWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.spendyWidgetGlassPreview) private var glassPreview
    let snapshot: SpendyWidgetSnapshot
    var previewFamily: WidgetFamily? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            SpendyMonthlyBriefColumn(snapshot: snapshot)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if (previewFamily ?? family) == .systemExtraLarge {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Where it went").font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SpendyWidgetPalette.secondary)
                    if snapshot.categorySpending.isEmpty {
                        Text("No spending yet").foregroundStyle(SpendyWidgetPalette.secondary)
                    } else {
                        SpendyCategoryRanking(snapshot: snapshot)
                    }
                    Divider()
                    HStack {
                        Text("Today").font(.caption).foregroundStyle(SpendyWidgetPalette.secondary)
                        Spacer()
                        SpendyWidgetAmount(amount: snapshot.todayTotal, symbol: snapshot.currencySymbol, size: 24)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .spendyWidgetChrome(transparent: glassPreview)
        .widgetURL(URL(string: "spendy://analytics"))
    }
}
