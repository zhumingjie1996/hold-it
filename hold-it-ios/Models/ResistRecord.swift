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

    /// 用于记录和统计的唯一标识：默认分类用 fixedID，自定义分类用 customCategoryID
    var stableID: String {
        if isCustom, let cid = customCategoryID {
            return cid.uuidString
        }
        return fixedID ?? name
    }

    /// 默认分类初始化
    init(emoji: String, name: String, defaultAmount: Double?, fixedID: String) {
        self.id = UUID()
        self.emoji = emoji
        self.name = name
        self.defaultAmount = defaultAmount
        self.hasAmount = defaultAmount != nil
        self.isCustom = false
        self.customCategoryID = nil
        self.fixedID = fixedID
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
    }

    static let defaults: [ResistCategory] = [
        ResistCategory(emoji: "🧋", name: "奶茶",   defaultAmount: 15, fixedID: "default_milk_tea"),
        ResistCategory(emoji: "💸", name: "冲动消费", defaultAmount: 100, fixedID: "default_impulse_buy"),
        ResistCategory(emoji: "🎮", name: "游戏",   defaultAmount: nil, fixedID: "default_gaming"),
        ResistCategory(emoji: "📱", name: "短视频",  defaultAmount: nil, fixedID: "default_short_video"),
        ResistCategory(emoji: "❤️", name: "想TA",   defaultAmount: nil, fixedID: "default_miss_him")
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
