import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../../viewmodels/app_state.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class RewardDetailView extends StatefulWidget {
  final Reward reward;

  const RewardDetailView({super.key, required this.reward});

  @override
  State<RewardDetailView> createState() => _RewardDetailViewState();
}

class _RewardDetailViewState extends State<RewardDetailView> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final filteredCoinRecords = appState.coinRecords.where((c) => c.rewardID == widget.reward.id).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.reward.title),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          spacing: 20,
          children: [
            _buildImageHeader(),
            _buildInfoSection(),
            _buildProgressCard(),
            _buildLinkedCategories(),
            _buildRecentCoins(filteredCoinRecords, appState),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return widget.reward.imageData != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              Uint8List.fromList(widget.reward.imageData!),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        : Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 64)),
            ),
          );
  }

  Widget _buildInfoSection() {
    return Column(
      spacing: 8,
      children: [
        Text(
          widget.reward.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (widget.reward.rewardDescription.isNotEmpty)
          Text(
            widget.reward.rewardDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final remaining = widget.reward.targetCoins - widget.reward.currentCoins;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 12,
        children: [
          Row(
            children: [
              Text('当前进度', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const Spacer(),
              Text(
                '${widget.reward.currentCoins} / ${widget.reward.targetCoins}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brand),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: widget.reward.progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand),
          ),
          if (widget.reward.status == RewardStatus.inProgress)
            Text(
              '距离解锁还差 $remaining 忍币',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          else if (widget.reward.status == RewardStatus.unlocked)
            const Text(
              '🎉 奖励已解锁！现在可以奖励自己了',
              style: TextStyle(fontSize: 12, color: AppColors.brand),
            )
          else if (widget.reward.redeemedAt != null)
            Text(
              '已兑现 · ${widget.reward.redeemedAt!.month}月${widget.reward.redeemedAt!.day}日',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildLinkedCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        const Text('已关联克制项', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        if (widget.reward.categoryIDs.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('未关联任何克制项', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          )
        else
          ...widget.reward.categoryIDs.map((catID) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              spacing: 8,
              children: [
                Text(_categoryEmoji(catID)),
                Text(_categoryName(catID)),
                const Spacer(),
                const Icon(Icons.check_circle, color: AppColors.brand, size: 16),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildRecentCoins(List<RewardCoinRecord> coinRecords, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        const Text('最近贡献记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        if (coinRecords.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '还没有贡献记录，记录克制即可自动获得忍币',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          )
        else
          ...coinRecords.take(20).map((cr) {
            final resistRecord = appState.records.firstWhere(
              (r) => r.id == cr.restraintRecordID,
              orElse: () => ResistRecord(category: '—', categoryEmoji: '', categoryID: '', note: ''),
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(resistRecord.categoryEmoji),
                  const SizedBox(width: 8),
                  Text(resistRecord.category),
                  const Spacer(),
                  Text(
                    '+${cr.coins} 忍币',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.brand),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${cr.createdAt.month}月${cr.createdAt.day}日',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      spacing: 12,
      children: [
        if (widget.reward.status == RewardStatus.unlocked)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _redeemReward(),
              icon: const Icon(Icons.card_giftcard),
              label: const Text('兑现奖励'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        if (widget.reward.status == RewardStatus.redeemed)
          TextButton(
            onPressed: () => _undoRedeem(),
            child: const Text('撤回兑现'),
          ),
      ],
    );
  }

  void _redeemReward() {
    setState(() {
      widget.reward.status = RewardStatus.redeemed;
      widget.reward.redeemedAt = DateTime.now();
    });
    context.read<AppState>().updateReward(widget.reward);
  }

  void _undoRedeem() {
    setState(() {
      widget.reward.status = RewardStatus.unlocked;
      widget.reward.redeemedAt = null;
    });
    context.read<AppState>().updateReward(widget.reward);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除奖励'),
        content: const Text('删除后奖励进度将丢失，确定删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteReward(widget.reward.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String categoryID) {
    final map = {
      'default_milk_tea': '🧋',
      'default_impulse_buy': '💸',
      'default_gaming': '🎮',
      'default_short_video': '📱',
      'default_miss_him': '❤️',
    };
    return map[categoryID] ?? '📌';
  }

  String _categoryName(String categoryID) {
    final map = {
      'default_milk_tea': '奶茶',
      'default_impulse_buy': '冲动消费',
      'default_gaming': '游戏',
      'default_short_video': '短视频',
      'default_miss_him': '想TA',
    };
    return map[categoryID] ?? categoryID;
  }
}
