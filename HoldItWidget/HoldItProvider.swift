//
//  HoldItProvider.swift
//  HoldItWidget
//

import WidgetKit
import Foundation

struct HoldItEntry: TimelineEntry {
    let date: Date
    let stats: WidgetDataStore.Stats
}

struct HoldItProvider: TimelineProvider {
    func placeholder(in context: Context) -> HoldItEntry {
        HoldItEntry(date: Date(), stats: WidgetDataStore.Stats(
            todayCount: 3,
            totalCount: 42,
            streakDays: 7,
            totalSaved: 258.0,
            currencySymbol: "¥"
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (HoldItEntry) -> Void) {
        let stats = WidgetDataStore.load()
        let entry = HoldItEntry(date: Date(), stats: stats)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HoldItEntry>) -> Void) {
        let stats = WidgetDataStore.load()
        let entry = HoldItEntry(date: Date(), stats: stats)
        // 每 15 分钟刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
