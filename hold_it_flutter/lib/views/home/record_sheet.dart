import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/store_manager.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class RecordSheet extends StatefulWidget {
  final Function(Reward? unlocked)? onSave;

  const RecordSheet({super.key, this.onSave});

  @override
  State<RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends State<RecordSheet> {
  late ResistCategory _selectedCategory;
  String _note = '';
  String _amountText = '';
  bool _showAddCategory = false;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = ResistCategory.defaults[0];
    _updateAmountText();
  }

  void _updateAmountText() {
    if (_selectedCategory.hasAmount && _selectedCategory.defaultAmount != null) {
      _amountController.text = formatAmount(_selectedCategory.defaultAmount!);
    } else {
      _amountController.text = '';
    }
  }

  List<ResistCategory> _getAllCategories(AppState appState) {
    final custom = appState.customCategories.map((c) => ResistCategory.fromCustom(c)).toList();
    return ResistCategory.defaults + custom;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final storeManager = context.watch<StoreManager>();
    final allCategories = _getAllCategories(appState);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '你忍住了什么？',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                spacing: 20,
                children: [
                  _buildCategoryGrid(allCategories, storeManager, appState),
                  if (_selectedCategory.hasAmount) _buildAmountInput(),
                  _buildNoteInput(),
                  _buildSaveButton(appState, storeManager),
                  if (!storeManager.isVip) _buildVipCTA(storeManager),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<ResistCategory> categories, StoreManager storeManager, AppState appState) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...categories.map((cat) => _CategoryCell(
          category: cat,
          isSelected: _selectedCategory == cat,
          onTap: () {
            setState(() {
              _selectedCategory = cat;
              _updateAmountText();
            });
          },
          onEdit: cat.isCustom ? () => _editCategory(cat) : null,
          onDelete: cat.isCustom ? () => _deleteCategory(cat, appState) : null,
        )),
        _buildAddCategoryCell(storeManager, appState),
      ],
    );
  }

  Widget _buildAddCategoryCell(StoreManager storeManager, AppState appState) {
    final canAdd = storeManager.isVip || appState.customCategories.length < 3;

    return GestureDetector(
      onTap: canAdd ? () => _showAddCategorySheet(context) : null,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.brand.withOpacity(0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          spacing: 6,
          children: [
            Icon(
              canAdd ? Icons.add_circle : Icons.lock,
              color: AppColors.brand.withOpacity(0.7),
              size: 30,
            ),
            Text(
              canAdd ? '自定义' : '已达上限',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          '节省了多少钱？（可选）',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            spacing: 8,
            children: [
              const Text('¥', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '输入金额',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  onChanged: (v) => _amountText = v,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          '备注（可选）',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: _selectedCategory.placeholder.isNotEmpty ? _selectedCategory.placeholder : '写点什么…',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          onChanged: (v) => _note = v,
        ),
      ],
    );
  }

  Widget _buildSaveButton(AppState appState, StoreManager storeManager) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _saveRecord(appState, storeManager),
        icon: const Icon(Icons.check_circle),
        label: const Text('保存记录', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.brandDark,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildVipCTA(StoreManager storeManager) {
    return GestureDetector(
      onTap: () => storeManager.purchase(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brand, AppColors.brandDark],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          spacing: 4,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 18),
                const Text(
                  '解锁终身会员',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            Text(
              '非会员最多添加3个，解锁后无限添加',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveRecord(AppState appState, StoreManager storeManager) {
    final amount = _amountText.isNotEmpty ? double.tryParse(_amountText) : null;

    final record = ResistRecord(
      category: _selectedCategory.name,
      categoryEmoji: _selectedCategory.emoji,
      categoryID: _selectedCategory.stableID,
      note: _note,
      amount: amount,
    );

    appState.addRecord(record);

    // Find matching rewards
    final activeRewards = appState.rewards.where((r) => r.status == RewardStatus.inProgress).toList();
    final matched = activeRewards.where((r) => r.categoryIDs.contains(_selectedCategory.stableID)).toList();

    Reward? unlockedReward;
    for (final reward in matched) {
      reward.currentCoins += 1;
      final coinRecord = RewardCoinRecord(
        rewardID: reward.id,
        restraintRecordID: record.id,
      );
      appState.addCoinRecord(coinRecord);

      if (reward.currentCoins >= reward.targetCoins && reward.status == RewardStatus.inProgress) {
        reward.status = RewardStatus.unlocked;
        reward.unlockedAt = DateTime.now();
        appState.updateReward(reward);
        unlockedReward = reward;
      }
    }

    widget.onSave?.call(unlockedReward);
    Navigator.pop(context);
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddCategorySheet(),
    );
  }

  void _editCategory(ResistCategory category) {
    // TODO: Implement edit
  }

  void _deleteCategory(ResistCategory category, AppState appState) {
    if (category.customCategoryID != null) {
      appState.deleteCustomCategory(category.customCategoryID!);
    }
  }
}

class _CategoryCell extends StatelessWidget {
  final ResistCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CategoryCell({
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand.withOpacity(0.18) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.brand, width: 2) : null,
        ),
        child: Column(
          spacing: 6,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 32)),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.brandDark : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key});

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  String _emoji = '';
  String _name = '';
  bool _hasAmount = false;
  String _defaultAmountText = '';

  bool get _canSave => _name.trim().isNotEmpty && _emoji.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Row(
            children: [
              const Text('新增忍住项', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Emoji',
              hintText: '例如: 🍔',
            ),
            onChanged: (v) => setState(() => _emoji = v),
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '忍住项名称',
            ),
            onChanged: (v) => setState(() => _name = v),
          ),
          SwitchListTile(
            title: const Text('涉及金钱支出'),
            value: _hasAmount,
            onChanged: (v) => setState(() => _hasAmount = v),
          ),
          if (_hasAmount)
            TextField(
              decoration: const InputDecoration(
                labelText: '默认节省金额',
                hintText: '可选',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => _defaultAmountText = v,
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSave
                  ? () {
                      final category = CustomCategory(
                        emoji: _emoji.trim(),
                        name: _name.trim(),
                        hasAmount: _hasAmount,
                        defaultAmount: _defaultAmountText.isNotEmpty ? double.tryParse(_defaultAmountText) : null,
                      );
                      appState.addCustomCategory(category);
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
