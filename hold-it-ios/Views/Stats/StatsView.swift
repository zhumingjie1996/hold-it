//
//  StatsView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var storeManager
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    basicStats
                    recordsTimeline
                    
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
        }
    }

    private var recordsTimeline: some View {
        NavigationLink {
            RecordsListView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("全部记录")
                        .font(.subheadline.weight(.medium))
                    Text(records.isEmpty ? "暂无记录" : "共 \(records.count) 条克制记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        HStack(spacing: 12) {
            BasicStatBox(
                title: "累计忍住",
                value: "\(appState.totalCount(from: records))",
                unit: "次",
                color: .brand
            )
            BasicStatBox(
                title: "今天",
                value: "\(appState.todayCount(from: records))",
                unit: "次",
                color: .green
            )
            BasicStatBox(
                title: "连续记录",
                value: "\(appState.streakDays(from: records))",
                unit: "天",
                color: .orange
            )
        }
    }
    
    private var vipContent: some View {
        VStack(spacing: 20) {
            CategoryStatsView(records: records)
            HeatmapView(records: records)
            MonthlyTrendView(records: records)
            
            if appState.totalSavedAmount(from: records) > 0 {
                savedAmountCard
            }
        }
    }
    
    private var savedAmountCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "banknote.fill")
                    .foregroundStyle(.green)
                Text("累计节省")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("¥")
                    .font(.title3)
                Text(String(format: "%.0f", appState.totalSavedAmount(from: records)))
                    .font(.system(size: 40, weight: .bold))
            }
            .foregroundStyle(.green)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }
    
    private var vipLockView: some View {
        VStack(spacing: 16) {
            lockedFeature(icon: "chart.pie.fill", title: "分类分析", description: "查看每个分类的克制次数")
            lockedFeature(icon: "calendar", title: "热力图", description: "全年克制频率可视化")
            lockedFeature(icon: "chart.line.uptrend.xyaxis", title: "月度趋势", description: "过去6个月的变化趋势")
            lockedFeature(icon: "banknote.fill", title: "节省统计", description: "累计节省金额统计")
            
            Button {
                Task {
                    _ = await storeManager.purchase()
                }
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("解锁终身会员")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.top, 8)
        }
    }
    
    private func lockedFeature(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.systemBackground.opacity(0.4))
        )
    }
}

struct BasicStatBox: View {
    let title: String
    let value: String
    let unit: String
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
