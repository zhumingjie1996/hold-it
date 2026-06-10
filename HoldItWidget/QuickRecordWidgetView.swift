//
//  QuickRecordWidgetView.swift
//  HoldItWidget
//

import SwiftUI
import WidgetKit

struct QuickRecordWidgetView: View {
    @Environment(\.widgetRenderingMode) var renderingMode

    private var brand: Color {
        Color(.sRGB, red: 106/255, green: 216/255, blue: 108/255, opacity: 1)
    }
    private var brandDark: Color {
        Color(.sRGB, red: 31/255, green: 107/255, blue: 42/255, opacity: 1)
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

    /// 是否处于 Vibrant（Clear）或 Tinted 模式
    private var isVibrantOrTinted: Bool {
        renderingMode == .vibrant || renderingMode == .accented
    }

    var body: some View {
        Link(destination: URL(string: "holdit://record")!) {
            ZStack {
                if isVibrantOrTinted {
                    // Clear/Tinted 模式：描边圆，避免填充色被系统淹没
                    Circle()
                        .strokeBorder(.primary.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 120, height: 120)

                    Circle()
                        .strokeBorder(.primary.opacity(0.5), lineWidth: 2)
                        .frame(width: 96, height: 96)
                } else {
                    // 默认模式：绿色渐变填充圆
                    Circle()
                        .fill(brand.opacity(0.2))
                        .frame(width: 130, height: 130)

                    Circle()
                        .fill(brandGradient)
                        .frame(width: 106, height: 106)
                        .shadow(color: brand.opacity(0.4), radius: 12, x: 0, y: 6)
                }

                // 文字：始终用语义色保证可读性
                VStack(spacing: 4) {
                    Text(String(localized: "忍一下"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(isVibrantOrTinted ? .primary : brandDark)
                    Text(String(localized: "点击记录"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isVibrantOrTinted ? .secondary : brandDark.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
