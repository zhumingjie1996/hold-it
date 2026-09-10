//
//  CategoryManageView.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

/// 克制项管理：自定义忍住项的增删改
struct CategoryManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager

    @Query(sort: \CustomCategory.createdAt) private var customCategories: [CustomCategory]
    @Query private var allRecords: [ResistRecord]

    @State private var showAddSheet = false
    @State private var editingCategory: CustomCategory?
    @State private var deletingCategory: CustomCategory?
    @State private var showDeleteAlert = false
    @State private var showVipAlert = false

    private var deletingRecordCount: Int {
        guard let cat = deletingCategory else { return 0 }
        return allRecords.filter { $0.effectiveCategoryID == cat.id.uuidString }.count
    }

    private var canAddMore: Bool {
        storeManager.isVip || customCategories.count < 3
    }

    var body: some View {
        List {
            if customCategories.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Text("还没有自定义克制项")
                            .font(.subheadline.weight(.medium))
                        Text("点击右上角 + 添加")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(customCategories) { cat in
                        row(for: cat)
                    }
                } footer: {
                    if !storeManager.isVip {
                        Text("非会员最多添加3个自定义忍住项，解锁后可无限添加。")
                    }
                }
            }
        }
        .navigationTitle("克制项管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if canAddMore {
                        showAddSheet = true
                    } else {
                        showVipAlert = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCategorySheet()
        }
        .sheet(item: $editingCategory) { cat in
            AddCategorySheet(editingCategory: cat)
        }
        .alert("删除忍住项", isPresented: $showDeleteAlert) {
            if deletingRecordCount > 0 {
                Button("删除项目和 \(deletingRecordCount) 条记录", role: .destructive) {
                    performDelete(includingRecords: true)
                }
                Button("仅删除项目") {
                    performDelete(includingRecords: false)
                }
            } else {
                Button("删除", role: .destructive) {
                    performDelete(includingRecords: false)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            if let cat = deletingCategory {
                if deletingRecordCount > 0 {
                    Text("「\(cat.name)」已有 \(deletingRecordCount) 条记录。删除记录后无法恢复，相关奖励的忍币进度也会相应减少。")
                } else {
                    Text("确定删除「\(cat.name)」吗？")
                }
            }
        }
        .alert("解锁更多自定义", isPresented: $showVipAlert) {
            Button(vipAlertPurchaseTitle) {
                Task { _ = await storeManager.purchase() }
            }
            Button("暂不需要", role: .cancel) { }
        } message: {
            Text("非会员最多添加3个自定义忍住项，解锁后可无限添加。")
        }
    }

    private func row(for cat: CustomCategory) -> some View {
        let recordCount = allRecords.filter { $0.effectiveCategoryID == cat.id.uuidString }.count
        return Button {
            editingCategory = cat
        } label: {
            HStack(spacing: 12) {
                Text(cat.emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cat.name)
                        .foregroundStyle(.primary)
                    Text("\(recordCount) 条记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deletingCategory = cat
                showDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private var vipAlertPurchaseTitle: String {
        storeManager.displayPrice.isEmpty
            ? String(localized: "解锁终身会员")
            : String(localized: "解锁终身会员") + " (" + storeManager.displayPrice + ")"
    }

    private func performDelete(includingRecords: Bool) {
        guard let cat = deletingCategory else { return }
        modelContext.deleteCustomCategory(cat, includingRecords: includingRecords, allRecords: allRecords)
        deletingCategory = nil
    }
}
