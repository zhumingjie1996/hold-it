//
//  SettingsView.swift
//  hold-it-ios
//

import SwiftUI
import StoreKit
import UIKit

enum ThemeMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var label: String {
        switch self {
        case .system: return String(localized: "跟随系统")
        case .light: return String(localized: "浅色")
        case .dark: return String(localized: "深色")
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.openURL) private var openURL
    @AppStorage("themeMode") private var themeModeRaw: Int = 0
    @AppStorage("currencyCode") private var currencyCode: String = "auto"
    @State private var showRestoreAlert = false
    @State private var restoreSuccess = false

    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            List {
                vipSection

                Section("外观") {
                    Picker(selection: $themeModeRaw) {
                        ForEach(ThemeMode.allCases, id: \.rawValue) { mode in
                            Label(mode.label, systemImage: mode.icon)
                                .tag(mode.rawValue)
                        }
                    } label: {
                        Label("主题", systemImage: "paintbrush.fill")
                    }

                    Picker(selection: $currencyCode) {
                        ForEach(SupportedCurrency.allCases) { currency in
                            Text(currency.displayName).tag(currency.rawValue)
                        }
                    } label: {
                        Label("货币单位", systemImage: "dollarsign.circle.fill")
                    }

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        Label("语言", systemImage: "globe")
                            .foregroundStyle(.primary)
                    }
                }

                Section("关于") {
                    NavigationLink("关于忍一下") {
                        AboutView()
                    }

                    if let url = URL(string: "https://apps.apple.com") {
                        Link("评价应用", destination: url)
                    }
                }

                Section("支持") {
                    Button("恢复购买") {
                        Task {
                            await storeManager.restorePurchases()
                            restoreSuccess = storeManager.isVip
                            showRestoreAlert = true
                        }
                    }

                    if let url = URL(string: "mailto:support@holdit.app") {
                        Link("意见反馈", destination: url)
                    }
                }

                Section("法律") {
                    NavigationLink("隐私政策") {
                        LegalView(title: "隐私政策", content: privacyPolicy)
                    }
                    NavigationLink("用户协议") {
                        LegalView(title: "用户协议", content: termsOfService)
                    }
                }
            }
            .navigationTitle("设置")
            .alert("恢复购买", isPresented: $showRestoreAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(restoreSuccess ? "已成功恢复购买" : "未找到购买记录")
            }
        }
    }

    private var vipSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: storeManager.isVip ? "checkmark.seal.fill" : "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(storeManager.isVip ? Color.green : Color(hex: "F59E0B"))

                VStack(alignment: .leading, spacing: 4) {
                    Text(storeManager.isVip ? "已激活终身会员" : "解锁终身会员")
                        .font(.headline)
                    Text(storeManager.isVip
                         ? "享受所有高级功能"
                         : "热力图、趋势图、年度报告等")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !storeManager.isVip {
                    Button {
                        Task {
                            _ = await storeManager.purchase()
                        }
                    } label: {
                        Text("购买")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "F59E0B"))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.brand)

                    Text("忍一下")
                        .font(.title.weight(.bold))

                    Text("记录克制，成就更好的自己")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("版本 1.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }

            Section {
                Text("忍一下是一款专门记录克制行为的极简 App。我们不记录「完成了什么」，而是记录「忍住了什么」——没喝奶茶、没刷短视频、没冲动消费。每一次克制，都是对自己的一次胜利。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LegalView: View {
    let title: String
    let content: String

    var body: some View {
        ScrollView {
            Text(content)
                .font(.body)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private let privacyPolicy = """
隐私政策

1. 数据收集
本应用为完全离线运行，不会收集、上传或分享您的任何个人数据。所有记录均存储在您的设备本地。

2. 数据使用
您的记录数据仅用于在应用内展示统计信息，不会用于任何其他目的。

3. 第三方服务
本应用不使用任何第三方分析或广告服务。

4. 数据安全
您的数据存储在设备本地，由系统级安全机制保护。

5. 联系我们
如有任何问题，请通过意见反馈联系我们。
"""

private let termsOfService = """
用户协议

1. 使用条款
使用本应用即表示您同意本协议的所有条款。

2. 服务内容
本应用提供克制行为记录和统计功能。

3. 会员服务
终身会员为一次性购买，购买后即可永久使用所有高级功能。

4. 退款政策
退款请通过 App Store 申请。

5. 协议修改
我们保留修改本协议的权利，修改后的协议将在应用内公布。
"""
