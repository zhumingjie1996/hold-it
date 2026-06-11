//
//  StatsView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData
import UIKit

struct StatsView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var storeManager
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @Query private var allRewards: [Reward]
    @Query private var allCoinRecords: [RewardCoinRecord]
    @AppStorage("currencyCode") private var currencyCode: String = "auto"
    @State private var showVipAlert = false
    @State private var showExportSheet = false
    @State private var exportImage: UIImage? = nil
    @State private var isExporting = false
    @AppStorage("statsModuleOrder") private var moduleOrderData: Data = Data()
    @State private var showSortSheet = false

    private var moduleOrder: [String] {
        get { (try? JSONDecoder().decode([String].self, from: moduleOrderData)) ?? [] }
    }
    private func saveModuleOrder(_ names: [String]) {
        moduleOrderData = (try? JSONEncoder().encode(names)) ?? Data()
    }

    /// 默认模块顺序
    private let defaultModuleOrder = [
        "category", "weekday", "timeOfDay", "heatmap", "monthlyTrend"
    ]

    /// 按用户排序返回模块 ID 列表
    private var orderedModules: [String] {
        let order = moduleOrder.isEmpty ? defaultModuleOrder : moduleOrder
        var sorted: [String] = []
        for id in order {
            if defaultModuleOrder.contains(id) { sorted.append(id) }
        }
        for id in defaultModuleOrder where !sorted.contains(id) { sorted.append(id) }
        return sorted
    }

    @ViewBuilder
    private func moduleView(for id: String) -> some View {
        switch id {
        case "category": CategoryStatsView(records: records)
        case "weekday": WeekdayDistributionView(records: records)
        case "timeOfDay": TimeOfDayView(records: records)
        case "heatmap": HeatmapView(records: records)
        case "monthlyTrend": MonthlyTrendView(records: records)
        default: EmptyView()
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    basicStats
                    rewardStats
                    recordsTimeline
                    savedAmountEntry
                    
                    if storeManager.isVip {
                        vipContent
                    } else {
                        vipLockView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("统计")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if storeManager.isVip {
                            exportSnapshot()
                        } else {
                            showVipAlert = true
                        }
                    } label: {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting || records.isEmpty)
                }
            }
            .alert("解锁高级功能", isPresented: $showVipAlert) {
                Button(statsVipTitle) {
                    Task {
                        _ = await storeManager.purchase()
                    }
                }
                Button("暂不需要", role: .cancel) { }
            } message: {
                Text("该功能为会员专属，解锁后可永久使用分类分析、热力图、月度趋势等高级统计功能")
            }
            .sheet(isPresented: $showExportSheet) {
                if let img = exportImage {
                    ShareSheet(image: img)
                }
            }
        }
    }

    // MARK: - 奖励统计
    private var rewardStats: some View {
        NavigationLink {
            RewardStatsView()
        } label: {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(Color.brand)
                    Text("奖励统计")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    RewardStatBox(
                        title: "累计忍币",
                        value: "\(allCoinRecords.reduce(0) { $0 + $1.coins })",
                        icon: "bitcoinsign.circle.fill",
                        color: .brand
                    )
                    RewardStatBox(
                        title: "已解锁",
                        value: "\(allRewards.filter { $0.status == .unlocked }.count)",
                        icon: "lock.open.fill",
                        color: .orange
                    )
                    RewardStatBox(
                        title: "已兑现",
                        value: "\(allRewards.filter { $0.status == .redeemed }.count)",
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                    RewardStatBox(
                        title: "进行中",
                        value: "\(allRewards.filter { $0.status == .inProgress }.count)",
                        icon: "clock.fill",
                        color: .blue
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var recordsTimeline: some View {
        NavigationLink {
            RecordsListView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("全部记录")
                        .font(.subheadline.weight(.medium))
                    if records.isEmpty {
                        Text("暂无记录")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("共 \(records.count) 条忍住记录")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.secondarySystemGroupedBackground)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    private var basicStats: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                BasicStatBox(title: "累计忍住", value: "\(appState.totalCount(from: records))", unit: "次", color: Color.brand)
                BasicStatBox(title: "今年", value: "\(appState.thisYearCount(from: records))", unit: "次", color: .indigo)
                BasicStatBox(title: "本月", value: "\(appState.thisMonthCount(from: records))", unit: "次", color: .purple)
            }
            HStack(spacing: 10) {
                BasicStatBox(title: "今天", value: "\(appState.todayCount(from: records))", unit: "次", color: .green)
                BasicStatBox(title: "连续记录", value: "\(appState.streakDays(from: records))", unit: "天", color: .orange)
                BasicStatBox(title: "最长连续", value: "\(appState.bestStreak(from: records))", unit: "天", color: .red)
            }
        }
    }
    
    private var vipContent: some View {
        VStack(spacing: 20) {
            ForEach(orderedModules, id: \.self) { moduleId in
                moduleView(for: moduleId)
            }

            // 排序按钮
            Button {
                showSortSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("排序")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.secondarySystemGroupedBackground)
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showSortSheet) {
            StatsSortSheet(modules: orderedModules, onSave: saveModuleOrder)
        }
    }
    
    
    private var savedAmountEntry: some View {
        NavigationLink {
            SavedAmountStatsView(records: records)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "banknote.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("节省统计")
                        .font(.subheadline.weight(.medium))
                    if appState.totalSavedAmount(from: records) > 0 {
                        Text("累计节省 \(savedAmountSummary)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("多维度节省金额分析")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.secondarySystemGroupedBackground)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var savedAmountSummary: String {
        let symbol = SupportedCurrency(rawValue: currencyCode)?.symbol ?? SupportedCurrency.systemSymbol
        let total = appState.totalSavedAmount(from: records)
        if total.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(symbol)\(Int(total))"
        }
        return "\(symbol)\(String(format: "%.1f", total))"
    }

    private var vipLockView: some View {
        VStack(spacing: 20) {
            // 真实数据模糊预览
            blurPreviewCard
            
            // 功能亮点卡片
            featureHighlights
            
            // 升级 CTA
            upgradeCTA
        }
    }
    
    // MARK: - 数据模糊预览
    private var blurPreviewCard: some View {
        VStack(spacing: 16) {
            // 热力图预览（模糊）
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.brand)
                    Text("热力图")
                        .font(.headline)
                    Spacer()
                }
                
                // 生成模拟热力图格子
                let cellSize: CGFloat = 14
                let cellSpacing: CGFloat = 3
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: 12),
                    spacing: cellSpacing
                ) {
                    ForEach(0..<84, id: \.self) { index in
                        let level = [0, 0, 1, 2, 0, 3, 1, 0, 0, 2, 1, 0, 3, 2, 0, 1, 0, 0, 2, 3, 1, 0, 0, 1, 2, 0, 3, 1]
                        let l = level[index % level.count]
                        RoundedRectangle(cornerRadius: 2)
                            .fill(l == 0 ? Color.systemGray5 : Color.brand.opacity(Double(l) * 0.25))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondarySystemGroupedBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.systemBackground.opacity(0.6))
            )
            .blur(radius: 3)
            .allowsHitTesting(false)
            
            // 分类统计预览（模糊）
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .foregroundStyle(Color.brand)
                    Text("分类统计")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    ForEach([0.65, 0.4, 0.25], id: \.self) { pct in
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.brand.opacity(0.15))
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.brand)
                                        .frame(width: geo.size.width * pct)
                                }
                        }
                        .frame(height: 8)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondarySystemGroupedBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.systemBackground.opacity(0.6))
            )
            .blur(radius: 3)
            .allowsHitTesting(false)
            
            // 月度趋势预览（模糊）
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Color.brand)
                    Text("月度趋势")
                        .font(.headline)
                    Spacer()
                }
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach([0.3, 0.5, 0.4, 0.7, 0.6, 0.9], id: \.self) { pct in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.brand)
                            .frame(width: 28, height: max(CGFloat(pct) * 80, 4))
                    }
                }
                .frame(height: 90)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondarySystemGroupedBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.systemBackground.opacity(0.6))
            )
            .blur(radius: 3)
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - 功能亮点
    private var featureHighlights: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                highlightItem(icon: "calendar.badge.clock", title: "周几分布", color: .pink)
                highlightItem(icon: "calendar", title: "热力图", color: .orange)
            }
            HStack(spacing: 12) {
                highlightItem(icon: "chart.line.uptrend.xyaxis", title: "月度趋势", color: .blue)
                highlightItem(icon: "clock.badge.fill", title: "时段分析", color: .purple)
            }
            HStack(spacing: 12) {
                highlightItem(icon: "chart.pie.fill", title: "分类分析", color: .brand)
            }
        }
    }
    
    private func highlightItem(icon: String, title: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
    
    // MARK: - 升级 CTA
    private var upgradeCTA: some View {
        Button {
            Task {
                _ = await storeManager.purchase()
                if storeManager.purchaseState == .failed {
                    showVipAlert = true
                }
            }
        } label: {
            if storeManager.purchaseState == .purchasing {
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                        Text(String(localized: "支付中…"))
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Text(String(localized: "请稍候"))
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
                    Text("解锁全部高级统计")
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
                .shadow(color: Color.brand.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
        .buttonStyle(.plain)
    }

    private var statsVipTitle: String {
        storeManager.displayPrice.isEmpty
            ? String(localized: "解锁终身会员")
            : String(localized: "解锁终身会员") + "(" + storeManager.displayPrice + ")"
    }

    // MARK: - 导出快照
    @MainActor
    private func exportSnapshot() {
        isExporting = true
        let snapshot = StatsSnapshotView(
            records: records,
            appState: appState,
            currencyCode: currencyCode
        )
        let renderer = ImageRenderer(content: snapshot)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            exportImage = uiImage
            showExportSheet = true
        }
        isExporting = false
    }
}

struct BasicStatBox: View {
    let title: LocalizedStringKey
    let value: String
    let unit: LocalizedStringKey
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }
}

struct RewardStatBox: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
}

// MARK: - 系统分享面板
struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - 统计模块排序 Sheet
struct StatsSortSheet: View {
    let modules: [String]
    let onSave: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var items: [String] = []

    private let moduleInfo: [String: (icon: String, name: LocalizedStringKey)] = [
        "category": ("chart.pie.fill", "分类统计"),
        "weekday": ("calendar.badge.clock", "周几分布"),
        "timeOfDay": ("clock.badge.fill", "时段分析"),
        "heatmap": ("calendar", "热力图"),
        "monthlyTrend": ("chart.line.uptrend.xyaxis", "月度趋势"),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items, id: \.self) { moduleId in
                    HStack(spacing: 12) {
                        Image(systemName: moduleInfo[moduleId]?.icon ?? "square")
                            .foregroundStyle(Color.brand)
                            .frame(width: 24)
                        Text(moduleInfo[moduleId]?.name ?? LocalizedStringKey(moduleId))
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
                .onMove { from, to in
                    items.move(fromOffsets: from, toOffset: to)
                }
            }
            .navigationTitle("模块排序")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        onSave(items)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            items = modules
        }
    }
}
