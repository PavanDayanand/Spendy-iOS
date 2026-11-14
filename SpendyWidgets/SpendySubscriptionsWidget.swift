import SwiftUI
import WidgetKit

struct SpendySubscriptionsWidget: Widget {
    let kind = "SpendySubscriptionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendyWidgetTimelineProvider()) { entry in
            SpendySubscriptionsWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Subscriptions")
        .description("See your next renewal and the subscriptions coming up.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
