//
//  SavedAmountStatsView.swift
//  hold-it-ios
//

import SwiftUI

struct SavedAmountStatsView: View {
    let records: [ResistRecord]
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var storeManager
    @AppStorage("currencyCode") private var currencyCode: String = "auto"
    @State private var showVipAlert = false

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
                // 1. 核心数字大卡（所有用户可见）
                totalSavedCard

                if storeManager.isVip {
                    // 会员：完整内容
                    periodComparisonCard
                    monthlyTrendCard
                    categoryBreakdownCard
                    highlightCard
                } else {
                    // 非会员：模糊预览 + 遮罩
                    vipLockView
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.systemGroupedBackground)
        .navigationTitle("节省统计")
        .navigationBarTitleDisplayMode(.large)
        .alert("解锁高级功能", isPresented: $showVipAlert) {
            Button(savedVipTitle) {
                Task {
                    _ = await storeManager.purchase()
                }
            }
            Button("暂不需要", role: .cancel) { }
        } message: {
            Text("该功能为会员专属，解锁后可永久使用时段对比、月度趋势、分类排行等高级节省统计功能")
        }
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

                NavigationLink {
                    SavedRecordsListView()
                } label: {
                    HStack(spacing: 4) {
                        Text("全部记录")
                            .font(.caption2)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(.secondary)
                }
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

    // MARK: - 非会员遮罩
    private var vipLockView: some View {
        VStack(spacing: 20) {
            // 时段对比模糊预览
            periodComparisonCard
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemBackground.opacity(0.6))
                )
                .blur(radius: 3)
                .allowsHitTesting(false)

            // 月度趋势模糊预览
            monthlyTrendCard
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemBackground.opacity(0.6))
                )
                .blur(radius: 3)
                .allowsHitTesting(false)

            // 分类排行模糊预览
            categoryBreakdownCard
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemBackground.opacity(0.6))
                )
                .blur(radius: 3)
                .allowsHitTesting(false)

            // 功能亮点
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    savedHighlightItem(icon: "calendar.badge.clock", title: "时段对比", color: .blue)
                    savedHighlightItem(icon: "chart.line.uptrend.xyaxis", title: "月度趋势", color: .green)
                }
                HStack(spacing: 12) {
                    savedHighlightItem(icon: "tray.full.fill", title: "分类排行", color: .orange)
                    savedHighlightItem(icon: "sparkles", title: "亮点数据", color: .yellow)
                }
            }

            // 开通会员按钮
            Button {
                showVipAlert = true
            } label: {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text("解锁全部节省统计")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Text("一次购买，终身使用")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.brand, Color.brandDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.brand.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    private func savedHighlightItem(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    private var savedVipTitle: String {
        storeManager.displayPrice.isEmpty
            ? String(localized: "解锁终身会员")
            : String(localized: "解锁终身会员") + "(" + storeManager.displayPrice + ")"
    }
}
