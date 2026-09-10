//
//  SpendyWidgetTimelineProvider.swift
//  SpendyWidgets
//

import WidgetKit
import SwiftUI
import AppIntents

struct SpendyWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SpendyWidgetSnapshot
}

struct SpendyConfiguredEntry: TimelineEntry {
    let date: Date
    let snapshot: SpendyWidgetSnapshot
    let configuration: SpendyHomeWidgetIntent
}

struct SpendyWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendyWidgetEntry {
        SpendyWidgetEntry(date: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendyWidgetEntry) -> Void) {
        let snapshot = context.isPreview ? SpendyWidgetSnapshot.preview : WidgetDataManager.shared.loadSnapshot()
        completion(SpendyWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendyWidgetEntry>) -> Void) {
        let snapshot = WidgetDataManager.shared.loadSnapshot()
        let now = Date()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        completion(Timeline(entries: [SpendyWidgetEntry(date: now, snapshot: snapshot)], policy: .after(nextUpdate)))
    }
}

struct SpendyConfigurableProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SpendyConfiguredEntry {
        SpendyConfiguredEntry(date: Date(), snapshot: .preview, configuration: SpendyHomeWidgetIntent())
    }

    func snapshot(for configuration: SpendyHomeWidgetIntent, in context: Context) async -> SpendyConfiguredEntry {
        let snapshot = context.isPreview ? SpendyWidgetSnapshot.preview : WidgetDataManager.shared.loadSnapshot()
        return SpendyConfiguredEntry(date: Date(), snapshot: snapshot, configuration: configuration)
    }

    func timeline(for configuration: SpendyHomeWidgetIntent, in context: Context) async -> Timeline<SpendyConfiguredEntry> {
        let snapshot = WidgetDataManager.shared.loadSnapshot()
        let now = Date()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        return Timeline(
            entries: [SpendyConfiguredEntry(date: now, snapshot: snapshot, configuration: configuration)],
            policy: .after(next)
        )
    }
}
