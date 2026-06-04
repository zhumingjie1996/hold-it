//
//  ContentView.swift
//  hold-it-ios
//
//  Created by zhumingjie on 2026/6/2.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }

            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
        .onAppear {
            insertMockDataIfNeeded()
        }
    }

    // MARK: - Mock 数据注入（仅首次）
    private func insertMockDataIfNeeded() {
        let key = "mock_data_inserted_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let calendar = Calendar.current
        let now = Date()

        // 分类配置：(category, emoji, categoryID, hasAmount, amountRange)
        let categories: [(String, String, String, Bool, ClosedRange<Double>?)] = [
            ("奶茶",   "🧋", "default_milk_tea",    true,  12.0...32.0),
            ("冲动消费", "💸", "default_impulse_buy",  true,  30.0...299.0),
            ("游戏",   "🎮", "default_gaming",       false, nil),
            ("短视频",  "📱", "default_short_video",  false, nil),
            ("想TA",  "❤️", "default_miss_him",     false, nil),
        ]

        let notes: [String: [String]] = [
            "default_milk_tea":    ["好想喝一杯", "下午茶冲动", "路过奶茶店忍住了", "同事都在点", ""],
            "default_impulse_buy": ["又想买新衣服", "限时折扣忍住了", "看到广告心动了", "购物车清空", ""],
            "default_gaming":      ["才打了一局", "再玩一局的冲动", "队友喊我忍住了", "", ""],
            "default_short_video": ["刷了好久了", "睡前又拿起手机", "放下手机去散步", "", ""],
            "default_miss_him":    ["想发消息忍住了", "看到熟悉的地方", "听到那首歌", "", ""],
        ]

        // 生成过去 180 天的数据，每天 0~4 条，概率分布不均匀
        for dayOffset in 0...999 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: day)

            // 越近数据越密集
            let maxCount = dayOffset < 7 ? 4 : (dayOffset < 30 ? 3 : 2)
            let count = Int.random(in: 0...maxCount)
            guard count > 0 else { continue }

            for _ in 0..<count {
                // 随机时间（7:00 ~ 23:00）
                let hour = Int.random(in: 7...23)
                let minute = Int.random(in: 0...59)
                guard let recordTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay) else { continue }

                // 随机选分类（奶茶和短视频权重更高）
                let weights = [3, 2, 2, 4, 2]
                let totalWeight = weights.reduce(0, +)
                var rand = Int.random(in: 0..<totalWeight)
                var catIndex = 0
                for (i, w) in weights.enumerated() {
                    rand -= w
                    if rand < 0 { catIndex = i; break }
                }

                let (catName, catEmoji, catID, hasAmount, amountRange) = categories[catIndex]
                let noteList = notes[catID] ?? [""]
                let note = noteList.randomElement() ?? ""
                let amount: Double? = hasAmount ? (amountRange.map { Double.random(in: $0) }.map { (($0 * 2).rounded() / 2) }) : nil

                let record = ResistRecord(
                    category: catName,
                    categoryEmoji: catEmoji,
                    categoryID: catID,
                    note: note,
                    amount: amount
                )
                record.createdAt = recordTime
                modelContext.insert(record)
            }
        }

        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(StoreManager())
        .modelContainer(for: [ResistRecord.self, CustomCategory.self])
}
