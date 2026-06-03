//
//  AppState.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

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
