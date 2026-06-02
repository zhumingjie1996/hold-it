//
//  HomeView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @State private var showRecordSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    statsCards
                    mainButton
                    recentRecords
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
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
                color: .blue
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
    
    private var mainButton: some View {
        Button {
            showRecordSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .scaleEffect(1.2)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: showRecordSheet
                    )
                
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(1.1)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                        .delay(0.3),
                        value: showRecordSheet
                    )
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 160, height: 160)
                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 4) {
                    Text("忍一下")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("点击记录")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 20)
    }
    
    private var recentRecords: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近记录")
                    .font(.headline)
                Spacer()
                if records.count > 3 {
                    Text("共 \(records.count) 条")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if records.isEmpty {
                ContentUnavailableView {
                    Label("暂无记录", systemImage: "doc.text")
                } description: {
                    Text("点击上方按钮，记录你忍住的小事")
                }
                .padding(.vertical, 20)
            } else {
                ForEach(records.prefix(3)) { record in
                    RecordRow(record: record)
                }
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
