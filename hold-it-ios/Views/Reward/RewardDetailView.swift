//
//  RewardDetailView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData
import PhotosUI

struct RewardDetailView: View {
    @Bindable var reward: Reward
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RewardCoinRecord.createdAt, order: .reverse) private var coinRecords: [RewardCoinRecord]
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var allRecords: [ResistRecord]
    @State private var showRedeemAlert = false
    @State private var showDeleteAlert = false

    private var filteredCoinRecords: [RewardCoinRecord] {
        coinRecords.filter { $0.rewardID == reward.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 图片/占位
                rewardImageHeader

                // 基础信息
                VStack(spacing: 8) {
                    Text(reward.title)
                        .font(.title2.weight(.bold))
                    if !reward.rewardDescription.isEmpty {
                        Text(reward.rewardDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // 进度卡片
                progressCard

                // 关联克制项
                linkedCategoriesSection

                // 最近贡献记录
                recentCoinsSection

                // 操作按钮
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("删除奖励", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(String(localized: "确认已兑现奖励？"), isPresented: $showRedeemAlert) {
            Button(String(localized: "兑现"), role: .destructive) {
                redeemReward()
            }
            Button(String(localized: "取消"), role: .cancel) { }
        }
        .alert(String(localized: "删除奖励"), isPresented: $showDeleteAlert) {
            Button(String(localized: "删除"), role: .destructive) {
                deleteReward()
            }
            Button(String(localized: "取消"), role: .cancel) { }
        } message: {
            Text(String(localized: "删除后奖励进度将丢失，确定删除吗？"))
        }
    }

    // MARK: - 图片头部
    private var rewardImageHeader: some View {
        Group {
            if let data = reward.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.brand.opacity(0.12))
                        .frame(height: 160)
                    Text("🎁")
                        .font(.system(size: 64))
                }
            }
        }
    }

    // MARK: - 进度卡片
    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("当前进度")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(reward.currentCoins) / \(reward.targetCoins)")
                    .font(.headline)
                    .foregroundStyle(Color.brand)
            }

            ProgressView(value: reward.progress)
                .tint(Color.brand)

            if reward.status == .inProgress {
                let remaining = reward.targetCoins - reward.currentCoins
                Text(String(format: String(localized: "距离解锁还差 %d 忍币"), remaining))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if reward.status == .unlocked {
                Text("🎉 奖励已解锁！现在可以奖励自己了")
                    .font(.caption)
                    .foregroundStyle(Color.brand)
            } else {
                if let date = reward.redeemedAt {
                    Text(String(format: String(localized: "已兑现 · %@"), date.formatted(date: .abbreviated, time: .omitted)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 关联克制项
    private var linkedCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("已关联克制项")
                .font(.subheadline.weight(.medium))

            if reward.categoryIDs.isEmpty {
                Text("未关联任何克制项")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            } else {
                ForEach(reward.categoryIDs, id: \.self) { catID in
                    let name = localizedCategoryName(categoryID: catID, fallback: catID)
                    HStack(spacing: 8) {
                        Text(categoryEmoji(for: catID))
                        Text(name)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.brand)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - 最近贡献记录
    private var recentCoinsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最近贡献记录")
                .font(.subheadline.weight(.medium))

            if filteredCoinRecords.isEmpty {
                Text("还没有贡献记录，记录克制即可自动获得忍币")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            } else {
                ForEach(filteredCoinRecords.prefix(20)) { record in
                    let resistRecord = allRecords.first { $0.id == record.restraintRecordID }
                    HStack {
                        if let r = resistRecord {
                            Text(r.categoryEmoji)
                            Text(localizedCategoryName(categoryID: r.effectiveCategoryID, fallback: r.category))
                                .font(.subheadline)
                        } else {
                            Text("—")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: String(localized: "+%d 忍币"), record.coins))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.brand)
                        Text(record.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - 操作按钮
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if reward.status == .unlocked {
                Button {
                    showRedeemAlert = true
                } label: {
                    HStack {
                        Image(systemName: "gift.fill")
                        Text("兑现奖励")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brand)
                    .cornerRadius(16)
                }
            }

            if reward.status == .redeemed {
                Button {
                    showRedeemAlert = false
                    reward.status = .unlocked
                    reward.redeemedAt = nil
                } label: {
                    Text("撤回兑现")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 操作
    private func redeemReward() {
        reward.status = .redeemed
        reward.redeemedAt = Date()
    }

    private func deleteReward() {
        // 删除关联的忍币记录
        for record in filteredCoinRecords {
            modelContext.delete(record)
        }
        modelContext.delete(reward)
        dismiss()
    }

    private func categoryEmoji(for categoryID: String) -> String {
        let map: [String: String] = [
            "default_milk_tea": "🧋",
            "default_impulse_buy": "💸",
            "default_gaming": "🎮",
            "default_short_video": "📱",
            "default_miss_him": "❤️",
        ]
        return map[categoryID] ?? "📌"
    }
}
