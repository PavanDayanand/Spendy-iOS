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
        .configurationDisplayName("This Week")
        .description("Today’s spend and a 7-day pulse.")
        .supportedFamilies([.systemMedium])
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
        .configurationDisplayName("Categories")
        .description("Top three categories this month.")
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
        .configurationDisplayName("Overview")
        .description("Today, this week, and recent activity.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}
