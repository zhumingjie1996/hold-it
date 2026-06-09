//
//  HoldItWidget.swift
//  HoldItWidget
//

import WidgetKit
import SwiftUI

struct HoldItWidget: Widget {
    let kind: String = "HoldItWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HoldItProvider()) { entry in
            HoldItWidgetView(entry: entry)
        }
        .configurationDisplayName(String(localized: "忍一下"))
        .description(String(localized: "展示你的忍住记录统计"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
