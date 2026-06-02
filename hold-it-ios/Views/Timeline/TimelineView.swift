//
//  TimelineView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    
    var groupedRecords: [(String, [ResistRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            if calendar.isDateInToday(record.createdAt) {
                return "今天"
            } else if calendar.isDateInYesterday(record.createdAt) {
                return "昨天"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "M月d日"
                return formatter.string(from: record.createdAt)
            }
        }
        return grouped.sorted { pair1, pair2 in
            let date1 = pair1.value.first?.createdAt ?? Date()
            let date2 = pair2.value.first?.createdAt ?? Date()
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("暂无记录", systemImage: "doc.text")
                        } description: {
                            Text("去首页记录你的第一次克制吧")
                        }
                    }
                } else {
                    ForEach(groupedRecords, id: \.0) { date, dayRecords in
                        Section {
                            ForEach(dayRecords) { record in
                                TimelineRow(record: record)
                            }
                        } header: {
                            Text(date)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.systemGroupedBackground)
            .navigationTitle("时间线")
        }
    }
}

struct TimelineRow: View {
    let record: ResistRecord
    
    var body: some View {
        HStack(spacing: 14) {
            Text(record.categoryEmoji)
                .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.category)
                        .font(.subheadline.weight(.medium))
                    
                    if let amount = record.amount {
                        Text("省 ¥\(Int(amount))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12))
                            .foregroundStyle(.green)
                            .cornerRadius(4)
                    }
                }
                
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text(timeString(from: record.createdAt))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
