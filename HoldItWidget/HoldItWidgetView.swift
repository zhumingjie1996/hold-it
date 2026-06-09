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
            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(String(localized: "忍一下"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }

            Spacer(minLength: 0)

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
        HStack(spacing: 12) {
            // 左侧：今日忍住绿色卡片
            VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(String(localized: "忍一下"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 2) {
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
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // 右侧：连续天数 + 累计节省
            VStack(alignment: .leading, spacing: 10) {
                // 连续天数卡片
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "连续天数"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(entry.stats.streakDays)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(brand)
                        Text(String(localized: "天"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // 累计节省卡片
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "累计节省"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(entry.stats.totalSaved > 0
                        ? "\(entry.stats.currencySymbol)\(formatAmount(entry.stats.totalSaved))"
                        : "—")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .frame(maxWidth: .infinity)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 品牌标题
            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(String(localized: "忍一下"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }

            // 模块一：次数统计
            largeSection(title: String(localized: "忍住次数")) {
                HStack(spacing: 0) {
                    largePill(label: String(localized: "今日"), value: "\(entry.stats.todayCount)", unit: String(localized: "次"), highlight: true)
                    largeDivider()
                    largePill(label: String(localized: "本周"), value: "\(entry.stats.weekCount)", unit: String(localized: "次"))
                    largeDivider()
                    largePill(label: String(localized: "本月"), value: "\(entry.stats.monthCount)", unit: String(localized: "次"))
                    largeDivider()
                    largePill(label: String(localized: "累计"), value: "\(entry.stats.totalCount)", unit: String(localized: "次"))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // 模块二：连续记录
            largeSection(title: String(localized: "连续天数")) {
                HStack(spacing: 0) {
                    largePill(label: String(localized: "当前"), value: "\(entry.stats.streakDays)", unit: String(localized: "天"), highlight: true)
                    largeDivider()
                    largePill(label: String(localized: "最长"), value: "\(entry.stats.bestStreak)", unit: String(localized: "天"))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // 模块三：节省（有数据才展示）
            if entry.stats.totalSaved > 0 {
                largeSection(title: String(localized: "累计节省")) {
                    HStack(spacing: 0) {
                        largePill(label: String(localized: "金额"), value: "\(entry.stats.currencySymbol)\(formatAmount(entry.stats.totalSaved))", unit: "", highlight: true)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 10)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func largePill(label: String, value: String, unit: String, highlight: Bool = false) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(highlight ? brand : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func largeDivider() -> some View {
        Rectangle()
            .fill(Color(UIColor.separator).opacity(0.4))
            .frame(width: 0.5)
            .padding(.vertical, 4)
    }

    private func largeSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 2)
            content()
        }
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
