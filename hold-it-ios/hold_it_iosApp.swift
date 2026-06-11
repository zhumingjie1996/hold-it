//
//  hold_it_iosApp.swift
//  hold-it-ios
//
//  Created by zhumingjie on 2026/6/2.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct hold_it_iosApp: App {
    @State private var appState = AppState()
    @State private var storeManager = StoreManager()
    @AppStorage("themeMode") private var themeModeRaw: Int = 0

    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(storeManager)
                .preferredColorScheme(themeMode.colorScheme)
        }
        .modelContainer(hold_it_iosApp.createModelContainer())
    }

    /// 创建 ModelContainer，若 schema 不兼容则删除旧库重建
    static func createModelContainer() -> ModelContainer {
        let schema = Schema([ResistRecord.self, CustomCategory.self, Reward.self, RewardCoinRecord.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // schema 变更导致加载失败，删除旧数据库重建
            print("ModelContainer load failed: \(error). Rebuilding...")
            let url = config.url
            let urls = [
                url,
                url.appendingPathExtension("-wal"),
                url.appendingPathExtension("-shm")
            ]
            for fileURL in urls {
                try? FileManager.default.removeItem(at: fileURL)
            }
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }
}

extension Color {
    static let systemGroupedBackground = Color(uiColor: .systemGroupedBackground)
    static let secondarySystemGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let systemBackground = Color(uiColor: .systemBackground)
    static let systemGray5 = Color(uiColor: .systemGray5)

    /// 品牌主色 - 鲜亮翠绿色 #6AD86C
    static let brand = Color(.sRGB, red: 106/255, green: 216/255, blue: 108/255, opacity: 1)
    /// 品牌深色 - 用于在 brand 背景上的文字，确保可读性 #1F6B2A
    static let brandDark = Color(.sRGB, red: 31/255, green: 107/255, blue: 42/255, opacity: 1)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
