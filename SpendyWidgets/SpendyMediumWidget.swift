//
//  SpendyMediumWidget.swift
//  SpendyWidgets
//

import SwiftUI
import WidgetKit

struct SpendyWeekWidget: Widget {
    let kind = "SpendyWeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendyWidgetTimelineProvider()) { entry in
            SpendyMediumWeekWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Spending Pulse")
        .description("Today’s spending and the last seven days.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct SpendyQuickActionsWidget: Widget {
    let kind = "SpendyQuickActionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendyWidgetTimelineProvider()) { entry in
            SpendyQuickActionsWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Quick actions")
        .description("Add an expense, scan a receipt, or open your budget and trends.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct SpendyActivityWidget: Widget {
    let kind = "SpendyActivityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendyWidgetTimelineProvider()) { entry in
            SpendyMediumActivityWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Recent")
        .description("Your last two transactions.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct SpendyCategoriesWidget: Widget {
    let kind = "SpendyCategoriesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendyWidgetTimelineProvider()) { entry in
            SpendyMediumCategoriesWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Where It Went")
        .description("The categories driving this month’s spending.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct SpendyOverviewWidget: Widget {
    let kind = "SpendyOverviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendyWidgetTimelineProvider()) { entry in
            SpendyLargeOverviewWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Monthly Brief")
        .description("A monthly comparison, seven-day trend, top category, and budget room.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}
