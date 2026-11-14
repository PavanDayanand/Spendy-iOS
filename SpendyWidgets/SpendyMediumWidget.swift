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
            SpendyWeekWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Spending Pulse")
        .description("See your spending over the last seven days.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
        .description("Add an expense, scan a receipt, or see your spending trends.")
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
        .description("See where your money went this month.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
