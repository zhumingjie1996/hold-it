//
//  RewardStatsView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

struct RewardStatsView: View {
    @Environment(StoreManager.self) private var storeManager
    @Query private var allRewards: [Reward]
    @Query(sort: \RewardCoinRecord.createdAt, order: .reverse) private var coinRecords: [RewardCoinRecord]
    @Query private var allRecords: [ResistRecord]
    @State private var showVipAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 免费维度
                overviewCard
                statusDistribution
                timeDimension
                efficiencyMetrics
                contributorsTop
                closestToUnlock

                // 会员维度
                if storeManager.isVip {
                    vipSection
                } else {
                    vipLockSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("奖励统计")
        .navigationBarTitleDisplayMode(.inline)
        .alert(String(localized: "解锁高级功能"), isPresented: $showVipAlert) {
            Button(vipPurchaseTitle) {
                Task { _ = await storeManager.purchase() }
            }
            Button(String(localized: "暂不需要"), role: .cancel) { }
        } message: {
            Text("该功能为会员专属，解锁后可永久使用分类分析、热力图、月度趋势等高级统计功能")
        }
    }

    // MARK: - 1. 总览大卡
    private var overviewCard: some View {
        HStack(spacing: 12) {
            VStack(spacing: 6) {
                Text("\(totalCoins)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                Text("累计忍币")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 1, height: 50)

            VStack(spacing: 6) {
                Text(String(format: "%.0f%%", completionRate * 100))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                Text("完成率")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.brand, Color.brandDark],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
    }

    // MARK: - 2. 状态分布
    private var statusDistribution: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(String(localized: "状态分布"), icon: "chart.pie.fill")
            HStack(spacing: 10) {
                RewardStatBox(title: String(localized: "进行中"), value: "\(inProgressCount)", icon: "clock.fill", color: .blue)
                RewardStatBox(title: String(localized: "已解锁"), value: "\(unlockedCount)", icon: "lock.open.fill", color: .orange)
                RewardStatBox(title: String(localized: "已兑现"), value: "\(redeemedCount)", icon: "checkmark.seal.fill", color: .green)
                RewardStatBox(title: String(localized: "总奖励数"), value: "\(allRewards.count)", icon: "gift.fill", color: .brand)
            }
        }
    }

    // MARK: - 3. 时间维度
    private var timeDimension: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(String(localized: "忍币时段"), icon: "clock.badge.fill")
            HStack(spacing: 10) {
                RewardStatBox(title: String(localized: "今日"), value: "\(todayCoins)", icon: "sun.max.fill", color: .yellow)
                RewardStatBox(title: String(localized: "本周"), value: "\(thisWeekCoins)", icon: "calendar", color: .indigo)
                RewardStatBox(title: String(localized: "本月"), value: "\(thisMonthCoins)", icon: "calendar.badge.clock", color: .purple)
            }
        }
    }

    // MARK: - 4. 效率指标
    private var efficiencyMetrics: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(String(localized: "效率指标"), icon: "speedometer")
            HStack(spacing: 10) {
                metricCard(
                    title: String(localized: "日均忍币"),
                    value: avgDailyCoinsText,
                    icon: "chart.bar.fill",
                    color: .pink
                )
                metricCard(
                    title: String(localized: "平均兑现用时"),
                    value: avgRedeemDays.map { "\($0)" } ?? "—",
                    suffix: avgRedeemDays != nil ? String(localized: "天") : nil,
                    icon: "stopwatch.fill",
                    color: .teal
                )
            }
        }
    }

    private func metricCard(
        title: String,
        value: String,
        suffix: String? = nil,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(color)
                if let suffix {
                    Text(suffix)
                        .font(.caption)
                        .foregroundStyle(color.opacity(0.7))
                }
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - 5. 贡献来源 TOP 5
    private var contributorsTop: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(String(localized: "贡献来源 TOP 5"), icon: "trophy.fill")

            if topContributors.isEmpty {
                emptyHint(String(localized: "还没有贡献记录"))
            } else {
                let maxCoins = topContributors.first?.coins ?? 1
                VStack(spacing: 10) {
                    ForEach(Array(topContributors.enumerated()), id: \.offset) { idx, item in
                        contributorRow(rank: idx + 1, item: item, max: maxCoins)
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }

    private func contributorRow(rank: Int, item: ContributorItem, max: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.caption.weight(.bold))
                .frame(width: 18)
                .foregroundStyle(rank <= 3 ? Color.brand : .secondary)
            Text(item.emoji)
            Text(item.name)
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 4)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.brand.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.brand)
                        .frame(width: max > 0 ? geo.size.width * CGFloat(item.coins) / CGFloat(max) : 0, height: 6)
                }
            }
            .frame(width: 70, height: 6)
            Text("\(item.coins)")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.brand)
                .frame(width: 32, alignment: .trailing)
        }
    }

    // MARK: - 6. 即将解锁 TOP 3
    private var closestToUnlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(String(localized: "即将解锁"), icon: "flag.checkered")

            let list = closestRewards
            if list.isEmpty {
                emptyHint(String(localized: "没有进行中的奖励"))
            } else {
                VStack(spacing: 8) {
                    ForEach(list) { reward in
                        NavigationLink(destination: RewardDetailView(reward: reward)) {
                            closestRow(reward: reward)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }

    private func closestRow(reward: Reward) -> some View {
        HStack(spacing: 12) {
            Group {
                if let data = reward.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text("🎁")
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(Color.brand.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(String(format: String(localized: "还差 %d 忍币"), reward.targetCoins - reward.currentCoins))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(reward.progress * 100))%")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brand)
        }
    }

    // MARK: - 会员区域
    private var vipSection: some View {
        VStack(spacing: 16) {
            monthlyTrendCard
            weekdayCard
            timeOfDayCard
            bestRecordsCard
        }
    }

    // MARK: - 7. 月度忍币趋势（会员）
    private var monthlyTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(String(localized: "月度忍币趋势"), icon: "chart.line.uptrend.xyaxis", trailing: String(localized: "近 6 个月"))

            if monthlySeries.allSatisfy({ $0.coins == 0 }) {
                emptyHint(String(localized: "暂无数据"))
            } else {
                let maxC = max(monthlySeries.map { $0.coins }.max() ?? 1, 1)
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(monthlySeries) { item in
                        VStack(spacing: 6) {
                            Text("\(item.coins)")
                                .font(.system(size: 11, weight: .medium).monospacedDigit())
                                .foregroundStyle(item.coins == maxC && item.coins > 0 ? Color.brand : .secondary)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(item.coins == maxC && item.coins > 0 ? Color.brand : Color.brand.opacity(0.25))
                                .frame(height: max(CGFloat(item.coins) / CGFloat(maxC) * 100, 4))
                            Text(item.label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - 8. 周几获得分布（会员）
    private var weekdayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(String(localized: "周几分布"), icon: "calendar.badge.clock")

            let counts = weekdayCoinCounts
            if counts.allSatisfy({ $0 == 0 }) {
                emptyHint(String(localized: "暂无数据"))
            } else {
                let maxC = max(counts.max() ?? 1, 1)
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<7, id: \.self) { idx in
                        let c = counts[idx]
                        let isMax = c == maxC && c > 0
                        VStack(spacing: 6) {
                            Text("\(c)")
                                .font(.system(size: 11, weight: .medium).monospacedDigit())
                                .foregroundStyle(isMax ? Color.brand : .secondary)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isMax ? Color.brand : Color.brand.opacity(0.25))
                                .frame(width: 28, height: max(CGFloat(c) / CGFloat(maxC) * 100, 4))
                            Text(weekdayNames[idx])
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - 9. 时段获得分布（会员）
    private var timeOfDayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(String(localized: "时段分布"), icon: "clock.badge.fill")

            let slots = timeSlots
            let total = slots.reduce(0) { $0 + $1.coins }
            if total == 0 {
                emptyHint(String(localized: "暂无数据"))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(slots) { slot in
                        timeSlotCircle(slot: slot, total: total)
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }

    private func timeSlotCircle(slot: TimeSlot, total: Int) -> some View {
        let pct = total > 0 ? Double(slot.coins) / Double(total) : 0
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(slot.color.opacity(0.15), lineWidth: 5)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(slot.color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Image(systemName: slot.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(slot.color)
            }
            Text(slot.shortLabel)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            Text("\(slot.coins)")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
        }
    }

    // MARK: - 10. 最佳记录（会员）
    private var bestRecordsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(String(localized: "最佳记录"), icon: "rosette")
            VStack(spacing: 10) {
                bestRow(icon: "flame.fill", iconColor: .orange, title: String(localized: "单日最高"),
                        value: "\(bestSingleDayCoins)", suffix: bestSingleDayCoins > 0 ? String(localized: "忍币") : nil)
                bestRow(icon: "bolt.fill", iconColor: .yellow, title: String(localized: "最快达成"),
                        value: fastestRedeemDays.map { "\($0)" } ?? "—",
                        suffix: fastestRedeemDays != nil ? String(localized: "天") : nil)
                bestRow(icon: "target", iconColor: .pink, title: String(localized: "平均目标"),
                        value: avgTargetCoins > 0 ? "\(avgTargetCoins)" : "—",
                        suffix: avgTargetCoins > 0 ? String(localized: "忍币") : nil)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private func bestRow(icon: String, iconColor: Color, title: String, value: String, suffix: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(iconColor)
                .frame(width: 22)
            Text(title)
                .font(.subheadline)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.brand)
                if let suffix {
                    Text(suffix)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 非会员锁
    private var vipLockSection: some View {
        VStack(spacing: 16) {
            // 模糊预览
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Color.brand)
                    Text("月度忍币趋势")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach([0.3, 0.5, 0.4, 0.7, 0.6, 0.9], id: \.self) { pct in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.brand)
                            .frame(width: 28, height: max(CGFloat(pct) * 80, 4))
                    }
                }
                .frame(height: 90, alignment: .bottom)
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground).opacity(0.55))
            )
            .blur(radius: 3)
            .allowsHitTesting(false)

            // 高亮
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    lockHighlight(icon: "chart.line.uptrend.xyaxis", title: String(localized: "月度忍币趋势"), color: .blue)
                    lockHighlight(icon: "calendar.badge.clock", title: String(localized: "周几分布"), color: .pink)
                }
                HStack(spacing: 10) {
                    lockHighlight(icon: "clock.badge.fill", title: String(localized: "时段分布"), color: .purple)
                    lockHighlight(icon: "rosette", title: String(localized: "最佳记录"), color: .orange)
                }
            }

            // CTA
            Button {
                Task {
                    _ = await storeManager.purchase()
                    if storeManager.purchaseState == .failed {
                        showVipAlert = true
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text("解锁终身会员")
                            .font(.headline)
                            .foregroundStyle(.white)
                        if !storeManager.displayPrice.isEmpty {
                            Text(storeManager.displayPrice)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                    Text("解锁全部奖励维度统计")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
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

    private func lockHighlight(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Image(systemName: "lock.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    private var vipPurchaseTitle: String {
        storeManager.displayPrice.isEmpty
            ? String(localized: "解锁终身会员")
            : String(localized: "解锁终身会员") + "(" + storeManager.displayPrice + ")"
    }

    // MARK: - Helpers
    private func sectionHeader(_ title: String, icon: String, trailing: String? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.brand)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
    }

    // MARK: - 计算属性
    private var totalCoins: Int { coinRecords.reduce(0) { $0 + $1.coins } }
    private var inProgressCount: Int { allRewards.filter { $0.status == .inProgress }.count }
    private var unlockedCount: Int { allRewards.filter { $0.status == .unlocked }.count }
    private var redeemedCount: Int { allRewards.filter { $0.status == .redeemed }.count }

    private var completionRate: Double {
        guard !allRewards.isEmpty else { return 0 }
        return Double(redeemedCount) / Double(allRewards.count)
    }

    private var todayCoins: Int {
        let cal = Calendar.current
        return coinRecords.filter { cal.isDateInToday($0.createdAt) }.reduce(0) { $0 + $1.coins }
    }

    private var thisWeekCoins: Int {
        let cal = Calendar.current
        guard let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return coinRecords.filter { $0.createdAt >= start }.reduce(0) { $0 + $1.coins }
    }

    private var thisMonthCoins: Int {
        let cal = Calendar.current
        guard let start = cal.dateInterval(of: .month, for: Date())?.start else { return 0 }
        return coinRecords.filter { $0.createdAt >= start }.reduce(0) { $0 + $1.coins }
    }

    private var avgDailyCoinsText: String {
        guard !coinRecords.isEmpty,
              let firstDate = coinRecords.last?.createdAt else { return "0" }
        let dayDiff = (Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day ?? 0) + 1
        let days = Swift.max(1, dayDiff)
        let avg = Double(totalCoins) / Double(days)
        return String(format: "%.1f", avg)
    }

    private var avgRedeemDays: Int? {
        let redeemed = allRewards.filter { $0.status == .redeemed && $0.redeemedAt != nil }
        guard !redeemed.isEmpty else { return nil }
        let total = redeemed.reduce(0.0) { sum, r in
            guard let redeemedAt = r.redeemedAt else { return sum }
            return sum + redeemedAt.timeIntervalSince(r.createdAt) / 86400
        }
        return Int((total / Double(redeemed.count)).rounded())
    }

    // MARK: - 会员维度数据

    /// 月度趋势：近 6 个月（含本月），按月聚合忍币数
    private struct MonthSeriesItem: Identifiable {
        let id: String
        let label: String
        let coins: Int
    }
    private var monthlySeries: [MonthSeriesItem] {
        let cal = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "M"
        var buckets: [(start: Date, label: String, coins: Int)] = []
        for offset in stride(from: 5, through: 0, by: -1) {
            guard let monthDate = cal.date(byAdding: .month, value: -offset, to: now),
                  let interval = cal.dateInterval(of: .month, for: monthDate) else { continue }
            buckets.append((start: interval.start, label: formatter.string(from: monthDate), coins: 0))
        }
        for cr in coinRecords {
            for i in buckets.indices {
                let start = buckets[i].start
                let end = cal.date(byAdding: .month, value: 1, to: start) ?? start
                if cr.createdAt >= start && cr.createdAt < end {
                    buckets[i].coins += cr.coins
                    break
                }
            }
        }
        return buckets.map { MonthSeriesItem(id: $0.label, label: $0.label, coins: $0.coins) }
    }

    /// 周几获得忍币：周一=0 ... 周日=6
    private var weekdayCoinCounts: [Int] {
        var counts = Array(repeating: 0, count: 7)
        let cal = Calendar.current
        for cr in coinRecords {
            let wd = cal.component(.weekday, from: cr.createdAt)
            let index = (wd + 5) % 7
            counts[index] += cr.coins
        }
        return counts
    }

    private let weekdayNames: [String] = [
        String(localized: "周一"),
        String(localized: "周二"),
        String(localized: "周三"),
        String(localized: "周四"),
        String(localized: "周五"),
        String(localized: "周六"),
        String(localized: "周日")
    ]

    /// 时段获得忍币
    private struct TimeSlot: Identifiable {
        let id = UUID()
        let label: String
        let shortLabel: String
        let icon: String
        let range: Range<Int>
        let color: Color
        var coins: Int
    }
    private var timeSlots: [TimeSlot] {
        var s: [TimeSlot] = [
            TimeSlot(label: String(localized: "凌晨"), shortLabel: "0-6", icon: "moon.stars.fill", range: 0..<6, color: .indigo, coins: 0),
            TimeSlot(label: String(localized: "上午"), shortLabel: "6-9", icon: "sunrise.fill", range: 6..<9, color: .orange, coins: 0),
            TimeSlot(label: String(localized: "午前"), shortLabel: "9-12", icon: "sun.max.fill", range: 9..<12, color: .yellow, coins: 0),
            TimeSlot(label: String(localized: "下午"), shortLabel: "12-15", icon: "sun.and.horizon.fill", range: 12..<15, color: .orange, coins: 0),
            TimeSlot(label: String(localized: "傍晚"), shortLabel: "15-18", icon: "sunset.fill", range: 15..<18, color: .pink, coins: 0),
            TimeSlot(label: String(localized: "晚上"), shortLabel: "18-24", icon: "moon.fill", range: 18..<24, color: .purple, coins: 0)
        ]
        let cal = Calendar.current
        for cr in coinRecords {
            let hour = cal.component(.hour, from: cr.createdAt)
            for i in s.indices where s[i].range.contains(hour) {
                s[i].coins += cr.coins
                break
            }
        }
        return s
    }

    /// 单日最高忍币
    private var bestSingleDayCoins: Int {
        let cal = Calendar.current
        var bucket: [Date: Int] = [:]
        for cr in coinRecords {
            let day = cal.startOfDay(for: cr.createdAt)
            bucket[day, default: 0] += cr.coins
        }
        return bucket.values.max() ?? 0
    }

    /// 最快达成（最小兑现用时，单位天）
    private var fastestRedeemDays: Int? {
        let redeemed = allRewards.filter { $0.status == .redeemed && $0.redeemedAt != nil }
        guard !redeemed.isEmpty else { return nil }
        let minDays = redeemed.compactMap { r -> Double? in
            guard let redeemedAt = r.redeemedAt else { return nil }
            return redeemedAt.timeIntervalSince(r.createdAt) / 86400
        }.min() ?? 0
        return Swift.max(0, Int(minDays.rounded()))
    }

    /// 平均奖励目标忍币
    private var avgTargetCoins: Int {
        guard !allRewards.isEmpty else { return 0 }
        let total = allRewards.reduce(0) { $0 + $1.targetCoins }
        return Int((Double(total) / Double(allRewards.count)).rounded())
    }

    // 贡献来源排行结构
    private struct ContributorItem: Identifiable {
        let id: String
        let emoji: String
        let name: String
        let coins: Int
    }

    private var topContributors: [ContributorItem] {
        let recordsByID = Dictionary(uniqueKeysWithValues: allRecords.map { ($0.id, $0) })
        var bucket: [String: (emoji: String, name: String, coins: Int)] = [:]
        for cr in coinRecords {
            guard let r = recordsByID[cr.restraintRecordID] else { continue }
            let cid = r.effectiveCategoryID
            let name = localizedCategoryName(categoryID: cid, fallback: r.category)
            let prev = bucket[cid] ?? (emoji: r.categoryEmoji, name: name, coins: 0)
            bucket[cid] = (emoji: prev.emoji, name: prev.name, coins: prev.coins + cr.coins)
        }
        return bucket
            .map { ContributorItem(id: $0.key, emoji: $0.value.emoji, name: $0.value.name, coins: $0.value.coins) }
            .sorted { $0.coins > $1.coins }
            .prefix(5)
            .map { $0 }
    }

    private var closestRewards: [Reward] {
        allRewards
            .filter { $0.status == .inProgress && $0.targetCoins > $0.currentCoins }
            .sorted { ($0.targetCoins - $0.currentCoins) < ($1.targetCoins - $1.currentCoins) }
            .prefix(3)
            .map { $0 }
    }
}
