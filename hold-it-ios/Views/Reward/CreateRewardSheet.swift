//
//  CreateRewardSheet.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData
import PhotosUI

struct CreateRewardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.createdAt) private var customCategories: [CustomCategory]

    var editingReward: Reward?

    // 表单字段
    @State private var title: String = ""
    @State private var rewardDescription: String = ""
    @State private var targetCoinsText: String = ""
    @State private var selectedCategoryIDs: Set<String> = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?

    private var isEditing: Bool { editingReward != nil }

    private var canSave: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        guard let target = Int(targetCoinsText), target > 0 else { return false }
        guard !selectedCategoryIDs.isEmpty else { return false }
        return true
    }

    private var allCategories: [ResistCategory] {
        ResistCategory.defaults + customCategories.map { ResistCategory(from: $0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                // 图片选择
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let data = imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.brand.opacity(0.12))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundStyle(Color.brand)
                                    )
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("奖励图片")
                                    .font(.subheadline.weight(.medium))
                                Text("选填，从相册选择")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if imageData != nil {
                        Button(String(localized: "移除图片"), role: .destructive) {
                            imageData = nil
                            selectedPhoto = nil
                        }
                        .font(.caption)
                    }
                }

                // 基本信息
                Section("基本信息") {
                    TextField(String(localized: "奖励名称（必填）"), text: $title)
                    TextField(String(localized: "奖励描述（选填）"), text: $rewardDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                // 所需忍币
                Section("所需忍币") {
                    TextField(String(localized: "目标忍币数量"), text: $targetCoinsText)
                        .keyboardType(.numberPad)
                }

                // 关联克制项
                Section {
                    ForEach(allCategories) { category in
                        Button {
                            toggleCategory(category.stableID)
                        } label: {
                            HStack {
                                Text(category.emoji)
                                    .font(.title2)
                                Text(LocalizedStringKey(category.name))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedCategoryIDs.contains(category.stableID) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brand)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("关联克制项")
                } footer: {
                    Text("每次记录关联的克制项时，该奖励自动获得 1 忍币")
                }
            }
            .navigationTitle(isEditing ? String(localized: "编辑奖励") : String(localized: "新建奖励"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? String(localized: "保存") : String(localized: "创建")) { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let item = newValue {
                        imageData = try? await item.loadTransferable(type: Data.self)
                    }
                }
            }
            .onAppear {
                if let reward = editingReward {
                    title = reward.title
                    rewardDescription = reward.rewardDescription
                    targetCoinsText = "\(reward.targetCoins)"
                    selectedCategoryIDs = Set(reward.categoryIDs)
                    imageData = reward.imageData
                }
            }
        }
    }

    private func toggleCategory(_ id: String) {
        if selectedCategoryIDs.contains(id) {
            selectedCategoryIDs.remove(id)
        } else {
            selectedCategoryIDs.insert(id)
        }
    }

    private func save() {
        guard let target = Int(targetCoinsText), target > 0 else { return }

        if let reward = editingReward {
            reward.title = title.trimmingCharacters(in: .whitespaces)
            reward.rewardDescription = rewardDescription.trimmingCharacters(in: .whitespaces)
            reward.targetCoins = target
            reward.categoryIDs = Array(selectedCategoryIDs)
            reward.imageData = imageData
        } else {
            let reward = Reward(
                title: title.trimmingCharacters(in: .whitespaces),
                rewardDescription: rewardDescription.trimmingCharacters(in: .whitespaces),
                imageData: imageData,
                targetCoins: target,
                categoryIDs: Array(selectedCategoryIDs)
            )
            modelContext.insert(reward)
        }
        dismiss()
    }
}
