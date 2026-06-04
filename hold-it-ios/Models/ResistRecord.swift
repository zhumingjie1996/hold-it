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
