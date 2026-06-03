//
//  SavedAmountStatsView.swift
//  hold-it-ios
//

import SwiftUI

struct SavedAmountStatsView: View {
    let records: [ResistRecord]
    @Environment(AppState.self) private var appState
    @AppStorage("currencyCode") private var currencyCode: String = "auto"

    private var symbol: String {
        SupportedCurrency(rawValue: currencyCode)?.symbol ?? SupportedCurrency.systemSymbol
    }

    /// 格式化金额显示
    private func formatAmount(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 核心数字大卡
                totalSavedCard

                // 2. 时段对比（今天 / 本周 / 本月）
                periodComparisonCard

                // 3. 月度趋势柱状图
                monthlyTrendCard

                // 4. 分类节省排行
                categoryBreakdownCard

                // 5. 亮点数据
                highlightCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.systemGroupedBackground)
        .navigationTitle("节省统计")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - 1. 累计总金额 + 平均值
    private var totalSavedCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "banknote.fill")
                    .foregroundStyle(.green)
                Text("累计节省")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(symbol)
                    .font(.title3)
                Text(formatAmount(appState.totalSavedAmount(from: records)))
                    .font(.system(size: 40, weight: .bold))
            }
            .foregroundStyle(.green)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            HStack {
                Label {
                    Text("平均每次 \(symbol)\(formatAmount(appState.averageSavedAmount(from: records)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(appState.recordsWithAmountCount(from: records)) 条金额记录")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }

    // MARK: - 2. 时段对比
    private var periodComparisonCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.blue)
                Text("时段对比")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }

            HStack(spacing: 0) {
                periodItem(
                    title: "今天",
                    amount: appState.todaySavedAmount(from: records),
                    color: .green
                )
                Divider().frame(height: 36)
                periodItem(
                    title: "本月",
                    amount: appState.thisMonthSavedAmount(from: records),
                    color: .purple
                )
                Divider().frame(height: 36)
                periodItem(
                    title: "今年",
                    amount: appState.thisYearSavedAmount(from: records),
                    color: .indigo
                )
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }

    private func periodItem(title: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(formatAmount(amount))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 3. 月度节省趋势
    private var monthlyTrendCard: some View {
        let data = appState.monthlySavedAmountTrend(from: records)
        let maxAmount = max(data.map { $0.amount }.max() ?? 1, 1)

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.green)
                Text("月度节省趋势")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }

            if data.allSatisfy({ $0.amount == 0 }) {
                Text("暂无金额数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(data.indices, id: \.self) { index in
                        let item = data[index]
                        VStack(spacing: 6) {
                            if item.amount > 0 {
                                Text("\(formatAmount(item.amount))")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.amount > 0 ? Color.green : Color.systemGray5)
                                .frame(width: 32, height: max(CGFloat(item.amount) / CGFloat(maxAmount) * 100, 4))

                            Text(item.label)
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

    // MARK: - 4. 分类节省排行
    private var categoryBreakdownCard: some View {
        let stats = appState.savedAmountByCategory(from: records)
        let totalAmount = appState.totalSavedAmount(from: records)

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(.orange)
                Text("分类节省排行")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }

            if stats.isEmpty {
                Text("暂无金额数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(stats.indices, id: \.self) { index in
                        let item = stats[index]
                        let percentage = totalAmount > 0 ? item.amount / totalAmount : 0

                        HStack(spacing: 10) {
                            Text(item.emoji)
                                .font(.system(size: 22))

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(LocalizedStringKey(item.name))
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(symbol)\(formatAmount(item.amount))")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.green)
                                }

                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.green.opacity(0.12))
                                        .overlay(
                                            HStack {
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(Color.green.opacity(0.7))
                                                    .frame(width: geo.size.width * CGFloat(percentage))
                                                Spacer()
                                            }
                                        )
                                }
                                .frame(height: 6)

                                Text("\(item.count) 次 · \(Int(percentage * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }

    // MARK: - 5. 亮点数据
    private var highlightCard: some View {
        let bestDay = appState.bestSavedDay(from: records)
        let avg = appState.averageSavedAmount(from: records)

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("亮点数据")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }

            VStack(spacing: 10) {
                if let bestDay {
                    highlightRow(
                        icon: "trophy.fill",
                        color: .yellow,
                        title: "最佳一天",
                        value: "\(symbol)\(formatAmount(bestDay.amount))",
                        subtitle: bestDayDate(bestDay.date)
                    )
                }

                highlightRow(
                    icon: "repeat",
                    color: .blue,
                    title: "平均每次",
                    value: "\(symbol)\(formatAmount(avg))",
                    subtitle: String(localized: "基于 \(appState.recordsWithAmountCount(from: records)) 条记录")
                )

                if appState.thisMonthSavedAmount(from: records) > 0 {
                    let monthAvg = appState.thisMonthSavedAmount(from: records)
                    highlightRow(
                        icon: "flame.fill",
                        color: .orange,
                        title: "本月已省",
                        value: "\(symbol)\(formatAmount(monthAvg))",
                        subtitle: monthProgressText
                    )
                }
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }

    private func highlightRow(icon: String, color: Color, title: String, value: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
        }
    }

    // MARK: - 辅助方法

    private func bestDayDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return String(localized: "今天")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "昨天")
        } else {
            let formatter = DateFormatter()
            formatter.locale = .current
            formatter.setLocalizedDateFormatFromTemplate("Md")
            return formatter.string(from: date)
        }
    }

    private var monthProgressText: String {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        let totalDays = range.count
        let currentDay = calendar.component(.day, from: Date())
        return String(localized: "本月第 \(currentDay)/\(totalDays) 天")
    }
}
