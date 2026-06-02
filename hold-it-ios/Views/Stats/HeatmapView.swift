//
//  HeatmapView.swift
//  hold-it-ios
//

import SwiftUI

struct HeatmapView: View {
    let records: [ResistRecord]

    private let columns = 15
    private let cellSize: CGFloat = 18
    private let cellSpacing: CGFloat = 3

    var heatmapData: [(Date, Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(columns * 7 - 1), to: today)!

        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.createdAt)
        }

        var data: [(Date, Int)] = []
        var currentDate = startDate
        while currentDate <= today {
            let count = grouped[currentDate]?.count ?? 0
            data.append((currentDate, count))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text("热力图")
                    .font(.headline)
                Spacer()
            }

            if records.isEmpty {
                Text("记录越多，热力图越丰富")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: columns),
                    spacing: cellSpacing
                ) {
                    ForEach(heatmapData.indices, id: \.self) { index in
                        let item = heatmapData[index]
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorForCount(item.1))
                            .frame(width: cellSize, height: cellSize)
                    }
                }

                HStack(spacing: 4) {
                    Text("少")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForLevel(level))
                            .frame(width: 12, height: 12)
                    }
                    Text("多")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func colorForCount(_ count: Int) -> Color {
        if count == 0 { return Color(.systemGray5) }
        if count == 1 { return Color.green.opacity(0.3) }
        if count <= 3 { return Color.green.opacity(0.5) }
        if count <= 5 { return Color.green.opacity(0.7) }
        return Color.green
    }

    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return Color(.systemGray5)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        default: return Color.green
        }
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}
