//
//  MonthlyTrendView.swift
//  hold-it-ios
//

import SwiftUI

struct MonthlyTrendView: View {
    let records: [ResistRecord]

    var monthlyData: [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        let grouped = Dictionary(grouping: records) { record in
            formatter.string(from: record.createdAt)
        }

        var data: [(String, Int)] = []
        for offset in stride(from: -5, through: 0, by: 1) {
            if let date = calendar.date(byAdding: .month, value: offset, to: Date()) {
                let key = formatter.string(from: date)
                let count = grouped[key]?.count ?? 0
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "M月"
                let label = displayFormatter.string(from: date)
                data.append((label, count))
            }
        }

        return data
    }

    var maxCount: Int {
        max(monthlyData.map { $0.1 }.max() ?? 1, 1)
    }

    // 本月 vs 上月对比
    var trendInfo: (symbol: String, color: Color, text: String)? {
        guard monthlyData.count >= 2 else { return nil }
        let thisMonth = monthlyData[monthlyData.count - 1].1
        let lastMonth = monthlyData[monthlyData.count - 2].1
        guard lastMonth > 0 else { return nil }
        let diff = thisMonth - lastMonth
        if diff > 0 {
            return ("arrow.up", .green, "+\(diff)")
        } else if diff < 0 {
            return ("arrow.down", .red, "\(diff)")
        } else {
            return ("minus", .secondary, "持平")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.brand)
                Text("月度趋势")
                    .font(.headline)
                Spacer()
                if let trend = trendInfo {
                    HStack(spacing: 3) {
                        Image(systemName: trend.symbol)
                            .font(.caption2)
                        Text(trend.text)
                            .font(.caption)
                    }
                    .foregroundStyle(trend.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(trend.color.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            if records.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(monthlyData.indices, id: \.self) { index in
                        let item = monthlyData[index]
                        VStack(spacing: 6) {
                            Text("\(item.1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.brand)
                                .frame(width: 32, height: max(CGFloat(item.1) / CGFloat(maxCount) * 120, 4))

                            Text(item.0)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }
}
