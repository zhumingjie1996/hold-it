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
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode: String = "auto"
    var onSave: ((_ unlockedReward: Reward?) -> Void)? = nil

    @Query(sort: \CustomCategory.createdAt) private var customCategories: [CustomCategory]

    @State private var selectedCategory: ResistCategory = ResistCategory.defaults[0]
    @State private var note: String = ""
    @State private var amountText: String = ""
    @State private var showAddCategory = false
    @State private var editingCategory: CustomCategory?
    @State private var deletingCategory: ResistCategory?
    @State private var showDeleteAlert = false
    @State private var showVipAlert = false
    @State private var draggingCategory: ResistCategory?
    @State private var showRewardPicker = false
    @State private var pendingRecord: ResistRecord?
    @State private var matchingRewards: [Reward] = []
    @AppStorage("categoryOrder") private var categoryOrderData: Data = Data()

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    /// 排序顺序（存储 name）
    private var categoryOrder: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: categoryOrderData)) ?? []
        }
    }

    /// 保存排序顺序
    private func saveCategoryOrder(_ names: [String]) {
        categoryOrderData = (try? JSONEncoder().encode(names)) ?? Data()
    }

    /// 默认 + 自定义分类合并，按用户排序
    private var allCategories: [ResistCategory] {
        let all = ResistCategory.defaults + customCategories.map { ResistCategory(from: $0) }
        let order = categoryOrder
        if order.isEmpty { return all }
        // 按 order 排序，不在 order 中的保持原序追加到末尾
        var sorted: [ResistCategory] = []
        for name in order {
            if let cat = all.first(where: { $0.name == name }) {
                sorted.append(cat)
            }
        }
        for cat in all where !sorted.contains(where: { $0.name == cat.name }) {
            sorted.append(cat)
        }
        return sorted
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    formContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)
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
        .sheet(item: $editingCategory) { custom in
            AddCategorySheet(editingCategory: custom)
        }
        .alert("删除忍住项", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) {
                deleteCategory()
            }
            Button("取消", role: .cancel) { }
        } message: {
            if let cat = deletingCategory {
                Text("确定删除「\(cat.name)」吗？已有的记录不会被删除。")
            }
        }
        .alert("解锁更多自定义", isPresented: $showVipAlert) {
            Button(vipAlertPurchaseTitle) {
                Task {
                    _ = await storeManager.purchase()
                }
            }
            Button("暂不需要", role: .cancel) { }
        } message: {
            Text("非会员最多添加3个自定义忍住项，解锁后可无限添加。")
        }
        .sheet(isPresented: $showRewardPicker) {
            RewardPickerSheet(
                categoryName: selectedCategory.name,
                categoryEmoji: selectedCategory.emoji,
                rewards: matchingRewards
            ) { selectedIDs in
                confirmRewardSelection(selectedRewardIDs: selectedIDs)
            }
        }
        .onAppear {
            updateAmountText(for: selectedCategory)
        }
    }

    // MARK: - 表单内容
    private var formContent: some View {
        VStack(spacing: 20) {
            categoryGrid

            // 金额输入（仅在选中涉及金钱的分类时显示）
            if selectedCategory.hasAmount {
                amountInputField
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            noteSection

            // 保存按钮
            saveButton

            // 非会员：升级 CTA
            if !storeManager.isVip {
                vipUpgradeCTA
            }

            Spacer(minLength: 24)
        }
        .animation(.spring(response: 0.3), value: selectedCategory.hasAmount)
    }

    // MARK: - 分类网格
    private var categoryGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(allCategories) { category in
                CategoryCell(
                    category: category,
                    isSelected: selectedCategory == category,
                    onEdit: category.isCustom ? {
                        if let customID = category.customCategoryID,
                           let custom = customCategories.first(where: { $0.id == customID }) {
                            editingCategory = custom
                        }
                    } : nil,
                    onDelete: category.isCustom ? {
                        deletingCategory = category
                        showDeleteAlert = true
                    } : nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = category
                        updateAmountText(for: category)
                    }
                }
                .onDrag {
                    draggingCategory = category
                    return NSItemProvider(object: category.name as NSString)
                }
                .onDrop(of: ["public.text"], delegate: CategoryDropDelegate(
                    category: category,
                    categories: allCategories,
                    draggingCategory: $draggingCategory,
                    onReorder: { newOrder in
                        saveCategoryOrder(newOrder)
                    }
                ))
            }
            // "+" 新增按钮
            addCategoryCell
        }
    }

    // MARK: - 备注区域
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注（可选）")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(notePlaceholder, text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }

    // MARK: - 保存按钮
    private var saveButton: some View {
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
    }

    // MARK: - VIP 升级 CTA
    private var vipUpgradeCTA: some View {
        Button {
            Task {
                _ = await storeManager.purchase()
                if storeManager.purchaseState == .failed {
                    showVipAlert = true
                }
            }
        } label: {
            if storeManager.purchaseState == .purchasing {
                vipPurchasingLabel
            } else {
                vipIdleLabel
            }
        }
        .buttonStyle(.plain)
    }

    private var vipPurchasingLabel: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.9)
                Text("支付中…")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Text("请稍候")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color.brand, Color.brandDark],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }

    private var vipIdleLabel: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                Text("解锁终身会员")
                    .font(.headline)
                    .foregroundStyle(.white)
                if !storeManager.displayPrice.isEmpty {
                    Text(storeManager.displayPrice)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            Text("非会员最多添加3个，解锁后无限添加")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color.brand, Color.brandDark],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.brand.opacity(0.3), radius: 12, x: 0, y: 6)
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
        let canAdd = storeManager.isVip || customCategories.count < 3
        return Button {
            if canAdd {
                showAddCategory = true
            }
        } label: {
            ZStack {
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

                // 非会员已达上限：锁+遮罩
                if !canAdd {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.systemBackground.opacity(0.5))
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .onTapGesture {
            if !canAdd {
                showVipAlert = true
            }
        }
    }

    // MARK: - 辅助方法
    private var vipAlertPurchaseTitle: String {
        storeManager.displayPrice.isEmpty
            ? String(localized: "解锁终身会员")
            : String(localized: "解锁终身会员") + " (" + storeManager.displayPrice + ")"
    }

    private var notePlaceholder: String {
        if !selectedCategory.placeholder.isEmpty {
            return selectedCategory.placeholder
        }
        return String(localized: "写点什么…")
    }

    private func updateAmountText(for category: ResistCategory) {
        if category.hasAmount, let amt = category.defaultAmount {
            amountText = amt.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(amt))
                : String(amt)
        } else {
            amountText = ""
        }
    }

    @Query(filter: #Predicate<Reward> { $0.statusRaw == "IN_PROGRESS" }) private var activeRewards: [Reward]

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
            categoryID: selectedCategory.stableID,
            note: note,
            amount: finalAmount
        )
        modelContext.insert(record)

        // 查找关联的奖励任务
        let catID = selectedCategory.stableID
        let matched = activeRewards.filter { $0.categoryIDs.contains(catID) }

        if matched.count <= 1 {
            // 0 或 1 个奖励 → 直接加币
            assignCoins(to: matched, for: record)
            dismiss()
        } else {
            // 多个奖励 → 弹出选择器
            pendingRecord = record
            matchingRewards = matched
            showRewardPicker = true
        }
    }

    /// 给指定奖励加忍币
    private func assignCoins(to rewards: [Reward], for record: ResistRecord) {
        var unlockedReward: Reward?
        for reward in rewards {
            reward.currentCoins += 1
            let coinRecord = RewardCoinRecord(
                rewardID: reward.id,
                restraintRecordID: record.id
            )
            modelContext.insert(coinRecord)
            if reward.currentCoins >= reward.targetCoins, reward.status == .inProgress {
                reward.status = .unlocked
                reward.unlockedAt = Date()
                unlockedReward = reward
            }
        }
        onSave?(unlockedReward)
    }

    /// 用户选择奖励后确认
    private func confirmRewardSelection(selectedRewardIDs: Set<UUID>) {
        guard let record = pendingRecord else { return }
        let selected = matchingRewards.filter { selectedRewardIDs.contains($0.id) }
        assignCoins(to: selected, for: record)
        pendingRecord = nil
        matchingRewards = []
        dismiss()
    }

    private func deleteCategory() {
        guard let cat = deletingCategory,
              let customID = cat.customCategoryID,
              let custom = customCategories.first(where: { $0.id == customID }) else { return }
        modelContext.delete(custom)
        // 如果当前选中的是被删除的分类，重置为第一个默认分类
        if selectedCategory == cat {
            selectedCategory = ResistCategory.defaults[0]
            updateAmountText(for: selectedCategory)
        }
        deletingCategory = nil
    }
}

// MARK: - 分类 Cell
struct CategoryCell: View {
    let category: ResistCategory
    let isSelected: Bool
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    let action: () -> Void

    init(category: ResistCategory, isSelected: Bool, onEdit: (() -> Void)? = nil, onDelete: (() -> Void)? = nil, action: @escaping () -> Void) {
        self.category = category
        self.isSelected = isSelected
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
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

                // 自定义角标
                if category.isCustom {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Color.brand)
                        .clipShape(Circle())
                        .offset(x: -4, y: 4)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if category.isCustom {
                Button {
                    onEdit?()
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - 新增/编辑自定义分类 Sheet
struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode: String = "auto"
    @Query(sort: \CustomCategory.createdAt) private var customCategories: [CustomCategory]

    var editingCategory: CustomCategory?

    @State private var emoji: String = ""
    @State private var name: String = ""
    @State private var hasAmount: Bool = false
    @State private var defaultAmountText: String = ""

    @State private var showVipAlert = false

    private var isEditing: Bool { editingCategory != nil }

    private var canSave: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty && !trimmedEmoji.isEmpty else { return false }
        // 不允许与默认分类同名
        let defaultNames = ResistCategory.defaults.map { $0.name }
        guard !defaultNames.contains(trimmedName) else { return false }
        // 编辑时允许保留原名
        if isEditing, editingCategory?.name == trimmedName {
            return true
        }
        return true
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
                        TextField("忍住项名称", text: $name)
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
            .navigationTitle(isEditing ? "编辑忍住项" : "新增忍住项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "完成" : "保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .alert("解锁更多自定义", isPresented: $showVipAlert) {
                Button(addCategoryVipTitle) {
                    Task {
                        _ = await storeManager.purchase()
                    }
                }
                Button("暂不需要", role: .cancel) { }
            } message: {
                Text("非会员最多添加3个自定义忍住项，解锁后可无限添加。")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if let editing = editingCategory {
                emoji = editing.emoji
                name = editing.name
                hasAmount = editing.hasAmount
                if let amt = editing.defaultAmount {
                    defaultAmountText = amt.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(amt))
                        : String(amt)
                }
            }
        }
    }

    private var addCategoryVipTitle: String {
        storeManager.displayPrice.isEmpty
            ? String(localized: "解锁终身会员")
            : String(localized: "解锁终身会员") + " (" + storeManager.displayPrice + ")"
    }

    private func save() {
        let defaultAmount = hasAmount && !defaultAmountText.isEmpty
            ? Double(defaultAmountText)
            : nil

        if let editing = editingCategory {
            // 编辑模式：更新现有记录
            editing.emoji = emoji.trimmingCharacters(in: .whitespaces)
            editing.name = name.trimmingCharacters(in: .whitespaces)
            editing.hasAmount = hasAmount
            editing.defaultAmount = defaultAmount
        } else {
            // 新增模式：检查非会员上限
            if !storeManager.isVip && customCategories.count >= 3 {
                showVipAlert = true
                return
            }
            let category = CustomCategory(
                emoji: emoji.trimmingCharacters(in: .whitespaces),
                name: name.trimmingCharacters(in: .whitespaces),
                hasAmount: hasAmount,
                defaultAmount: defaultAmount
            )
            modelContext.insert(category)
        }
        dismiss()
    }
}

// MARK: - 拖拽排序 DropDelegate
struct CategoryDropDelegate: DropDelegate {
    let category: ResistCategory
    let categories: [ResistCategory]
    @Binding var draggingCategory: ResistCategory?
    let onReorder: ([String]) -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggingCategory = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingCategory,
              dragging != category else { return }

        var newCategories = categories
        let fromIndex = newCategories.firstIndex(where: { $0.name == dragging.name }) ?? 0
        let toIndex = newCategories.firstIndex(where: { $0.name == category.name }) ?? 0

        guard fromIndex != toIndex else { return }

        withAnimation(.spring(response: 0.3)) {
            newCategories.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            onReorder(newCategories.map { $0.name })
        }
    }
}

// MARK: - 奖励选择器 Sheet
struct RewardPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let categoryName: String
    let categoryEmoji: String
    let rewards: [Reward]
    let onConfirm: (Set<UUID>) -> Void

    @State private var selectedIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                categoryInfoHeader

                // 奖励列表
                rewardList

                // 操作按钮
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .navigationTitle("选择奖励")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .onAppear {
            // 默认全选
            selectedIDs = Set(rewards.map { $0.id })
        }
    }

    // MARK: - 分类信息提示
    private var categoryInfoHeader: some View {
        HStack(spacing: 10) {
            Text(categoryEmoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(categoryName))
                    .font(.subheadline.weight(.medium))
                Text("多个奖励关联了该忍住项，请选择要获得忍币的奖励")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.brand.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - 奖励列表
    private var rewardList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(rewards) { reward in
                    rewardRow(reward)
                }
            }
        }
    }

    // MARK: - 奖励行
    private func rewardRow(_ reward: Reward) -> some View {
        Button {
            toggleReward(reward.id)
        } label: {
            HStack(spacing: 12) {
                // 图片/占位
                Group {
                    if let data = reward.imageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(Color.brand)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    ProgressView(value: reward.progress)
                        .tint(Color.brand)
                    Text("\(reward.currentCoins)/\(reward.targetCoins) \(String(localized: "忍币"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: selectedIDs.contains(reward.id)
                      ? "checkmark.circle.fill"
                      : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedIDs.contains(reward.id) ? Color.brand : Color(.tertiaryLabel))
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedIDs.contains(reward.id) ? Color.brand : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 操作按钮
    private var actionButtons: some View {
        VStack(spacing: 10) {
            // 确认按钮
            Button {
                onConfirm(selectedIDs)
            } label: {
                HStack {
                    Text("确认")
                        .font(.headline)
                    if !selectedIDs.isEmpty {
                        Text("(\(selectedIDs.count))")
                            .font(.subheadline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selectedIDs.isEmpty ? Color.gray.opacity(0.4) : Color.brand)
                .cornerRadius(12)
            }
            .disabled(selectedIDs.isEmpty)

            // 全部添加
            Button {
                selectedIDs = Set(rewards.map { $0.id })
                onConfirm(selectedIDs)
            } label: {
                Text("全部添加")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
    }

    private func toggleReward(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}
