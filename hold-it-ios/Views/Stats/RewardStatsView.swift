//
//  RewardStatsView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

struct RewardStatsView: View {
    @Query private var allRewards: [Reward]
    @Query(sort: \RewardCoinRecord.createdAt, order: .reverse) private var coinRecords: [RewardCoinRecord]
    @Query private var allRecords: [ResistRecord]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                overviewCard
                statusDistribution
                timeDimension
                efficiencyMetrics
                contributorsTop
                closestToUnlock
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("奖励统计")
        .navigationBarTitleDisplayMode(.inline)
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
            sectionHeader("状态分布", icon: "chart.pie.fill")
            HStack(spacing: 10) {
                RewardStatBox(title: "进行中", value: "\(inProgressCount)", icon: "clock.fill", color: .blue)
                RewardStatBox(title: "已解锁", value: "\(unlockedCount)", icon: "lock.open.fill", color: .orange)
                RewardStatBox(title: "已兑现", value: "\(redeemedCount)", icon: "checkmark.seal.fill", color: .green)
                RewardStatBox(title: "总奖励数", value: "\(allRewards.count)", icon: "gift.fill", color: .brand)
            }
        }
    }

    // MARK: - 3. 时间维度
    private var timeDimension: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("忍币时段", icon: "clock.badge.fill")
            HStack(spacing: 10) {
                RewardStatBox(title: "今日", value: "\(todayCoins)", icon: "sun.max.fill", color: .yellow)
                RewardStatBox(title: "本周", value: "\(thisWeekCoins)", icon: "calendar", color: .indigo)
                RewardStatBox(title: "本月", value: "\(thisMonthCoins)", icon: "calendar.badge.clock", color: .purple)
            }
        }
    }

    // MARK: - 4. 效率指标
    private var efficiencyMetrics: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("效率指标", icon: "speedometer")
            HStack(spacing: 10) {
                metricCard(
                    title: "日均忍币",
                    value: avgDailyCoinsText,
                    icon: "chart.bar.fill",
                    color: .pink
                )
                metricCard(
                    title: "平均兑现用时",
                    value: avgRedeemDays.map { "\($0)" } ?? "—",
                    suffix: avgRedeemDays != nil ? String(localized: "天") : nil,
                    icon: "stopwatch.fill",
                    color: .teal
                )
            }
        }
    }

    private func metricCard(
        title: LocalizedStringKey,
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
            sectionHeader("贡献来源 TOP 5", icon: "trophy.fill")

            if topContributors.isEmpty {
                Text("还没有贡献记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
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
            sectionHeader("即将解锁", icon: "flag.checkered")

            let list = closestRewards
            if list.isEmpty {
                Text("没有进行中的奖励")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
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

    // MARK: - Helpers
    private func sectionHeader(_ title: LocalizedStringKey, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.brand)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
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
