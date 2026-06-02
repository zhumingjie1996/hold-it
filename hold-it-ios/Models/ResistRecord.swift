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

struct ResistCategory: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let name: String
    let defaultAmount: Double?

    static let defaults: [ResistCategory] = [
        ResistCategory(emoji: "🧋", name: "奶茶", defaultAmount: 15),
        ResistCategory(emoji: "🍿", name: "零食", defaultAmount: 20),
        ResistCategory(emoji: "🌙", name: "熬夜", defaultAmount: nil),
        ResistCategory(emoji: "💸", name: "冲动消费", defaultAmount: 100),
        ResistCategory(emoji: "🎮", name: "游戏", defaultAmount: nil),
        ResistCategory(emoji: "📱", name: "短视频", defaultAmount: nil),
        ResistCategory(emoji: "🐟", name: "摸鱼", defaultAmount: nil),
        ResistCategory(emoji: "🍺", name: "烟酒", defaultAmount: 30),
        ResistCategory(emoji: "✨", name: "其他", defaultAmount: nil)
    ]
}
