//
//  WeekdayDistributionView.swift
//  hold-it-ios
//

import SwiftUI

struct WeekdayDistributionView: View {
    let records: [ResistRecord]

    private let weekdayNames: [LocalizedStringKey] = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    var weekdayCounts: [Int] {
        var counts = Array(repeating: 0, count: 7)
        let calendar = Calendar.current
        for record in records {
            // weekday: 1=Sun, 2=Mon ... 7=Sat → remap to Mon=0...Sun=6
            let wd = calendar.component(.weekday, from: record.createdAt)
            let index = (wd + 5) % 7 // Mon=0, Tue=1, ..., Sun=6
            counts[index] += 1
        }
        return counts
    }

    var maxCount: Int { max(weekdayCounts.max() ?? 1, 1) }

    // 最活跃的那天
    var busiestDay: LocalizedStringKey? {
        guard let maxIdx = weekdayCounts.indices.max(by: { weekdayCounts[$0] < weekdayCounts[$1] }),
              weekdayCounts[maxIdx] > 0 else { return nil }
        return weekdayNames[maxIdx]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.brand)
                Text("周几最克制")
                    .font(.headline)
                Spacer()
                if let day = busiestDay {
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.brand.opacity(0.12))
                        .cornerRadius(6)
                }
            }

            if records.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        let count = weekdayCounts[index]
                        let isMax = count == maxCount && count > 0
                        VStack(spacing: 6) {
                            Text("\(count)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(isMax ? Color.brand : .secondary)

                            RoundedRectangle(cornerRadius: 5)
                                .fill(isMax ? Color.brand : Color.brand.opacity(0.25))
                                .frame(height: max(CGFloat(count) / CGFloat(maxCount) * 100, 4))

                            Text(weekdayNames[index])
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }
}
