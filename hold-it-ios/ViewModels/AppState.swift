//
//  AppState.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData
import WidgetKit

// MARK: - 货币配置

/// 支持的货币列表
enum SupportedCurrency: String, CaseIterable, Identifiable {
    case auto   = "auto"
    case cny    = "CNY"
    case usd    = "USD"
    case eur    = "EUR"
    case jpy    = "JPY"
    case gbp    = "GBP"
    case hkd    = "HKD"
    case twd    = "TWD"
    case krw    = "KRW"

    var id: String { rawValue }

    /// 显示名称（本地化）
    var displayName: String {
        switch self {
        case .auto: return String(localized: "跟随系统")
        case .cny:  return String(localized: "人民币 (¥)")
        case .usd:  return String(localized: "美元 ($)")
        case .eur:  return String(localized: "欧元 (€)")
        case .jpy:  return String(localized: "日元 (¥)")
        case .gbp:  return String(localized: "英镑 (£)")
        case .hkd:  return String(localized: "港元 (HK$)")
        case .twd:  return String(localized: "台币 (NT$)")
        case .krw:  return String(localized: "韩元 (₩)")
        }
    }

    /// 对应的货币符号
    var symbol: String {
        switch self {
        case .auto: return SupportedCurrency.systemSymbol
        case .cny:  return "¥"
        case .usd:  return "$"
        case .eur:  return "€"
        case .jpy:  return "¥"
        case .gbp:  return "£"
        case .hkd:  return "HK$"
        case .twd:  return "NT$"
        case .krw:  return "₩"
        }
    }

    /// 读取系统当前 Locale 对应的货币符号
    static var systemSymbol: String {
        guard let code = Locale.current.currency?.identifier else { return "¥" }
        // 用系统 Locale formatter 拿到简短符号
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale.current
        return formatter.currencySymbol ?? "¥"
    }
}

@Observable
class AppState {
    func todayCount(from records: [ResistRecord]) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return records.filter { $0.createdAt >= startOfDay }.count
    }

    func thisWeekCount(from records: [ResistRecord]) -> Int {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return records.filter { $0.createdAt >= startOfWeek }.count
    }

    func thisMonthCount(from records: [ResistRecord]) -> Int {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start else { return 0 }
        return records.filter { $0.createdAt >= startOfMonth }.count
    }

    func thisYearCount(from records: [ResistRecord]) -> Int {
        let calendar = Calendar.current
        guard let startOfYear = calendar.dateInterval(of: .year, for: Date())?.start else { return 0 }
        return records.filter { $0.createdAt >= startOfYear }.count
    }
    
    func streakDays(from records: [ResistRecord]) -> Int {
        guard !records.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = records.map { calendar.startOfDay(for: $0.createdAt) }
            .sorted(by: >)
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        if !sortedDates.contains(checkDate) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        var dateSet = Set(sortedDates)
        while dateSet.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        return streak
    }

    func bestStreak(from records: [ResistRecord]) -> Int {
        guard !records.isEmpty else { return 0 }
        let calendar = Calendar.current
        let dateSet = Set(records.map { calendar.startOfDay(for: $0.createdAt) })
        let sortedDates = dateSet.sorted()
        var best = 1
        var current = 1
        for i in 1..<sortedDates.count {
            let diff = calendar.dateComponents([.day], from: sortedDates[i - 1], to: sortedDates[i]).day ?? 0
            if diff == 1 {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }
    
    func totalCount(from records: [ResistRecord]) -> Int {
        records.count
    }
    
    func totalSavedAmount(from records: [ResistRecord]) -> Double {
        records.compactMap { $0.amount }.reduce(0, +)
    }

    // MARK: - 节省金额详细统计

    /// 本月节省金额
    func thisMonthSavedAmount(from records: [ResistRecord]) -> Double {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start else { return 0 }
        return records.filter { $0.createdAt >= startOfMonth }.compactMap { $0.amount }.reduce(0, +)
    }

    /// 今年节省金额
    func thisYearSavedAmount(from records: [ResistRecord]) -> Double {
        let calendar = Calendar.current
        guard let startOfYear = calendar.dateInterval(of: .year, for: Date())?.start else { return 0 }
        return records.filter { $0.createdAt >= startOfYear }.compactMap { $0.amount }.reduce(0, +)
    }

    /// 本周节省金额
    func thisWeekSavedAmount(from records: [ResistRecord]) -> Double {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return records.filter { $0.createdAt >= startOfWeek }.compactMap { $0.amount }.reduce(0, +)
    }

    /// 今天节省金额
    func todaySavedAmount(from records: [ResistRecord]) -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return records.filter { $0.createdAt >= startOfDay }.compactMap { $0.amount }.reduce(0, +)
    }

    /// 按分类的节省金额统计
    func savedAmountByCategory(from records: [ResistRecord]) -> [(emoji: String, name: String, categoryID: String, amount: Double, count: Int)] {
        let withAmount = records.filter { $0.amount != nil }
        let grouped = Dictionary(grouping: withAmount) { $0.effectiveCategoryID }
        return grouped.map { catID, items in
            let emoji = items.first?.categoryEmoji ?? ""
            let fallback = items.first?.category ?? catID
            let name = localizedCategoryName(categoryID: catID, fallback: fallback)
            let total = items.compactMap { $0.amount }.reduce(0, +)
            return (emoji, name, catID, total, items.count)
        }.sorted { $0.amount > $1.amount }
    }

    /// 月度节省金额趋势（近6个月）
    func monthlySavedAmountTrend(from records: [ResistRecord]) -> [(label: String, amount: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        let grouped = Dictionary(grouping: records) { formatter.string(from: $0.createdAt) }

        var data: [(String, Double)] = []
        for offset in stride(from: -5, through: 0, by: 1) {
            if let date = calendar.date(byAdding: .month, value: offset, to: Date()) {
                let key = formatter.string(from: date)
                let amount = grouped[key]?.compactMap { $0.amount }.reduce(0, +) ?? 0
                let displayFormatter = DateFormatter()
                displayFormatter.locale = Locale.current
                displayFormatter.setLocalizedDateFormatFromTemplate("MMM")
                let label = displayFormatter.string(from: date)
                data.append((label, amount))
            }
        }
        return data
    }

    /// 节省金额最多的一天
    func bestSavedDay(from records: [ResistRecord]) -> (date: Date, amount: Double)? {
        let calendar = Calendar.current
        let withAmount = records.filter { $0.amount != nil }
        guard !withAmount.isEmpty else { return nil }
        let grouped = Dictionary(grouping: withAmount) { calendar.startOfDay(for: $0.createdAt) }
        let best = grouped.map { (date, items) in
            (date, items.compactMap { $0.amount }.reduce(0, +))
        }.max { $0.1 < $1.1 }
        guard let best, best.1 > 0 else { return nil }
        return best
    }

    /// 平均每次节省金额（仅含填写了金额的记录）
    func averageSavedAmount(from records: [ResistRecord]) -> Double {
        let amounts = records.compactMap { $0.amount }
        guard !amounts.isEmpty else { return 0 }
        return amounts.reduce(0, +) / Double(amounts.count)
    }

    /// 含有金额的记录数
    func recordsWithAmountCount(from records: [ResistRecord]) -> Int {
        records.filter { $0.amount != nil }.count
    }

    // MARK: - Widget 数据同步

    /// 将关键统计数据写入 App Group 共享容器，供 Widget Extension 读取
    func syncWidgetData(from records: [ResistRecord]) {
        let stats = WidgetDataStore.Stats(
            todayCount:     todayCount(from: records),
            totalCount:     totalCount(from: records),
            streakDays:     streakDays(from: records),
            totalSaved:     totalSavedAmount(from: records),
            currencySymbol: SupportedCurrency.systemSymbol
        )
        WidgetDataStore.save(stats: stats)
        WidgetCenter.shared.reloadTimelines(ofKind: "HoldItWidget")
    }
}
