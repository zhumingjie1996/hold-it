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
    var note: String
    var createdAt: Date
    var amount: Double?

    init(category: String, categoryEmoji: String, note: String = "", amount: Double? = nil) {
        self.id = UUID()
        self.category = category
        self.categoryEmoji = categoryEmoji
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

    /// 默认分类初始化
    init(emoji: String, name: String, defaultAmount: Double?) {
        self.id = UUID()
        self.emoji = emoji
        self.name = name
        self.defaultAmount = defaultAmount
        self.hasAmount = defaultAmount != nil
        self.isCustom = false
        self.customCategoryID = nil
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
    }

    static let defaults: [ResistCategory] = [
        ResistCategory(emoji: "🧋", name: "奶茶",   defaultAmount: 15),
        ResistCategory(emoji: "🍿", name: "零食",   defaultAmount: 20),
        ResistCategory(emoji: "🌙", name: "熬夜",   defaultAmount: nil),
        ResistCategory(emoji: "💸", name: "冲动消费", defaultAmount: 100),
        ResistCategory(emoji: "🎮", name: "游戏",   defaultAmount: nil),
        ResistCategory(emoji: "📱", name: "短视频",  defaultAmount: nil),
        ResistCategory(emoji: "🐟", name: "摸鱼",   defaultAmount: nil),
        ResistCategory(emoji: "🍺", name: "烟酒",   defaultAmount: 30),
        ResistCategory(emoji: "✨", name: "其他",   defaultAmount: nil)
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
