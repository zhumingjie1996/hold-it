//
//  HomeView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @State private var showRecordSheet = false
    @State private var currentQuoteIndex: Int = EncourageQuote.todayIndex()
    @State private var isSpinning = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    statsCards
                    encourageCard
                    mainButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("忍一下")
            .sheet(isPresented: $showRecordSheet) {
                RecordSheet()
            }
        }
    }
    
    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "今天已忍住",
                value: "\(appState.todayCount(from: records))",
                unit: "次",
                icon: "checkmark.circle.fill",
                color: .brand
            )
            StatCard(
                title: "连续记录",
                value: "\(appState.streakDays(from: records))",
                unit: "天",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - 鼓励卡片
    private var encourageCard: some View {
        let quote = EncourageQuote.allQuotes[currentQuoteIndex]
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "quote.opening")
                    .foregroundStyle(Color.brand.opacity(1))
                Text("To Myself")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandDark.opacity(1))
            }
        
            Text(quote)
                .font(.footnote)
                .foregroundStyle(.primary.opacity(0.6))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
        .id(currentQuoteIndex)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    private var mainButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showRecordSheet = true
        } label: {
            ZStack {
                // 外层旋转渐变光环
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.brand,
                                Color.brand.opacity(0.3),
                                Color(.sRGB, red: 31/255, green: 180/255, blue: 42/255),
                                Color.brand.opacity(0.3),
                                Color.brand
                            ]),
                            center: .center
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 1)
                    .shadow(color: .brand.opacity(0.5), radius: 15, x: 0, y: -5)
                    .shadow(color: Color(.sRGB, red: 31/255, green: 180/255, blue: 42/255).opacity(0.5), radius: 15, x: 0, y: 5)
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))

                // 内层遮罩圆（形成环状效果）
                Circle()
                    .fill(Color.systemGroupedBackground)
                    .frame(width: 120, height: 120)
                    .blur(radius: 0.5)

                // 中心内容
                VStack(spacing: 4) {
                    Text("忍一下")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.brandDark)
                    Text("点击记录")
                        .font(.caption)
                        .foregroundStyle(Color.brandDark.opacity(0.75))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 20)
        .onAppear {
            withAnimation(.linear(duration: 1.7).repeatForever(autoreverses: false)) {
                isSpinning = true
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(16)
    }
}

struct RecordRow: View {
    let record: ResistRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Text(record.categoryEmoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.category)
                    .font(.subheadline.weight(.medium))
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(timeString(from: record.createdAt))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
