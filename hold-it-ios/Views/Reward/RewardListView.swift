//
//  RewardListView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

struct RewardListView: View {
    @Query(sort: \Reward.createdAt, order: .reverse) private var rewards: [Reward]
    @State private var showCreateReward = false

    var body: some View {
        NavigationStack {
            List {
                let inProgress = rewards.filter { $0.status == .inProgress }
                let unlocked = rewards.filter { $0.status == .unlocked }
                let redeemed = rewards.filter { $0.status == .redeemed }

                if !inProgress.isEmpty {
                    Section(String(localized: "进行中")) {
                        ForEach(inProgress.sorted(by: { $0.progress > $1.progress })) { reward in
                            NavigationLink(destination: RewardDetailView(reward: reward)) {
                                RewardRow(reward: reward)
                            }
                        }
                    }
                }

                if !unlocked.isEmpty {
                    Section(String(localized: "已解锁")) {
                        ForEach(unlocked) { reward in
                            NavigationLink(destination: RewardDetailView(reward: reward)) {
                                RewardRow(reward: reward)
                            }
                        }
                    }
                }

                if !redeemed.isEmpty {
                    Section(String(localized: "已兑现")) {
                        ForEach(redeemed) { reward in
                            NavigationLink(destination: RewardDetailView(reward: reward)) {
                                RewardRow(reward: reward)
                            }
                        }
                    }
                }

                if rewards.isEmpty {
                    ContentUnavailableView(
                        String(localized: "暂无奖励"),
                        systemImage: "gift",
                        description: Text("点击右上角 + 创建你的第一个奖励")
                    )
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle(String(localized: "奖励管理"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateReward = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateReward) {
                CreateRewardSheet()
            }
        }
    }
}

// MARK: - 奖励行
struct RewardRow: View {
    let reward: Reward

    var body: some View {
        HStack(spacing: 12) {
            // 图片/占位
            Group {
                if let data = reward.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text("🎁")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.brand.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text("\(reward.currentCoins) / \(reward.targetCoins)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 进度条
            VStack(spacing: 2) {
                ProgressView(value: reward.progress)
                    .tint(reward.status == .redeemed ? .secondary : Color.brand)
                    .frame(width: 60)
                Text("\(Int(reward.progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
