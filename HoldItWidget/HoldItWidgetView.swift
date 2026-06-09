//
//  HoldItWidgetView.swift
//  HoldItWidget
//

import SwiftUI
import WidgetKit
import UIKit

struct HoldItWidgetView: View {
    var entry: HoldItEntry
    @Environment(\.widgetFamily) var family

    // MARK: - Colors

    private var brand: Color {
        Color(.sRGB, red: 106/255, green: 216/255, blue: 108/255, opacity: 1)
    }
    private var brandGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.sRGB, red: 118/255, green: 224/255, blue: 120/255, opacity: 1),
                Color(.sRGB, red: 72/255, green: 188/255, blue: 74/255, opacity: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        switch family {
        case .systemLarge:
            largeWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App 名称
            HStack(spacing: 5) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .opacity(0.9)
                Text(String(localized: "忍一下"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer(minLength: 0)

            // 核心数据：今日忍住
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "今日忍住"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(entry.stats.todayCount)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(String(localized: "次"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(brandGradient, for: .widget)
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // 左侧：品牌 + 今日核心
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 5) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .opacity(0.85)
                    Text(String(localized: "忍一下"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 3) {
                    Text(String(localized: "今日忍住"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(entry.stats.todayCount)")
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text(String(localized: "次"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }

                Spacer(minLength: 8)

                // 连续天数
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("\(entry.stats.streakDays)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(String(localized: "天连续"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // 右侧：两个指标
            VStack(spacing: 12) {
                mediumStatItem(
                    icon: "checkmark.circle.fill",
                    iconColor: brand,
                    value: "\(entry.stats.totalCount)",
                    unit: String(localized: "次"),
                    label: String(localized: "累计忍住")
                )

                Divider()
                    .padding(.horizontal, 2)

                mediumStatItem(
                    icon: "banknote.fill",
                    iconColor: .green,
                    value: entry.stats.totalSaved > 0
                        ? "\(entry.stats.currencySymbol)\(formatAmount(entry.stats.totalSaved))"
                        : "—",
                    unit: "",
                    label: String(localized: "累计节省")
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(0)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func mediumStatItem(
        icon: String,
        iconColor: Color,
        value: String,
        unit: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        VStack(spacing: 12) {
            // 顶部品牌栏
            HStack {
                HStack(spacing: 5) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    Text(String(localized: "忍一下"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                // 连续天数
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text("\(entry.stats.streakDays)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(String(localized: "天连续"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            // 今日忍住 - 大卡片
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "今日忍住"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(entry.stats.todayCount)")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text(String(localized: "次"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // 三列统计
            HStack(spacing: 10) {
                largeStatBox(
                    icon: "checkmark.circle.fill",
                    iconColor: brand,
                    value: "\(entry.stats.totalCount)",
                    unit: String(localized: "次"),
                    label: String(localized: "累计忍住")
                )

                largeStatBox(
                    icon: "banknote.fill",
                    iconColor: .green,
                    value: entry.stats.totalSaved > 0
                        ? "\(entry.stats.currencySymbol)\(formatAmount(entry.stats.totalSaved))"
                        : "—",
                    unit: "",
                    label: String(localized: "累计节省")
                )

                largeStatBox(
                    icon: "calendar",
                    iconColor: .blue,
                    value: "\(entry.stats.streakDays)",
                    unit: String(localized: "天"),
                    label: String(localized: "连续记录")
                )
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func largeStatBox(
        icon: String,
        iconColor: Color,
        value: String,
        unit: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Helpers

    private func formatAmount(_ amount: Double) -> String {
        if amount >= 10000 {
            return String(format: "%.1fw", amount / 10000)
        }
        let intVal = Int(amount)
        if Double(intVal) == amount {
            return "\(intVal)"
        }
        return String(format: "%.1f", amount)
    }
}
