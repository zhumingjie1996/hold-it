//
//  SettingsView.swift
//  hold-it-ios
//

import SwiftUI
import StoreKit
import SwiftData
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
    @State private var showClearDataAlert = false
    @State private var showPurchaseResult = false

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

                Section("危险操作") {
                    Button(role: .destructive) {
                        showClearDataAlert = true
                    } label: {
                        Label("抹除所有数据", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("设置")
            .alert("恢复购买", isPresented: $showRestoreAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                if restoreSuccess {
                    Text("已成功恢复购买")
                } else {
                    Text("未找到购买记录")
                }
            }
            .alert("抹除所有数据", isPresented: $showClearDataAlert) {
                Button("抹除", role: .destructive) {
                    clearAllData()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("此操作不可恢复，所有忍住记录和自定义分类将被永久删除。")
            }
            .alert("购买结果", isPresented: $showPurchaseResult) {
                Button("确定", role: .cancel) {
                    storeManager.purchaseState = .idle
                }
            } message: {
                if storeManager.purchaseState == .success {
                    Text("已成功解锁终身会员！")
                } else {
                    Text("购买失败，请稍后重试或检查网络连接。")
                }
            }
        }
    }

    private var vipSection: some View {
        Section {
            if storeManager.isLoading {
                // 加载中状态
                HStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "正在加载会员信息…"))
                            .font(.headline)
                        Text(String(localized: "请稍候"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            } else if storeManager.isVip {
                // 已激活状态
                HStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "已激活终身会员"))
                            .font(.headline)
                        Text(String(localized: "享受所有高级功能"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                // 未激活：购买入口
                HStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(hex: "F59E0B"))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "解锁终身会员"))
                            .font(.headline)
                        Text(String(localized: "热力图、趋势图、年度报告等"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        Task {
                            _ = await storeManager.purchase()
                            if storeManager.purchaseState == .success {
                                showPurchaseResult = true
                            } else if storeManager.purchaseState == .failed {
                                showPurchaseResult = true
                            }
                        }
                    } label: {
                        if storeManager.purchaseState == .purchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 80, height: 32)
                                .background(Color(hex: "F59E0B"))
                                .cornerRadius(20)
                        } else {
                            Text(storeManager.displayPrice.isEmpty ? String(localized: "购买") : storeManager.displayPrice)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(hex: "F59E0B"))
                                .cornerRadius(20)
                        }
                    }
                    .disabled(storeManager.purchaseState == .purchasing)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - 抹除数据
    @Environment(\.modelContext) private var modelContext

    private func clearAllData() {
        do {
            try modelContext.delete(model: ResistRecord.self)
            try modelContext.delete(model: CustomCategory.self)
            try modelContext.save()
        } catch {
            print("清除数据失败: \(error)")
        }
    }
}

struct AboutView: View {

    @ViewBuilder
    private func featureRow(emoji: String, title: LocalizedStringKey, desc: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 20))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    ZStack(alignment: .bottomTrailing) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .opacity(1)
                        Text("🫰")
                            .font(.system(size: 20))
                            .offset(x: -50, y: -10)
                    }

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
                VStack(alignment: .leading, spacing: 16) {
                    Text("「忍一下」是一款专注于『克制』的极简记录 App。")
                        .font(.subheadline.weight(.medium))

                    Text("我们不记录「完成了什么」，而是记录「忍住了什么」——没喝奶茶、没刷短视频、没冲动消费。每一次忍住，都是对自己的一次胜利。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        featureRow(emoji: "📝", title: "忍住记录", desc: "一键记录你每一次忍住的努力")
                        featureRow(emoji: "🎨", title: "自定义分类(PRO)", desc: "添加你自己想记录的任意忍住项")
                        featureRow(emoji: "📊", title: "多维统计(PRO)", desc: "热力图、分类分析、月度趋势一目了然")
                        featureRow(emoji: "💰", title: "节省统计(PRO)", desc: "计算忍住消费所节省的真实金额")
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("关于应用")
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
本应用提供忍住行为记录和统计功能。

3. 会员服务
终身会员为一次性购买，购买后即可永久使用所有高级功能。

4. 退款政策
退款请通过 App Store 申请。

5. 协议修改
我们保留修改本协议的权利，修改后的协议将在应用内公布。
"""
