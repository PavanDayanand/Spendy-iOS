import SwiftUI
import WidgetKit

struct SpendySubscriptionsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.spendyWidgetGlassPreview) private var glassPreview
    let snapshot: SpendyWidgetSnapshot
    var previewFamily: WidgetFamily? = nil

    private var isSmall: Bool { (previewFamily ?? family) == .systemSmall }
    private var next: WidgetSubscriptionItem? { snapshot.subscriptions.first }

    private func timing(for item: WidgetSubscriptionItem) -> String {
        let overdue = Calendar.current.startOfDay(for: item.renewalDate) < Calendar.current.startOfDay(for: .now)
        let label = overdue ? "Check payment" : item.isTrial ? "Trial ends" : "Next renewal"
        return "\(label) · \(item.renewalDate.formatted(.dateTime.day().month(.abbreviated)))"
    }

    private var icons: some View {
        HStack(spacing: -10) {
            ForEach(snapshot.subscriptions.prefix(3)) { item in
                SubscriptionProgressRingBadge(sfSymbol: item.sfSymbol,
                    color: SpendyHexColor.color(from: item.colorHex),
                    progress: item.cycleStart.map {
                        min(1, max(0.05, Date().timeIntervalSince($0) / max(1, item.renewalDate.timeIntervalSince($0))))
                    } ?? 0,
                    size: isSmall ? .small : .medium,
                    monogramName: item.name, animatesProgress: false)
                .background { Circle().fill(SpendyWidgetPalette.canvas).padding(-1) }
                .modifier(SpendyWidgetBadgeAppearance())
            }
        }
        .accessibilityHidden(true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Subscriptions")
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundStyle(SpendyWidgetPalette.secondary)
            if let next {
                Spacer(minLength: isSmall ? 3 : 6)
                SpendyWidgetAmount(amount: next.amount, symbol: snapshot.currencySymbol, size: isSmall ? 28 : 32)
                Text(next.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                    .lineLimit(1)
                Spacer(minLength: isSmall ? 3 : 6)
                if isSmall {
                    icons
                    Text(timing(for: next))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SpendyWidgetPalette.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .padding(.top, 5)
                } else {
                    HStack(alignment: .bottom) {
                        Text(timing(for: next))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyWidgetPalette.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        icons
                    }
                }
            } else {
                Spacer(minLength: 8)
                Image(systemName: "repeat")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                    .accessibilityHidden(true)
                Text("No renewals")
                    .font(.headline)
                    .foregroundStyle(SpendyWidgetPalette.text)
                    .padding(.top, 8)
                Spacer(minLength: 8)
                Text("Manage subscriptions")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
            }
        }
        .spendyWidgetChrome(transparent: glassPreview)
        .widgetURL(URL(string: "spendy://subscriptions"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(next.map {
            "\($0.name), \(SpendyWidgetFormat.amount($0.amount, symbol: snapshot.currencySymbol)), \(timing(for: $0))"
        } ?? "No renewals. Manage subscriptions in Spendy.")
    }
}
