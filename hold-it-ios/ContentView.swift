//
//  ContentView.swift
//  hold-it-ios
//
//  Created by zhumingjie on 2026/6/2.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var storeManager

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

            TimelineView()
                .tabItem {
                    Label("时间线", systemImage: "clock.fill")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(StoreManager())
        .modelContainer(for: ResistRecord.self)
}
