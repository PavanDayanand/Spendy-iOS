//
//  SpendySmallWidget.swift
//  SpendyWidgets
//

import SwiftUI
import WidgetKit

struct SpendyTodayWidget: Widget {
    let kind = "com.Spendy.widgets"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SpendyHomeWidgetIntent.self,
            provider: SpendyConfigurableProvider()
        ) { entry in
            SpendyConfiguredWidgetView(snapshot: entry.snapshot, configuration: entry.configuration)
        }
        .configurationDisplayName("Today")
        .description("Today’s spending at a glance. Edit to choose a budget or category view.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct SpendyBudgetWidget: Widget {
    let kind = "SpendyBudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendyWidgetTimelineProvider()) { entry in
            SpendyBudgetWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Budget Room")
        .description("What remains in your current budget cycle.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct SpendyLockWidget: Widget {
    let kind = "SpendyLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendyWidgetTimelineProvider()) { entry in
            SpendyLockEntryView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Today’s spend on the Lock Screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

private struct SpendyLockEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SpendyWidgetEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            SpendyAccessoryRectangularView(snapshot: entry.snapshot)
        case .accessoryInline:
            SpendyAccessoryInlineView(snapshot: entry.snapshot)
        default:
            SpendyAccessoryCircularView(snapshot: entry.snapshot)
        }
    }
}

#Preview(as: .systemSmall) {
    SpendyTodayWidget()
} timeline: {
    SpendyConfiguredEntry(date: .now, snapshot: .preview, configuration: SpendyHomeWidgetIntent())
}

#Preview(as: .systemSmall) {
    SpendyBudgetWidget()
} timeline: {
    SpendyWidgetEntry(date: .now, snapshot: .preview)
}
