//
//  WidgetDataStore.swift
//  hold-it-ios
//

import Foundation

/// Widget 与主 App 共享数据的桥接层
enum WidgetDataStore {
    /// App Group 标识（主 App 和 Widget Extension 必须一致）
    static let appGroupID = "group.mj.holdit.ios"

    private static var shared: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Keys
    private enum Keys {
        static let todayCount      = "widget_todayCount"
        static let totalCount      = "widget_totalCount"
        static let streakDays      = "widget_streakDays"
        static let totalSaved      = "widget_totalSaved"
        static let currencySymbol  = "widget_currencySymbol"
        static let lastUpdated     = "widget_lastUpdated"
    }

    // MARK: - WidgetStats
    struct Stats {
        var todayCount: Int = 0
        var totalCount: Int = 0
        var streakDays: Int = 0
        var totalSaved: Double = 0
        var currencySymbol: String = "¥"
        var lastUpdated: Date = Date()
    }

    // MARK: - Write
    static func save(stats: Stats) {
        guard let defaults = shared else { return }
        defaults.set(stats.todayCount, forKey: Keys.todayCount)
        defaults.set(stats.totalCount, forKey: Keys.totalCount)
        defaults.set(stats.streakDays, forKey: Keys.streakDays)
        defaults.set(stats.totalSaved, forKey: Keys.totalSaved)
        defaults.set(stats.currencySymbol, forKey: Keys.currencySymbol)
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastUpdated)
        defaults.synchronize()
    }

    // MARK: - Read
    static func load() -> Stats {
        guard let defaults = shared else { return Stats() }
        let updated = defaults.double(forKey: Keys.lastUpdated)
        return Stats(
            todayCount:     defaults.integer(forKey: Keys.todayCount),
            totalCount:     defaults.integer(forKey: Keys.totalCount),
            streakDays:     defaults.integer(forKey: Keys.streakDays),
            totalSaved:     defaults.double(forKey: Keys.totalSaved),
            currencySymbol: defaults.string(forKey: Keys.currencySymbol) ?? "¥",
            lastUpdated:    Date(timeIntervalSince1970: updated)
        )
    }
}
