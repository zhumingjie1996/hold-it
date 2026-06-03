//
//  TimeOfDayView.swift
//  hold-it-ios
//

import SwiftUI

struct TimeOfDayView: View {
    let records: [ResistRecord]

    struct TimeSlot: Identifiable {
        let id = UUID()
        let label: String
        let icon: String
        let range: Range<Int> // hour range
        let color: Color
        var count: Int = 0
    }

    var slots: [TimeSlot] {
        var s = [
            TimeSlot(label: "深夜", icon: "moon.stars.fill", range: 0..<6,   color: .indigo),
            TimeSlot(label: "早晨", icon: "sunrise.fill",    range: 6..<12,  color: .orange),
            TimeSlot(label: "下午", icon: "sun.max.fill",    range: 12..<18, color: .yellow),
            TimeSlot(label: "晚上", icon: "moon.fill",       range: 18..<24, color: .purple),
        ]
        let calendar = Calendar.current
        for record in records {
            let hour = calendar.component(.hour, from: record.createdAt)
            for i in s.indices {
                if s[i].range.contains(hour) {
                    s[i].count += 1
                    break
                }
            }
        }
        return s
    }

    var total: Int { slots.reduce(0) { $0 + $1.count } }

    var peakSlot: TimeSlot? {
        slots.max(by: { $0.count < $1.count }).flatMap { $0.count > 0 ? $0 : nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.badge.fill")
                    .foregroundStyle(Color.brand)
                Text("时段分析")
                    .font(.headline)
                Spacer()
                if let peak = peakSlot {
                    Label(peak.label, systemImage: peak.icon)
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
                VStack(spacing: 10) {
                    ForEach(slots) { slot in
                        let pct = total > 0 ? Double(slot.count) / Double(total) : 0
                        HStack(spacing: 12) {
                            Image(systemName: slot.icon)
                                .font(.subheadline)
                                .foregroundStyle(slot.color)
                                .frame(width: 22)

                            Text(slot.label)
                                .font(.subheadline)
                                .frame(width: 32, alignment: .leading)

                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(slot.color.opacity(0.15))
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(slot.color)
                                            .frame(width: max(geo.size.width * pct, pct > 0 ? 4 : 0))
                                    }
                            }
                            .frame(height: 8)

                            Text("\(slot.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)

                            Text(pct > 0 ? "\(Int(pct * 100))%" : "")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }
}
