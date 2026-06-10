//
//  QuickRecordWidget.swift
//  HoldItWidget
//

import WidgetKit
import SwiftUI

// 快捷记录 Widget 不需要真实数据，使用简单的空 Provider
struct QuickRecordEntry: TimelineEntry {
    let date: Date
}

struct QuickRecordProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickRecordEntry {
        QuickRecordEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickRecordEntry) -> Void) {
        completion(QuickRecordEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickRecordEntry>) -> Void) {
        // 按钮 Widget 无需定期刷新，设置较长的间隔
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [QuickRecordEntry(date: Date())], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct QuickRecordWidget: Widget {
    let kind: String = "QuickRecordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickRecordProvider()) { _ in
            QuickRecordWidgetView()
        }
        .configurationDisplayName(String(localized: "快速记录"))
        .description(String(localized: "一键打开忍住记录"))
        .supportedFamilies([.systemSmall])
    }
}
