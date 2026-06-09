//
//  QuickRecordWidgetView.swift
//  HoldItWidget
//

import SwiftUI
import WidgetKit

struct QuickRecordWidgetView: View {

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

    var body: some View {
        Link(destination: URL(string: "holdit://record")!) {
            ZStack {
                // 外层光晕
                Circle()
                    .fill(brand.opacity(0.25))
                    .frame(width: 130, height: 130)

                // 主圆（渐变）
                Circle()
                    .fill(brandGradient)
                    .frame(width: 106, height: 106)
                    .shadow(color: brand.opacity(0.4), radius: 12, x: 0, y: 6)

                // 文字
                VStack(spacing: 4) {
                    Text(String(localized: "忍一下"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(brandDark)
                    Text(String(localized: "点击记录"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(brandDark.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
