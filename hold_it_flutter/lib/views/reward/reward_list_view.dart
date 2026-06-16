import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../../viewmodels/app_state.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';
import 'reward_detail_view.dart';
import 'create_reward_sheet.dart';

class RewardListView extends StatelessWidget {
  const RewardListView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final rewards = appState.rewards;

    final inProgress = rewards.where((r) => r.status == RewardStatus.inProgress).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final unlocked = rewards.where((r) => r.status == RewardStatus.unlocked).toList();
    final redeemed = rewards.where((r) => r.status == RewardStatus.redeemed).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('奖励管理'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateReward(context),
          ),
        ],
      ),
      body: rewards.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (inProgress.isNotEmpty) ...[
                  _buildSection('进行中'),
                  ...inProgress.map((r) => _RewardRow(reward: r)),
                ],
                if (unlocked.isNotEmpty) ...[
                  _buildSection('已解锁'),
                  ...unlocked.map((r) => _RewardRow(reward: r)),
                ],
                if (redeemed.isNotEmpty) ...[
                  _buildSection('已兑现'),
                  ...redeemed.map((r) => _RewardRow(reward: r)),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          const Icon(Icons.card_giftcard, size: 48, color: Colors.grey),
          const Text('暂无奖励', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('点击右上角 + 创建你的第一个奖励', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showCreateReward(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateRewardSheet(),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final Reward reward;

  const _RewardRow({required this.reward});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RewardDetailView(reward: reward)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: reward.imageData != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        Uint8List.fromList(reward.imageData!),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(child: Text('🎁', style: TextStyle(fontSize: 20))),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    reward.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${reward.currentCoins} / ${reward.targetCoins}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              spacing: 2,
              children: [
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: reward.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      reward.status == RewardStatus.redeemed ? Colors.grey : AppColors.brand,
                    ),
                  ),
                ),
                Text(
                  '${(reward.progress * 100).toInt()}%',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
