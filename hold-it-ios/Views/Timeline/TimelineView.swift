//
//  TimelineView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    
    var groupedRecords: [(String, [ResistRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            if calendar.isDateInToday(record.createdAt) {
                return String(localized: "今天")
            } else if calendar.isDateInYesterday(record.createdAt) {
                return String(localized: "昨天")
            } else {
                let formatter = DateFormatter()
                formatter.locale = .current
                formatter.setLocalizedDateFormatFromTemplate("Md")
                return formatter.string(from: record.createdAt)
            }
        }
        return grouped.sorted { pair1, pair2 in
            let date1 = pair1.value.first?.createdAt ?? Date()
            let date2 = pair2.value.first?.createdAt ?? Date()
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("暂无记录", systemImage: "doc.text")
                        } description: {
                            Text("去首页记录你的第一次忍住吧")
                        }
                    }
                } else {
                    ForEach(groupedRecords, id: \.0) { date, dayRecords in
                        Section {
                            ForEach(dayRecords) { record in
                                TimelineRow(record: record)
                            }
                        } header: {
                            Text(date)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.systemGroupedBackground)
            .navigationTitle("时间线")
        }
    }
}

// MARK: - 统计页导航过来的记录列表页
struct RecordsListView: View {
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]

    // MARK: - 筛选状态
    enum TimeFilter: String, CaseIterable {
        case all = "全部"
        case today = "今天"
        case week = "本周"
        case month = "本月"
        case year = "今年"
    }

    var initialFilter: TimeFilter
    @State private var timeFilter: TimeFilter = .all
    @State private var selectedCategory: String? = nil

    init(initialFilter: TimeFilter = .all) {
        self.initialFilter = initialFilter
    }

    // MARK: - 计算属性

    /// 所有出现过的分类（按 categoryID 去重）
    var availableCategories: [(emoji: String, name: String, id: String)] {
        var seen = Set<String>()
        var result: [(String, String, String)] = []
        for r in records where !seen.contains(r.effectiveCategoryID) {
            seen.insert(r.effectiveCategoryID)
            result.append((r.categoryEmoji, r.category, r.effectiveCategoryID))
        }
        return result
    }

    var filteredRecords: [ResistRecord] {
        let calendar = Calendar.current
        return records.filter { record in
            // 时间筛选
            let passTime: Bool
            switch timeFilter {
            case .all:   passTime = true
            case .today: passTime = calendar.isDateInToday(record.createdAt)
            case .week:
                if let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start {
                    passTime = record.createdAt >= start
                } else { passTime = false }
            case .month:
                if let start = calendar.dateInterval(of: .month, for: Date())?.start {
                    passTime = record.createdAt >= start
                } else { passTime = false }
            case .year:
                if let start = calendar.dateInterval(of: .year, for: Date())?.start {
                    passTime = record.createdAt >= start
                } else { passTime = false }
            }
            // 分类筛选
            let passCategory = selectedCategory == nil || record.effectiveCategoryID == selectedCategory
            return passTime && passCategory
        }
    }

    var groupedRecords: [(String, [ResistRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredRecords) { record in
            if calendar.isDateInToday(record.createdAt) {
                return String(localized: "今天")
            } else if calendar.isDateInYesterday(record.createdAt) {
                return String(localized: "昨天")
            } else {
                let formatter = DateFormatter()
                formatter.locale = .current
                formatter.setLocalizedDateFormatFromTemplate("Md")
                return formatter.string(from: record.createdAt)
            }
        }
        return grouped.sorted { a, b in
            (a.value.first?.createdAt ?? Date()) > (b.value.first?.createdAt ?? Date())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 时间筛选 Picker
            Picker("时间", selection: $timeFilter) {
                ForEach(TimeFilter.allCases, id: \.self) { f in
                    Text(LocalizedStringKey(f.rawValue)).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.systemGroupedBackground)

            // 分类筛选 Chips
            if !availableCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // 「全部」chip
                        FilterChip(
                            label: String(localized: "全部"),
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        ForEach(availableCategories, id: \.id) { cat in
                            FilterChip(
                                label: "\(cat.emoji) \(cat.name)",
                                isSelected: selectedCategory == cat.id
                            ) {
                                selectedCategory = selectedCategory == cat.id ? nil : cat.id
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color.systemGroupedBackground)
            }

            Divider()

            // 记录列表
            List {
                if filteredRecords.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("暂无记录", systemImage: "doc.text")
                        } description: {
                            Text(selectedCategory != nil || timeFilter != .all
                                 ? "换个筛选条件试试"
                                 : "去首页记录你的第一次忍住吧")
                        }
                    }
                } else {
                    ForEach(groupedRecords, id: \.0) { date, dayRecords in
                        Section {
                            ForEach(dayRecords) { record in
                                TimelineRow(record: record)
                            }
                        } header: {
                            Text(date)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Color.systemGroupedBackground)
        .navigationTitle("全部记录")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if timeFilter != initialFilter {
                timeFilter = initialFilter
            }
        }
        .toolbar {
            if selectedCategory != nil || timeFilter != .all {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("重置") {
                        timeFilter = .all
                        selectedCategory = nil
                    }
                    .font(.subheadline)
                }
            }
        }
    }
}

// MARK: - 筛选 Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.brand : Color.secondarySystemGroupedBackground)
                .foregroundStyle(isSelected ? Color.brandDark : Color.primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct TimelineRow: View {
    let record: ResistRecord
    @AppStorage("currencyCode") private var currencyCode: String = "auto"

    private var currencySymbol: String {
        SupportedCurrency(rawValue: currencyCode)?.symbol ?? SupportedCurrency.systemSymbol
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Text(record.categoryEmoji)
                .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(LocalizedStringKey(record.category))
                        .font(.subheadline.weight(.medium))
                    
                    if let amount = record.amount {
                        Text("省 \(currencySymbol)\(Int(amount))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12))
                            .foregroundStyle(.green)
                            .cornerRadius(4)
                    }
                }
                
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text(timeString(from: record.createdAt))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 节省统计页的金额记录列表
struct SavedRecordsListView: View {
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @AppStorage("currencyCode") private var currencyCode: String = "auto"

    private var symbol: String {
        SupportedCurrency(rawValue: currencyCode)?.symbol ?? SupportedCurrency.systemSymbol
    }

    // MARK: - 筛选状态
    enum TimeFilter: String, CaseIterable {
        case all = "全部"
        case today = "今天"
        case week = "本周"
        case month = "本月"
        case year = "今年"
    }

    var initialFilter: TimeFilter = .all
    @State private var timeFilter: TimeFilter = .all
    @State private var selectedCategory: String? = nil

    init(initialFilter: TimeFilter = .all) {
        self.initialFilter = initialFilter
    }

    /// 只有金额的记录
    private var amountRecords: [ResistRecord] {
        records.filter { $0.amount != nil }
    }

    /// 所有出现过的分类（仅含金额记录）
    private var availableCategories: [(emoji: String, name: String, id: String)] {
        var seen = Set<String>()
        var result: [(String, String, String)] = []
        for r in amountRecords where !seen.contains(r.effectiveCategoryID) {
            seen.insert(r.effectiveCategoryID)
            result.append((r.categoryEmoji, r.category, r.effectiveCategoryID))
        }
        return result
    }

    private var filteredRecords: [ResistRecord] {
        let calendar = Calendar.current
        return amountRecords.filter { record in
            // 时间筛选
            let passTime: Bool
            switch timeFilter {
            case .all:   passTime = true
            case .today: passTime = calendar.isDateInToday(record.createdAt)
            case .week:
                if let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start {
                    passTime = record.createdAt >= start
                } else { passTime = false }
            case .month:
                if let start = calendar.dateInterval(of: .month, for: Date())?.start {
                    passTime = record.createdAt >= start
                } else { passTime = false }
            case .year:
                if let start = calendar.dateInterval(of: .year, for: Date())?.start {
                    passTime = record.createdAt >= start
                } else { passTime = false }
            }
            // 分类筛选
            let passCategory = selectedCategory == nil || record.effectiveCategoryID == selectedCategory
            return passTime && passCategory
        }
    }

    private var filteredTotal: Double {
        filteredRecords.compactMap { $0.amount }.reduce(0, +)
    }

    private var groupedRecords: [(String, [ResistRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredRecords) { record in
            if calendar.isDateInToday(record.createdAt) {
                return String(localized: "今天")
            } else if calendar.isDateInYesterday(record.createdAt) {
                return String(localized: "昨天")
            } else {
                let formatter = DateFormatter()
                formatter.locale = .current
                formatter.setLocalizedDateFormatFromTemplate("Md")
                return formatter.string(from: record.createdAt)
            }
        }
        return grouped.sorted { a, b in
            (a.value.first?.createdAt ?? Date()) > (b.value.first?.createdAt ?? Date())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 时间筛选 Picker
            Picker("时间", selection: $timeFilter) {
                ForEach(TimeFilter.allCases, id: \.self) { f in
                    Text(LocalizedStringKey(f.rawValue)).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.systemGroupedBackground)

            // 分类筛选 Chips
            if !availableCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            label: String(localized: "全部"),
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        ForEach(availableCategories, id: \.id) { cat in
                            FilterChip(
                                label: "\(cat.emoji) \(cat.name)",
                                isSelected: selectedCategory == cat.id
                            ) {
                                selectedCategory = selectedCategory == cat.id ? nil : cat.id
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color.systemGroupedBackground)
            }

            // 汇总条
            if !filteredRecords.isEmpty {
                HStack {
                    Text("\(filteredRecords.count) 条记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("合计 \(symbol)\(formatAmount(filteredTotal))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.systemGroupedBackground)
            }

            Divider()

            // 记录列表
            List {
                if filteredRecords.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("暂无金额记录", systemImage: "banknote")
                        } description: {
                            Text("记录忍住项时填写金额即可查看")
                        }
                    }
                } else {
                    ForEach(groupedRecords, id: \.0) { date, dayRecords in
                        Section {
                            ForEach(dayRecords) { record in
                                SavedRecordRow(record: record)
                            }
                        } header: {
                            Text(date)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Color.systemGroupedBackground)
        .navigationTitle("节省记录")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if timeFilter != initialFilter {
                timeFilter = initialFilter
            }
        }
        .toolbar {
            if selectedCategory != nil || timeFilter != .all {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("重置") {
                        timeFilter = .all
                        selectedCategory = nil
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private func formatAmount(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - 金额记录行
struct SavedRecordRow: View {
    let record: ResistRecord
    @AppStorage("currencyCode") private var currencyCode: String = "auto"

    private var symbol: String {
        SupportedCurrency(rawValue: currencyCode)?.symbol ?? SupportedCurrency.systemSymbol
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(record.categoryEmoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(record.category))
                    .font(.subheadline.weight(.medium))

                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let amount = record.amount {
                Text("省 \(symbol)\(Int(amount))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
