//
//  AppState.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

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
    var isVip: Bool = false
    
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
}
