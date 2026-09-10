//
//  ResistRecord.swift
//  hold-it-ios
//

import Foundation
import SwiftData

@Model
class ResistRecord {
    var id: UUID
    var category: String
    var categoryEmoji: String
    var categoryID: String = ""
    var note: String
    var createdAt: Date
    var amount: Double?

    /// 兼容旧数据的有效 categoryID（空则回退到 category 名）
    var effectiveCategoryID: String {
        categoryID.isEmpty ? category : categoryID
    }

    init(category: String, categoryEmoji: String, categoryID: String, note: String = "", amount: Double? = nil) {
        self.id = UUID()
        self.category = category
        self.categoryEmoji = categoryEmoji
        self.categoryID = categoryID.isEmpty ? category : categoryID
        self.note = note
        self.createdAt = Date()
        self.amount = amount
    }
}

// MARK: - 自定义分类（持久化）
@Model
class CustomCategory {
    var id: UUID
    var emoji: String
    var name: String
    var hasAmount: Bool       // 是否涉及金钱支出
    var defaultAmount: Double? // 默认节省金额（可选）
    var createdAt: Date

    init(emoji: String, name: String, hasAmount: Bool, defaultAmount: Double? = nil) {
        self.id = UUID()
        self.emoji = emoji
        self.name = name
        self.hasAmount = hasAmount
        self.defaultAmount = defaultAmount
        self.createdAt = Date()
    }
}

// MARK: - 展示用分类结构体
struct ResistCategory: Identifiable {
    let id: UUID
    let emoji: String
    let name: String
    let hasAmount: Bool
    let defaultAmount: Double?
    let isCustom: Bool
    let customCategoryID: UUID?
    let fixedID: String?
    let placeholder: String

    /// 用于记录和统计的唯一标识：默认分类用 fixedID，自定义分类用 customCategoryID
    var stableID: String {
        if isCustom, let cid = customCategoryID {
            return cid.uuidString
        }
        return fixedID ?? name
    }

    /// 默认分类初始化
    init(emoji: String, name: String, defaultAmount: Double?, fixedID: String, placeholder: String = "") {
        self.id = UUID()
        self.emoji = emoji
        self.name = name
        self.defaultAmount = defaultAmount
        self.hasAmount = defaultAmount != nil
        self.isCustom = false
        self.customCategoryID = nil
        self.fixedID = fixedID
        self.placeholder = placeholder
    }

    /// 自定义分类初始化
    init(from custom: CustomCategory) {
        self.id = custom.id
        self.emoji = custom.emoji
        self.name = custom.name
        self.hasAmount = custom.hasAmount
        self.defaultAmount = custom.defaultAmount
        self.isCustom = true
        self.customCategoryID = custom.id
        self.fixedID = nil
        self.placeholder = ""
    }

    static let defaults: [ResistCategory] = [
        ResistCategory(emoji: "🧋", name: String(localized: "奶茶"),   defaultAmount: 15, fixedID: "default_milk_tea", placeholder: String(localized: "忍住没喝一杯…")),
        ResistCategory(emoji: "💸", name: String(localized: "冲动消费"), defaultAmount: 100, fixedID: "default_impulse_buy", placeholder: String(localized: "忍住买了一个…")),
        ResistCategory(emoji: "🎮", name: String(localized: "游戏"),   defaultAmount: nil, fixedID: "default_gaming", placeholder: String(localized: "忍住又玩了一局…")),
        ResistCategory(emoji: "📱", name: String(localized: "短视频"),  defaultAmount: nil, fixedID: "default_short_video", placeholder: String(localized: "忍住刷了一会…")),
        ResistCategory(emoji: "❤️", name: String(localized: "想TA"),   defaultAmount: nil, fixedID: "default_miss_him", placeholder: String(localized: "聊表心意"))
    ]
}

extension ResistCategory: Equatable {
    static func == (lhs: ResistCategory, rhs: ResistCategory) -> Bool {
        lhs.id == rhs.id
    }
}

extension ResistCategory: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 默认分类名称本地化辅助
/// 根据 categoryID 返回本地化名称：默认分类走 xcstrings，自定义分类直接用 fallback
func localizedCategoryName(categoryID: String, fallback: String) -> String {
    // 默认分类 ID 映射表
    let defaultIDToKey: [String: String] = [
        "default_milk_tea":    "奶茶",
        "default_impulse_buy": "冲动消费",
        "default_gaming":      "游戏",
        "default_short_video": "短视频",
        "default_miss_him":    "想TA",
    ]
    if let key = defaultIDToKey[categoryID] {
        return String(localized: String.LocalizationValue(key))
    }
    return fallback
}

// MARK: - 记录/分类删除（RecordSheet / 克制项管理 / 时间线撤回 共用）
extension ModelContext {
    /// 删除单条忍住记录：级联删除其忍币记录，并回退相关奖励进度
    /// （已解锁且金币跌回目标以下的回退为进行中；已兑换的奖励保留状态，仅扣金币）
    func deleteResistRecord(_ record: ResistRecord) {
        let recordID = record.id
        let affectedCoins = ((try? fetch(FetchDescriptor<RewardCoinRecord>())) ?? [])
            .filter { $0.restraintRecordID == recordID }
        rollbackCoins(affectedCoins)
        delete(record)
    }

    /// 删除自定义忍住项；includingRecords 为 true 时级联删除其全部记录、
    /// 对应忍币记录，并回退相关奖励进度（已解锁且金币跌回目标以下的回退为进行中）
    func deleteCustomCategory(_ custom: CustomCategory, includingRecords: Bool, allRecords: [ResistRecord]) {
        if includingRecords {
            let stableID = custom.id.uuidString
            let targets = allRecords.filter { $0.effectiveCategoryID == stableID }
            if !targets.isEmpty {
                let targetIDs = Set(targets.map(\.id))
                let affectedCoins = ((try? fetch(FetchDescriptor<RewardCoinRecord>())) ?? [])
                    .filter { targetIDs.contains($0.restraintRecordID) }
                rollbackCoins(affectedCoins)
                for record in targets {
                    delete(record)
                }
            }
        }
        delete(custom)
    }

    /// 回退一组忍币记录：扣减奖励进度、必要时将已解锁奖励降回进行中，并删除忍币记录
    private func rollbackCoins(_ coins: [RewardCoinRecord]) {
        guard !coins.isEmpty else { return }
        let rewardsByID = Dictionary(
            uniqueKeysWithValues: ((try? fetch(FetchDescriptor<Reward>())) ?? []).map { ($0.id, $0) }
        )
        for coin in coins {
            if let reward = rewardsByID[coin.rewardID] {
                reward.currentCoins = max(0, reward.currentCoins - coin.coins)
                if reward.status == .unlocked, reward.currentCoins < reward.targetCoins {
                    reward.status = .inProgress
                    reward.unlockedAt = nil
                }
            }
            delete(coin)
        }
    }
}
