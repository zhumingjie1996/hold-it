//
//  RewardProgressCard.swift
//  hold-it-ios
//

import SwiftUI

/// 首页「进行中的奖励」卡片
struct RewardProgressCard: View {
    let reward: Reward

    var body: some View {
        NavigationLink(destination: RewardDetailView(reward: reward)) {
            VStack(alignment: .leading, spacing: 10) {
                // 标题行
                HStack(spacing: 8) {
                    Group {
                        if let data = reward.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Text("🎁")
                                .font(.title3)
                                .frame(width: 32, height: 32)
                                .background(Color.brand.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    Text(reward.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Spacer()

                    Text("\(reward.currentCoins) / \(reward.targetCoins)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.brand)
                }

                // 进度条
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.brand.opacity(0.15))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.brand)
                            .frame(width: geo.size.width * reward.progress, height: 8)
                    }
                }
                .frame(height: 8)

                // 底部提示
                if reward.currentCoins < reward.targetCoins {
                    let remaining = reward.targetCoins - reward.currentCoins
                    Text(String(format: String(localized: "距离解锁还差 %d 忍币"), remaining))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
