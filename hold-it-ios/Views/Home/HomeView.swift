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
    @State private var showCelebration = false
    @State private var carouselIndex: Int = 0
    @State private var carouselTask: Task<Void, Never>?
    @State private var logoRotation: Double = 12
    @State private var logoScale: CGFloat = 1.0
    @State private var logoTapLocked = false
    @State private var logoIdleTask: Task<Void, Never>?

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    statsCards
                    lastRecordCard
                    mainButton
                    encourageCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("忍一下")
            .sheet(isPresented: $showRecordSheet) {
                RecordSheet(onSave: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    showCelebration = true
                })
            }
            .overlay {
                if showCelebration {
                    CelebrationView(isActive: $showCelebration)
                }
            }
        }
    }
    
    private var statsCards: some View {
        HStack(spacing: 12) {
            NavigationLink {
                RecordsListView(initialFilter: .today)
            } label: {
                StatCard(
                    title: "今天已忍住",
                    value: "\(appState.todayCount(from: records))",
                    unit: "次",
                    icon: "checkmark.circle.fill",
                    color: .brand,
                    showArrow: true
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)

            NavigationLink {
                SavedRecordsListView(initialFilter: .today)
            } label: {
                StatCard(
                    title: "今天已节省",
                    value: todaySavedSummary,
                    unit: "元",
                    icon: "banknote.fill",
                    color: .green,
                    showArrow: true
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 最近忍住轮播
    private var lastRecordCard: some View {
        Group {
            if !records.isEmpty {
                let record = records[carouselIndex % records.count]
                HStack(spacing: 12) {
                    Text(record.categoryEmoji)
                        .font(.title)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.category)
                            .font(.subheadline.weight(.medium))
                        HStack(spacing: 4) {
                            Text(relativeTimeString(from: record.createdAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let amount = record.amount, amount > 0 {
                                Text("·")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(savedAmountText(amount))
                                    .font(.caption)
                                    .foregroundStyle(Color.brand)
                            }
                        }
                        if !record.note.isEmpty {
                            Text(record.note)
                                .font(.caption)
                                .foregroundStyle(.secondary.opacity(0.8))
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(Color.brand)
                }
                .padding(16)
                .background(Color.secondarySystemGroupedBackground)
                .cornerRadius(16)
                .id(carouselIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.4), value: carouselIndex)
            }
        }
        .onAppear {
            startCarousel()
        }
        .onChange(of: records.count) { _, _ in
            // 新增记录时重置轮播
            carouselIndex = 0
            startCarousel()
        }
    }

    private func startCarousel() {
        carouselTask?.cancel()
        guard records.count > 1 else { return }
        carouselTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                withAnimation {
                    carouselIndex = (carouselIndex + 1) % records.count
                }
            }
        }
    }

    // MARK: - Logo 摇动动画
    private func wiggleLogo() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
            logoRotation = -8
            logoScale = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                logoRotation = 12
                logoScale = 1.0
            }
        }
    }

    private func startLogoIdleAnimation() {
        logoIdleTask?.cancel()
        logoIdleTask = Task {
            while !Task.isCancelled {
                // 随机间隔 8~15 秒
                let interval = Double.random(in: 8...15)
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { return }
                guard !logoTapLocked else { continue }
                wiggleLogo()
            }
        }
    }

    // MARK: - 鼓励卡片
    private var encourageCard: some View {
        let quote = EncourageQuote.allQuotes[currentQuoteIndex]
        return ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
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

            // 贴纸 Logo
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.15), radius: 3, x: 1, y: 2)
                .rotationEffect(.degrees(logoRotation))
                .scaleEffect(logoScale)
                .offset(x: 15, y: -25)
                .onTapGesture {
                    guard !logoTapLocked else { return }
                    logoTapLocked = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    wiggleLogo()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentQuoteIndex = EncourageQuote.randomIndex(excluding: currentQuoteIndex)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        logoTapLocked = false
                    }
                }
                .onAppear { startLogoIdleAnimation() }
                .onDisappear { logoIdleTask?.cancel() }
        }
    }
    
    private var mainButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showRecordSheet = true
        } label: {
            ZStack {
                // 外层光晕
                Circle()
                    .fill(Color.brand.opacity(0.12))
                    .frame(width: 220, height: 220)

                // 主圆
                Circle()
                    .fill(Color.brand)
                    .frame(width: 180, height: 180)
                    .shadow(color: Color.brand.opacity(0.3), radius: 20, x: 0, y: 10)

                VStack(spacing: 4) {
                    Text("忍一下")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.brandDark)
                    Text("点击记录")
                        .font(.caption)
                        .foregroundStyle(Color.brandDark.opacity(0.75))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 20)
    }

    // MARK: - 辅助方法
    private func relativeTimeString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return String(localized: "刚刚")
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var todaySavedSummary: String {
        savedAmountText(appState.todaySavedAmount(from: records))
    }

    private func savedAmountText(_ amount: Double) -> String {
        let currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "auto"
        let symbol = SupportedCurrency(rawValue: currencyCode)?.symbol ?? SupportedCurrency.systemSymbol
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(symbol)\(Int(amount))"
        }
        return "\(symbol)\(String(format: "%.1f", amount))"
    }
}

struct StatCard: View {
    let title: LocalizedStringKey
    let value: String
    let unit: LocalizedStringKey
    let icon: String
    let color: Color
    var showArrow: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
            
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
