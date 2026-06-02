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
    
    func totalCount(from records: [ResistRecord]) -> Int {
        records.count
    }
    
    func totalSavedAmount(from records: [ResistRecord]) -> Double {
        records.compactMap { $0.amount }.reduce(0, +)
    }
}
