//
//  EncourageQuote.swift
//  hold-it-ios
//

import Foundation

struct EncourageQuote {

    /// 总数
    static var count: Int { allQuotes.count }

    /// 基于日期确定今日索引（同一天始终返回同一条）
    static func todayIndex() -> Int {
        let calendar = Calendar.current
        let date = Date()
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        // 用日期组合生成一个稳定的哈希
        let seed = year * 10000 + month * 100 + day
        return abs(seed) % allQuotes.count
    }

    /// 随机取一条（排除当前索引，用于手动换一条）
    static func randomIndex(excluding current: Int) -> Int {
        guard allQuotes.count > 1 else { return 0 }
        var newIndex: Int
        repeat {
            newIndex = Int.random(in: 0..<allQuotes.count)
        } while newIndex == current
        return newIndex
    }
}
