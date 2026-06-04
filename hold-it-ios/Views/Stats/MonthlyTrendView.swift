//
//  MonthlyTrendView.swift
//  hold-it-ios
//

import SwiftUI

struct MonthlyTrendView: View {
    let records: [ResistRecord]
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let years = Set(records.map { Calendar.current.component(.year, from: $0.createdAt) })
        var result = Array(years)
        if !result.contains(currentYear) { result.append(currentYear) }
        return result.sorted(by: >)
    }

    var monthlyData: [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        let grouped = Dictionary(grouping: records) { record in
            formatter.string(from: record.createdAt)
        }

        var data: [(String, Int)] = []
        for month in 1...12 {
            let key = String(format: "%04d-%02d", selectedYear, month)
            let count = grouped[key]?.count ?? 0
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale.current
            displayFormatter.setLocalizedDateFormatFromTemplate("MMM")
            let label = displayFormatter.string(from: calendar.date(from: DateComponents(year: selectedYear, month: month))!)
            data.append((label, count))
        }

        return data
    }

    var maxCount: Int {
        max(monthlyData.map { $0.1 }.max() ?? 1, 1)
    }

    // 本月 vs 上月对比
    var trendInfo: (symbol: String, color: Color, text: String)? {
        guard monthlyData.count >= 2 else { return nil }
        let currentMonth = Calendar.current.component(.month, from: Date())
        let thisMonth = monthlyData[currentMonth - 1].1
        let lastMonth = currentMonth > 1 ? monthlyData[currentMonth - 2].1 : 0
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

            // 年份切换
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableYears, id: \.self) { year in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedYear = year
                            }
                        } label: {
                            Text("\(year)")
                                .font(.subheadline.weight(selectedYear == year ? .semibold : .regular))
                                .foregroundStyle(selectedYear == year ? .white : .secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(selectedYear == year ? Color.brand : Color.secondarySystemGroupedBackground)
                                .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if records.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(monthlyData.indices, id: \.self) { index in
                        let item = monthlyData[index]
                        VStack(spacing: 4) {
                            if item.1 > 0 {
                                Text("\(item.1)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }

                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.1 > 0 ? Color.brand : Color.systemGray5)
                                .frame(height: max(CGFloat(item.1) / CGFloat(maxCount) * 100, 4))

                            Text(item.0)
                                .font(.system(size: 9))
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
