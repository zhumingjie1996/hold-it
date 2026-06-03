//
//  RecordSheet.swift
//  hold-it-ios
//

import SwiftUI
import SwiftData

// MARK: - 记录 Sheet（主入口）
struct RecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode: String = "auto"

    @Query(sort: \CustomCategory.createdAt) private var customCategories: [CustomCategory]

    @State private var selectedCategory: ResistCategory = ResistCategory.defaults[0]
    @State private var note: String = ""
    @State private var amountText: String = ""
    @State private var showSuccess = false
    @State private var showAddCategory = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    /// 默认 + 自定义分类合并
    private var allCategories: [ResistCategory] {
        ResistCategory.defaults + customCategories.map { ResistCategory(from: $0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if showSuccess {
                        successView
                            .frame(minHeight: 400)
                    } else {
                        formContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .navigationTitle("你忍住了什么？")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet()
        }
        .onAppear {
            updateAmountText(for: selectedCategory)
        }
    }

    // MARK: - 表单内容
    private var formContent: some View {
        VStack(spacing: 20) {
            // 分类网格
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(allCategories) { category in
                    CategoryCell(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                            updateAmountText(for: category)
                        }
                    }
                }
                // "+" 新增按钮
                addCategoryCell
            }

            // 金额输入（仅在选中涉及金钱的分类时显示）
            if selectedCategory.hasAmount {
                amountInputField
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // 备注
            VStack(alignment: .leading, spacing: 8) {
                Text("备注（可选）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("差点下单新键盘…", text: $note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }

            // 保存按钮
            Button {
                saveRecord()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("保存记录")
                }
                .font(.headline)
                .foregroundStyle(Color.brandDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brand)
                .cornerRadius(16)
            }
            .padding(.bottom, 24)
        }
        .animation(.spring(response: 0.3), value: selectedCategory.hasAmount)
    }

    // MARK: - 金额输入框
    private var amountInputField: some View {
        let symbol = SupportedCurrency(rawValue: currencyCode)?.symbol ?? SupportedCurrency.systemSymbol
        return VStack(alignment: .leading, spacing: 8) {
            Text("节省了多少钱？（可选）")
                .font(.subheadline)
                .foregroundStyle(.secondary)
    
            HStack(spacing: 8) {
                Text(symbol)
                    .font(.headline)
                    .foregroundStyle(.secondary)
    
                TextField("输入金额", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.headline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.secondarySystemGroupedBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - "+" 新增分类 Cell
    private var addCategoryCell: some View {
        Button {
            showAddCategory = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.brand.opacity(0.7))
                Text("自定义")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.secondarySystemGroupedBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [5])
                    )
                    .foregroundStyle(Color.brand.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 成功视图
    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .symbolEffect(.bounce)

            Text("已记录")
                .font(.title2.weight(.bold))

            Text("你又忍住了一次 \(selectedCategory.name)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - 辅助方法
    private func updateAmountText(for category: ResistCategory) {
        if category.hasAmount, let amt = category.defaultAmount {
            amountText = amt.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(amt))
                : String(amt)
        } else {
            amountText = ""
        }
    }

    private func saveRecord() {
        // 解析用户输入的金额
        let finalAmount: Double?
        if selectedCategory.hasAmount, !amountText.isEmpty, let amt = Double(amountText) {
            finalAmount = amt
        } else {
            finalAmount = nil
        }

        let record = ResistRecord(
            category: selectedCategory.name,
            categoryEmoji: selectedCategory.emoji,
            note: note,
            amount: finalAmount
        )
        modelContext.insert(record)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

// MARK: - 分类 Cell
struct CategoryCell: View {
    let category: ResistCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(category.emoji)
                    .font(.system(size: 32))
                Text(LocalizedStringKey(category.name))
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.brand.opacity(0.18) : Color.secondarySystemGroupedBackground)
            .foregroundStyle(isSelected ? Color.brandDark : Color.primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 新增自定义分类 Sheet
struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode: String = "auto"

    @State private var emoji: String = ""
    @State private var name: String = ""
    @State private var hasAmount: Bool = false
    @State private var defaultAmountText: String = ""

    private var canSave: Bool {
        !emoji.trimmingCharacters(in: .whitespaces).isEmpty &&
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // 图标区域
                Section {
                    VStack(spacing: 12) {
                        // 预览大图标
                        ZStack {
                            Circle()
                                .fill(Color.brand.opacity(0.12))
                                .frame(width: 88, height: 88)
                            Text(emoji.isEmpty ? "+" : emoji)
                                .font(.system(size: emoji.isEmpty ? 36 : 52))
                                .foregroundStyle(emoji.isEmpty ? Color.brand : Color.primary)
                        }
                        .padding(.top, 8)

                        TextField("点此输入 Emoji，切换到 😊 键盘", text: $emoji)
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .onChange(of: emoji) { _, new in
                                // 限制最多 2 个字符（兼容复合 Emoji）
                                let scalars = new.unicodeScalars
                                if scalars.count > 4 {
                                    emoji = String(String.UnicodeScalarView(scalars.prefix(4)))
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                }

                // 基本信息
                Section("基本信息") {
                    HStack {
                        Text("名称")
                        TextField("克制项名称", text: $name)
                            .multilineTextAlignment(.trailing)
                    }

                    Toggle("涉及金钱支出", isOn: $hasAmount)
                        .tint(Color.brand)

                    if hasAmount {
                        HStack {
                            Text("默认节省金额")
                            Spacer()
                            Text(SupportedCurrency(rawValue: currencyCode)?.symbol ?? SupportedCurrency.systemSymbol)
                                .foregroundStyle(.secondary)
                            TextField("可选", text: $defaultAmountText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                        }
                    }
                }
            }
            .navigationTitle("新增克制项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let defaultAmount = hasAmount && !defaultAmountText.isEmpty
            ? Double(defaultAmountText)
            : nil
        let category = CustomCategory(
            emoji: emoji.trimmingCharacters(in: .whitespaces),
            name: name.trimmingCharacters(in: .whitespaces),
            hasAmount: hasAmount,
            defaultAmount: defaultAmount
        )
        modelContext.insert(category)
        dismiss()
    }
}
