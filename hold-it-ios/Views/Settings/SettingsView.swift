//
//  SettingsView.swift
//  hold-it-ios
//

import SwiftUI
import StoreKit
import SwiftData
import UIKit
import WidgetKit

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
    @State private var showClearDataAlert = false
    @State private var showPurchaseResult = false

    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            List {
                // 非会员：CTA 横幅跟随列表滚动
                if !storeManager.isLoading && !storeManager.isVip {
                    Section {
                        ctaBanner
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listSectionSeparator(.hidden)
                }

                // VIP 已激活或加载中：显示在 Section 里
                if storeManager.isLoading || storeManager.isVip {
                    vipSection
                }

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
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("关于忍一下", systemImage: "info.circle.fill")
                    }

                    Button {
                        if let scene = UIApplication.shared.connectedScenes
                            .compactMap({ $0 as? UIWindowScene })
                            .first(where: { $0.activationState == .foregroundActive }) {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    } label: {
                        Label("评价应用", systemImage: "star.fill")
                            .foregroundStyle(.primary)
                    }
                }

                Section("支持") {
                    Button {
                        Task {
                            await storeManager.restorePurchases()
                        }
                    } label: {
                        HStack {
                            Label("恢复购买", systemImage: "arrow.counterclockwise.circle.fill")
                            Spacer()
                            if case .restoring = storeManager.restoreState {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled({ if case .restoring = storeManager.restoreState { return true }; return false }())

                    if let url = URL(string: "mailto:zhumingjie0822@gmail.com") {
                        Link(destination: url) {
                            Label("意见反馈", systemImage: "envelope.fill")
                        }
                    }
                }

                Section("法律") {
                    NavigationLink {
                        LegalView(title: String(localized: "隐私政策"), content: localizedPrivacyPolicy)
                    } label: {
                        Label("隐私政策", systemImage: "lock.shield.fill")
                    }
                    NavigationLink {
                        LegalView(title: String(localized: "用户协议"), content: localizedTermsOfService)
                    } label: {
                        Label("用户协议", systemImage: "doc.text.fill")
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
            .alert(restoreAlertTitle, isPresented: restoreAlertBinding) {
                Button("确定", role: .cancel) {
                    storeManager.resetRestoreState()
                }
            } message: {
                Text(restoreAlertMessage)
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

    // MARK: - 恢复购买 Alert 逻辑
    private var restoreAlertBinding: Binding<Bool> {
        Binding(
            get: {
                if case .restoring = storeManager.restoreState { return false }
                if case .idle = storeManager.restoreState { return false }
                return true
            },
            set: { _ in }
        )
    }

    private var restoreAlertTitle: String {
        switch storeManager.restoreState {
        case .success:
            return "🎉 " + String(localized: "恢复成功")
        case .noPurchases:
            return String(localized: "未找到购买记录")
        case .notSignedIn:
            return String(localized: "未登录 Apple ID")
        case .networkError:
            return String(localized: "网络错误")
        case .failed:
            return String(localized: "恢复失败")
        default:
            return String(localized: "恢复购买")
        }
    }

    private var restoreAlertMessage: String {
        switch storeManager.restoreState {
        case .success:
            return String(localized: "已成功恢复您的购买，会员权益已激活。")
        case .noPurchases:
            return String(localized: "当前 Apple ID 下未找到任何购买记录。请确认您使用的是购买时所用的 Apple ID。")
        case .notSignedIn:
            return String(localized: "请先登录您的 Apple ID，再尝试恢复购买。")
        case .networkError:
            return String(localized: "无法连接到 App Store，请检查网络连接后重试。")
        case .failed(let msg):
            return msg
        default:
            return ""
        }
    }

    // MARK: - VIP 已激活 / 加载中状态（在 List Section 里）
    private var vipSection: some View {
        Section {
            if storeManager.isLoading {
                HStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("正在加载会员信息…")
                            .font(.headline)
                        Text("请稍候")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            } else if storeManager.isVip {
                HStack(spacing: 16) {
                    ZStack(alignment: .bottomTrailing) {
                        Image("AppLogo")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .scaledToFit()
                            .opacity(1)
                        Text("👑")
                            .font(.system(size: 22))
                            .rotationEffect(.degrees(18))
                            .offset(x: -20, y: -57)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("已激活终身会员")
                            .font(.headline)
                        Text("享受所有高级功能")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - 未激活：全宽 CTA 横幅（在 List 外部）
    private var ctaBanner: some View {
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
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                        Text("支付中…")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Text("请稍候")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.brand, Color.brandDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            } else {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text("解锁终身会员")
                            .font(.headline)
                            .foregroundStyle(.white)
                        if !storeManager.displayPrice.isEmpty {
                            Text(storeManager.displayPrice)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                    Text("一次购买，终身使用")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.brand, Color.brandDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
    }

    // MARK: - 抹除数据
    @Environment(\.modelContext) private var modelContext

    private func clearAllData() {
        do {
            try modelContext.delete(model: ResistRecord.self)
            try modelContext.delete(model: CustomCategory.self)
            try modelContext.save()
            // 清空 Widget 共享数据
            WidgetDataStore.save(stats: WidgetDataStore.Stats())
            WidgetCenter.shared.reloadTimelines(ofKind: "HoldItWidget")
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
                    .fixedSize(horizontal: false, vertical: true)
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

                    Text("版本 1.1")
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
                        featureRow(emoji: "🎨", title: "自定义分类(VIP)", desc: "添加你自己想记录的任意忍住项")
                        featureRow(emoji: "📊", title: "多维统计(VIP)", desc: "热力图、分类分析、月度趋势一目了然")
                        featureRow(emoji: "💰", title: "节省统计(VIP)", desc: "计算忍住消费所节省的真实金额")
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

// MARK: - 多语言法律文案

private var localizedPrivacyPolicy: String {
    let lang = Locale.current.language.languageCode?.identifier ?? "zh"
    switch lang {
    case "en": return privacyPolicyEN
    case "ja": return privacyPolicyJA
    default:   return privacyPolicyZH
    }
}

private var localizedTermsOfService: String {
    let lang = Locale.current.language.languageCode?.identifier ?? "zh"
    switch lang {
    case "en": return termsOfServiceEN
    case "ja": return termsOfServiceJA
    default:   return termsOfServiceZH
    }
}

// MARK: - 隐私政策

private let privacyPolicyZH = """
隐私政策
更新日期：2025 年 6 月 4 日

1. 概述
「忍一下」（以下简称"本应用"）高度重视您的隐私。本政策说明我们如何处理您在使用本应用时所涉及的信息。

2. 数据收集
本应用完全离线运行，不会收集、上传或共享您的任何个人数据。所有忍住记录、自定义分类、奖励设置及偏好设置均存储在您的设备本地，不经您明确同意永远不会离开设备。

3. 数据使用
您的记录数据仅用于在应用内展示统计信息和奖励进度，不会用于任何其他目的。我们无法访问您设备上的任何数据。

4. 第三方服务
本应用不使用任何第三方分析工具、广告服务或数据上传服务。应用内购功能通过 Apple 的 StoreKit 实现，符合 Apple 隐私政策。购买过程中 Apple 可能会收集必要的交易信息，详情请参阅 Apple 隐私政策。

5. 数据安全
您的数据存储在设备本地，受 iOS 系统级安全机制保护。如您开启 iCloud 备份，数据将随设备备份到您的 iCloud 个人空间，受 Apple 隐私政策保护。

6. 儿童隐私
本应用不面向 13 岁以下的儿童，不会故意收集儿童个人信息。若监护人发现儿童在未经授权的情况下提供了个人信息，请与我们联系，我们将尽快删除相关数据。

7. 隐私政策变更
本隐私政策可能随应用更新而变更。重大变更将在应用内公告。继续使用本应用即表示您接受更新后的政策。

8. 联系我们
如您对本隐私政策有任何疑问，请通过应用内的"意见反馈"或发送邮件至 zhumingjie0822@gmail.com 联系我们。
"""

private let privacyPolicyEN = """
Privacy Policy
Last updated: June 4, 2025

1. Overview
"Hold It" (the "App") is committed to protecting your privacy. This policy explains how we handle information when you use the App.

2. Data Collection
The App runs entirely offline. We do not collect, upload, or share any of your personal data. All resistance records, custom categories, reward configurations, and preferences are stored locally on your device and never leave it without your explicit consent.

3. Data Use
Your data is used solely to display statistics and reward progress within the App. We have no access to any data on your device.

4. Third-Party Services
The App does not use any third-party analytics, advertising, or data-upload services. In-app purchases are handled by Apple's StoreKit, subject to Apple's Privacy Policy. Apple may collect necessary transaction information during purchases; please refer to Apple's Privacy Policy for details.

5. Data Security
Your data is stored locally and protected by iOS system-level security. If you enable iCloud Backup, data will be included in your personal iCloud backup, protected by Apple's Privacy Policy.

6. Children's Privacy
The App is not directed at children under 13. We do not knowingly collect personal information from children. If a guardian discovers that a child has provided personal information without consent, please contact us and we will promptly delete the data.

7. Changes to This Policy
This policy may be updated with app updates. Significant changes will be announced within the App. Continued use constitutes acceptance of the updated policy.

8. Contact Us
If you have questions about this privacy policy, please contact us via the Feedback option in the App or email us at zhumingjie0822@gmail.com.
"""

private let privacyPolicyJA = """
プライバシーポリシー
最終更新：2025年6月4日

1. 概要
「Hold It」（以下「本アプリ」）は、あなたのプライバシーを重視しています。本ポリシーは、本アプリのご利用にあたっての情報の取り扱いについて説明します。

2. データの収集
本アプリは完全オフラインで動作します。個人データの収集・アップロード・共有は一切行いません。すべての記録データ、カスタムカテゴリー、報酬設定、環境設定はお使いの端末に保存され、明示的な同意なく端末外に送信されることはありません。

3. データの利用
データはアプリ内の統計表示および報酬の進捗管理のみに使用されます。私たちが端末上のデータにアクセスすることは一切ありません。

4. 第三者サービス
本アプリは第三者の分析・広告サービスを一切使用しません。アプリ内購買は Apple の StoreKit を使用しており、Apple のプライバシーポリシーに従います。購入時に Apple が必要な取引情報を収集する場合があります。詳細は Apple のプライバシーポリシーをご参照ください。

5. データの安全性
データは端末内に保存され、iOS のセキュリティ機構によって保護されます。iCloud バックアップを有効にした場合、データは iCloud 個人スペースにバックアップされ、Apple のプライバシーポリシーにより保護されます。

6. 児童のプライバシー
本アプリは 13 歳未満の児童を対象としておらず、児童の個人情報を意図的に収集することはありません。保護者の方は、児童が同意なく個人情報を提供したことに気づいた場合は、ご連絡ください。速やかに削除いたします。

7. プライバシーポリシーの変更
本ポリシーはアプリのアップデートに伴い変更される場合があります。重要な変更はアプリ内でお知らせします。

8. お問い合わせ
プライバシーポリシーについてご不明な点があれば、アプリ内の「フィードバック」または zhumingjie0822@gmail.com までお問い合わせください。
"""

// MARK: - 用户协议

private let termsOfServiceZH = """
用户协议
更新日期：2025 年 6 月 4 日

1. 接受条款
使用「忍一下」即表示您已阅读并同意本协议的所有条款。如您不同意，请停止使用本应用。

2. 服务内容
本应用提供忍住行为记录、自定义分类、奖励系统、多维统计及桌面小组件等功能。我们保留随时修改、更新或停止服务的权利。

3. 用户行为
您同意不以如下方式使用本应用：
• 以任何非法目的使用本应用
• 试图破坏或干扰应用的正常运行
• 向他人转让或转售您的账户权益
• 利用本应用进行任何形式的欺诈活动

4. 会员服务
终身会员为一次性购买，购买后即可永久使用所有高级功能，包括但不限于无限自定义分类、高级统计和奖励系统。会员资格绑定至您的 Apple ID，可在同一 Apple ID 登录的所有设备上使用。

5. 退款政策
根据 Apple 的购买政策，退款请通过 App Store 申请。我们无法直接处理退款请求。

6. 免责声明
本应用按"现状"提供，不附带任何明示或暗示的保证。在法律允许的范围内，我们不就任何隐含保证（包括适销性、特定用途适用性）作出承诺。使用本应用产生的任何风险由您自行承担。

7. 分类与奖励内容
本应用内的预设分类仅供参考。您可以创建自定义分类和奖励项目，内容应合法合规，不得包含不当内容。

8. 协议修改
我们保留修改本协议的权利。重大变更将在应用内公告。继续使用本应用即表示您接受更新后的协议。

9. 联系我们
如您对本协议有任何疑问，请通过应用内的"意见反馈"或发送邮件至 zhumingjie0822@gmail.com 联系我们。
"""

private let termsOfServiceEN = """
Terms of Service
Last updated: June 4, 2025

1. Acceptance of Terms
By using "Hold It", you agree to these Terms of Service. If you do not agree, please stop using the App.

2. Services
The App provides resistance tracking, custom categories, a reward system, multi-dimensional statistics, and home screen widgets. We reserve the right to modify, update, or discontinue services at any time.

3. User Conduct
You agree not to:
• Use the App for any unlawful purpose
• Attempt to disrupt or interfere with the App's normal operation
• Transfer or sell your account rights to others
• Use the App for any form of fraudulent activity

4. Membership
Lifetime membership is a one-time purchase that grants permanent access to all premium features, including but not limited to unlimited custom categories, advanced statistics, and the reward system. Membership is tied to your Apple ID and available on all devices signed in with the same Apple ID.

5. Refund Policy
Refunds are subject to Apple's purchase policy. Please request refunds through the App Store. We are unable to process refund requests directly.

6. Disclaimer
The App is provided "as is" without warranties of any kind, express or implied. To the extent permitted by law, we make no warranties, including merchantability or fitness for a particular purpose. Use of the App is at your own risk.

7. Category and Reward Content
Preset categories are for reference only. Custom categories and reward items must be lawful and appropriate.

8. Changes to Terms
We reserve the right to modify these terms. Significant changes will be announced within the App. Continued use constitutes acceptance.

9. Contact
For questions about these terms, please contact us via the Feedback option in the App or email us at zhumingjie0822@gmail.com.
"""

private let termsOfServiceJA = """
利用規約
最終更新：2025年6月4日

1. 規約の承認
「Hold It」を使用することで、本利用規約に同意したものとみなされます。同意いただけない場合は、本アプリのご利用を中止してください。

2. サービス内容
本アプリは、我慢行動の記録、カスタムカテゴリー、報酬システム、多次元統計、ホーム画面ウィジェットなどの機能を提供します。サービスは予告なく変更・終了される場合があります。

3. 利用者の行為
以下の行為を禁止します：
• 違法な目的での利用
• アプリの正常動作を妨害する行為
• アカウント権益の第三者への譲渡・販売
• 本アプリを利用した詐欺行為

4. 会員サービス
買い切り会員は一度の購入で全てのプレミアム機能を永久利用できます。これには、無制限のカスタムカテゴリー、高度な統計、報酬システムなどが含まれます。会員資格は Apple ID に結び付けられ、同一 Apple ID でサインインした全端末で利用可能です。

5. 返金ポリシー
返金は Apple の購入ポリシーに従い、App Store よりリクエストしてください。当方では直接返金処理は行えません。

6. 免責事項
本アプリは「現状のまま」提供され、明示的または暗示的ないかなる保証も伴いません。法律が許容する範囲で、商品性や特定目的への適合性を含む一切の保証をいたしません。本アプリの使用に伴うリスクは利用者の負担となります。

7. カテゴリーと報酬の内容
プリセットカテゴリーは参考用です。カスタムカテゴリーや報酬アイテムの内容は適法かつ適切なものである必要があります。

8. 規約の変更
本規約はアプリのアップデートに伴い変更される場合があります。重要な変更はアプリ内でお知らせします。引き続きご利用いただくことで変更後の規約に同意いただいたことになります。

9. お問い合わせ
利用規約についてご不明な点があれば、アプリ内の「フィードバック」または zhumingjie0822@gmail.com までお問い合わせください。
"""
