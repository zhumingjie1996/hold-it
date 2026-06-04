//
//  StatsSnapshotView.swift
//  hold-it-ios
//

import SwiftUI

/// 用于 ImageRenderer 渲染导出图片的静态快照视图
struct StatsSnapshotView: View {
    let records: [ResistRecord]
    let appState: AppState
    let currencyCode: String

    private var symbol: String {
        SupportedCurrency(rawValue: currencyCode)?.symbol ?? SupportedCurrency.systemSymbol
    }

    private func fmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(v))"
            : String(format: "%.1f", v)
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            LinearGradient(
                colors: [Color.brand, Color.brandDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 110)
            .overlay {
                HStack(spacing: 14) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "统计报告"))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Text(exportDateString)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(appState.totalCount(from: records))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        Text(String(localized: "累计忍住次数"))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
            }

            // MARK: Body
            VStack(spacing: 16) {
                // 基础数据格子
                basicStatsGrid

                Divider()

                // 节省金额
                if appState.totalSavedAmount(from: records) > 0 {
                    savedAmountRow
                    Divider()
                }

                // 分类统计
                if !records.isEmpty {
                    categorySection
                    Divider()
                }

                // 月度趋势（近6个月）
                monthlySection

                // 底部署名
                HStack {
                    Spacer()
                    Text(String(localized: "Hold it · 忍一下"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
        }
        .frame(width: 375)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 基础数据格子
    private var basicStatsGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                snapshotBox(title: String(localized: "今天"), value: "\(appState.todayCount(from: records))", unit: String(localized: "次"), color: .green)
                snapshotBox(title: String(localized: "本月"), value: "\(appState.thisMonthCount(from: records))", unit: String(localized: "次"), color: .purple)
                snapshotBox(title: String(localized: "今年"), value: "\(appState.thisYearCount(from: records))", unit: String(localized: "次"), color: .indigo)
            }
            HStack(spacing: 8) {
                snapshotBox(title: String(localized: "连续记录"), value: "\(appState.streakDays(from: records))", unit: String(localized: "天"), color: .orange)
                snapshotBox(title: String(localized: "最长连续"), value: "\(appState.bestStreak(from: records))", unit: String(localized: "天"), color: .red)
                snapshotBox(title: String(localized: "累计忍住"), value: "\(appState.totalCount(from: records))", unit: String(localized: "次"), color: Color.brand)
            }
        }
    }

    private func snapshotBox(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - 节省金额
    private var savedAmountRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "累计节省"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(symbol)
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    Text(fmt(appState.totalSavedAmount(from: records)))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                savedPillItem(label: String(localized: "今天"), value: "\(symbol)\(fmt(appState.todaySavedAmount(from: records)))")
                savedPillItem(label: String(localized: "本月"), value: "\(symbol)\(fmt(appState.thisMonthSavedAmount(from: records)))")
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func savedPillItem(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
        }
    }

    // MARK: - 分类统计（Top 5）
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(String(localized: "分类统计"), systemImage: "chart.pie.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brand)

            let stats = categoryStats()
            let topStats = Array(stats.prefix(5))
            VStack(spacing: 8) {
                ForEach(topStats.indices, id: \.self) { i in
                    let s = topStats[i]
                    HStack(spacing: 8) {
                        Text(s.emoji)
                        Text(s.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.brand.opacity(0.15))
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.brand)
                                        .frame(width: geo.size.width * CGFloat(s.pct))
                                }
                        }
                        .frame(width: 80, height: 6)
                        Text("\(s.count)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func categoryStats() -> [(emoji: String, name: String, count: Int, pct: Double)] {
        var merged: [String: (emoji: String, name: String, count: Int)] = [:]
        for r in records {
            let key = r.effectiveCategoryID
            if merged[key] != nil {
                merged[key]?.count += 1
            } else {
                merged[key] = (r.categoryEmoji, localizedCategoryName(categoryID: key, fallback: r.category), 1)
            }
        }
        let total = records.count
        return merged.values
            .sorted { $0.count > $1.count }
            .map { (emoji: $0.emoji, name: $0.name, count: $0.count, pct: total > 0 ? Double($0.count) / Double(total) : 0) }
    }

    // MARK: - 月度趋势（近6个月）
    private var monthlySection: some View {
        let data = appState.monthlySavedAmountTrend(from: records)
        // 只用 count 做柱子高度
        let countData = monthlyCountData()
        let maxCount = max(countData.map { $0.1 }.max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 10) {
            Label(String(localized: "月度趋势"), systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(countData.indices, id: \.self) { i in
                    let item = countData[i]
                    VStack(spacing: 4) {
                        if item.1 > 0 {
                            Text("\(item.1)")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.1 > 0 ? Color.brand : Color.systemGray5)
                            .frame(width: 28, height: max(CGFloat(item.1) / CGFloat(maxCount) * 70, 4))
                        Text(item.0)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
            // 月度节省金额小标注（如有）
            if data.contains(where: { $0.amount > 0 }) {
                HStack(spacing: 0) {
                    ForEach(data.indices, id: \.self) { i in
                        Text(data[i].amount > 0 ? "\(symbol)\(fmt(data[i].amount))" : "")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func monthlyCountData() -> [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let grouped = Dictionary(grouping: records) { formatter.string(from: $0.createdAt) }

        var result: [(String, Int)] = []
        for offset in stride(from: -5, through: 0, by: 1) {
            if let date = calendar.date(byAdding: .month, value: offset, to: Date()) {
                let key = formatter.string(from: date)
                let count = grouped[key]?.count ?? 0
                let df = DateFormatter()
                df.locale = Locale.current
                df.setLocalizedDateFormatFromTemplate("MMM")
                result.append((df.string(from: date), count))
            }
        }
        return result
    }

    // MARK: - 辅助
    private var exportDateString: String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.setLocalizedDateFormatFromTemplate("yMd")
        return df.string(from: Date())
    }
}
