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

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(String(localized: "首页"), systemImage: "house.fill")
                }

            StatsView()
                .tabItem {
                    Label(String(localized: "统计"), systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label(String(localized: "设置"), systemImage: "gear")
                }
        }
        .onOpenURL { url in
            if url.scheme == "holdit" && url.host == "record" {
                appState.triggerRecordSheet = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(StoreManager())
        .modelContainer(for: [ResistRecord.self, CustomCategory.self])
}
