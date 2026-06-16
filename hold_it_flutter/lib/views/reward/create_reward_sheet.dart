import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/app_state.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class CreateRewardSheet extends StatefulWidget {
  const CreateRewardSheet({super.key});

  @override
  State<CreateRewardSheet> createState() => _CreateRewardSheetState();
}

class _CreateRewardSheetState extends State<CreateRewardSheet> {
  String _title = '';
  String _description = '';
  String _targetCoinsText = '';
  final Set<String> _selectedCategoryIDs = {};

  bool get _canSave {
    final trimmed = _title.trim();
    final target = int.tryParse(_targetCoinsText);
    return trimmed.isNotEmpty && target != null && target > 0 && _selectedCategoryIDs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final allCategories = ResistCategory.defaults + appState.customCategories.map((c) => ResistCategory.fromCustom(c)).toList();

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
                const Text('新建奖励', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                spacing: 16,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '奖励名称（必填）',
                      hintText: '例如：买新手机',
                    ),
                    onChanged: (v) => setState(() => _title = v),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '奖励描述（选填）',
                      hintText: '描述一下这个奖励',
                    ),
                    maxLines: 2,
                    onChanged: (v) => setState(() => _description = v),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '目标忍币数量',
                      hintText: '需要多少忍币才能解锁',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _targetCoinsText = v),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('关联克制项', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                  Text(
                    '每次记录关联的克制项时，该奖励自动获得 1 忍币',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  ...allCategories.map((cat) => GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedCategoryIDs.contains(cat.stableID)) {
                          _selectedCategoryIDs.remove(cat.stableID);
                        } else {
                          _selectedCategoryIDs.add(cat.stableID);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: _selectedCategoryIDs.contains(cat.stableID)
                            ? AppColors.brand.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: _selectedCategoryIDs.contains(cat.stableID)
                            ? Border.all(color: AppColors.brand)
                            : null,
                      ),
                      child: Row(
                        spacing: 12,
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                          Text(cat.name),
                          const Spacer(),
                          Icon(
                            _selectedCategoryIDs.contains(cat.stableID)
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: _selectedCategoryIDs.contains(cat.stableID) ? AppColors.brand : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSave
                    ? () {
                        final reward = Reward(
                          title: _title.trim(),
                          rewardDescription: _description.trim(),
                          targetCoins: int.parse(_targetCoinsText),
                          categoryIDs: _selectedCategoryIDs.toList(),
                        );
                        appState.addReward(reward);
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: AppColors.brandDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('创建', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
