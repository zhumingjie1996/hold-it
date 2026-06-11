//
//  Reward.swift
//  hold-it-ios
//

import Foundation
import SwiftData

// MARK: - 奖励状态
enum RewardStatus: String, Codable {
    case inProgress = "IN_PROGRESS"
    case unlocked = "UNLOCKED"
    case redeemed = "REDEEMED"
}

// MARK: - 奖励模型
@Model
class Reward {
    var id: UUID
    var title: String
    var rewardDescription: String
    var imageData: Data?
    var targetCoins: Int
    var currentCoins: Int
    /// 关联的克制项 categoryID 列表
    var categoryIDs: [String]
    /// 状态字符串
    var statusRaw: String
    var createdAt: Date
    var unlockedAt: Date?
    var redeemedAt: Date?

    var status: RewardStatus {
        get { RewardStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    /// 进度百分比 0.0 ~ 1.0
    var progress: Double {
        guard targetCoins > 0 else { return 0 }
        return min(Double(currentCoins) / Double(targetCoins), 1.0)
    }

    init(
        title: String,
        rewardDescription: String = "",
        imageData: Data? = nil,
        targetCoins: Int,
        categoryIDs: [String]
    ) {
        self.id = UUID()
        self.title = title
        self.rewardDescription = rewardDescription
        self.imageData = imageData
        self.targetCoins = targetCoins
        self.currentCoins = 0
        self.categoryIDs = categoryIDs
        self.statusRaw = RewardStatus.inProgress.rawValue
        self.createdAt = Date()
        self.unlockedAt = nil
        self.redeemedAt = nil
    }
}

// MARK: - 忍币记录模型
@Model
class RewardCoinRecord {
    var id: UUID
    var rewardID: UUID
    var restraintRecordID: UUID
    var coins: Int
    var createdAt: Date

    init(rewardID: UUID, restraintRecordID: UUID, coins: Int = 1) {
        self.id = UUID()
        self.rewardID = rewardID
        self.restraintRecordID = restraintRecordID
        self.coins = coins
        self.createdAt = Date()
    }
}
