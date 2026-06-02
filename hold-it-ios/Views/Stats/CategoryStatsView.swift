//
//  CategoryStatsView.swift
//  hold-it-ios
//

import SwiftUI

struct CategoryStatsView: View {
    let records: [ResistRecord]

    var categoryStats: [(String, String, Int, Double)] {
        let grouped = Dictionary(grouping: records) { $0.category }
        let total = records.count
        return grouped.map { category, items in
            let emoji = items.first?.categoryEmoji ?? ""
            let count = items.count
            let percentage = total > 0 ? Double(count) / Double(total) : 0
            return (emoji, category, count, percentage)
        }.sorted { $0.2 > $1.2 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(Color.brand)
                Text("分类统计")
                    .font(.headline)
                Spacer()
            }

            if categoryStats.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(categoryStats.indices, id: \.self) { index in
                        let stat = categoryStats[index]
                        CategoryBar(
                            emoji: stat.0,
                            name: stat.1,
                            count: stat.2,
                            percentage: stat.3
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }
}

struct CategoryBar: View {
    let emoji: String
    let name: String
    let count: Int
    let percentage: Double

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(emoji) \(name)")
                    .font(.subheadline)
                Spacer()
                Text("\(count) 次")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brand.opacity(0.15))
                    .overlay(
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.brand)
                                .frame(width: geo.size.width * percentage)
                            Spacer()
                        }
                    )
            }
            .frame(height: 8)
        }
    }
}
