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
        let shortLabel: String  // 短标签用于圆环内显示（纯数字/符号，无国际化问题）
        let icon: String
        let range: Range<Int>
        let color: Color
        var count: Int = 0
    }

    var slots: [TimeSlot] {
        var s = [
            TimeSlot(label: String(localized: "凌晨"), shortLabel: "0-6",   icon: "moon.stars.fill", range: 0..<6,   color: .indigo),
            TimeSlot(label: String(localized: "上午"), shortLabel: "6-9",   icon: "sunrise.fill",    range: 6..<9,   color: .orange),
            TimeSlot(label: String(localized: "午前"), shortLabel: "9-12",  icon: "sun.max.fill",    range: 9..<12,  color: .yellow),
            TimeSlot(label: String(localized: "下午"), shortLabel: "12-15", icon: "sun.and.horizon.fill", range: 12..<15, color: .orange),
            TimeSlot(label: String(localized: "傍晚"), shortLabel: "15-18", icon: "sunset.fill",     range: 15..<18, color: .pink),
            TimeSlot(label: String(localized: "晚上"), shortLabel: "18-24", icon: "moon.fill",       range: 18..<24, color: .purple),
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

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

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
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(slots) { slot in
                        slotCircle(slot: slot)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }

    // MARK: - 圆环 Slot
    @ViewBuilder
    private func slotCircle(slot: TimeSlot) -> some View {
        let pct = total > 0 ? Double(slot.count) / Double(total) : 0
        VStack(spacing: 6) {
            ZStack {
                // 底圆
                Circle()
                    .stroke(slot.color.opacity(0.15), lineWidth: 5)
                    .frame(width: 52, height: 52)

                // 进度圆
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(slot.color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))

                // 中心图标
                Image(systemName: slot.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(slot.color)
            }

            // 时间段短标签
            Text(slot.shortLabel)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)

            // 次数
            Text("\(slot.count)")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
}
