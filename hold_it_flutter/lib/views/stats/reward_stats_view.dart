import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/store_manager.dart';
import '../../utils/constants.dart';

class RewardStatsView extends StatelessWidget {
  const RewardStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final storeManager = context.watch<StoreManager>();
    final totalCoins = appState.coinRecords.fold(0, (sum, c) => sum + c.coins);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('奖励统计'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          spacing: 16,
          children: [
            _buildOverviewCard(totalCoins, appState),
            _buildStatusDistribution(appState),
            _buildTimeDimension(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(int totalCoins, AppState appState) {
    final allRewards = appState.rewards;
    final redeemedCount = allRewards.where((r) => r.status == RewardStatus.redeemed).length;
    final completionRate = allRewards.isNotEmpty ? redeemedCount / allRewards.length : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              spacing: 6,
              children: [
                Text(
                  '$totalCoins',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '累计忍币',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: Column(
              spacing: 6,
              children: [
                Text(
                  '${(completionRate * 100).toInt()}%',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '完成率',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution(AppState appState) {
    final allRewards = appState.rewards;
    final inProgress = allRewards.where((r) => r.status == RewardStatus.inProgress).length;
    final unlocked = allRewards.where((r) => r.status == RewardStatus.unlocked).length;
    final redeemed = allRewards.where((r) => r.status == RewardStatus.redeemed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Row(
          spacing: 6,
          children: [
            const Icon(Icons.pie_chart, color: AppColors.brand, size: 16),
            const Text('状态分布', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        Row(
          spacing: 10,
          children: [
            _RewardStatBox(title: '进行中', value: '$inProgress', icon: Icons.access_time, color: Colors.blue),
            _RewardStatBox(title: '已解锁', value: '$unlocked', icon: Icons.lock_open, color: Colors.orange),
            _RewardStatBox(title: '已兑现', value: '$redeemed', icon: Icons.check_circle, color: Colors.green),
            _RewardStatBox(title: '总奖励数', value: '${allRewards.length}', icon: Icons.card_giftcard, color: AppColors.brand),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeDimension(AppState appState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    final todayCoins = appState.coinRecords
        .where((c) => c.createdAt.isAfter(today) || c.createdAt.isAtSameMomentAs(today))
        .fold(0, (sum, c) => sum + c.coins);
    final weekCoins = appState.coinRecords
        .where((c) => c.createdAt.isAfter(startOfWeek) || c.createdAt.isAtSameMomentAs(startOfWeek))
        .fold(0, (sum, c) => sum + c.coins);
    final monthCoins = appState.coinRecords
        .where((c) => c.createdAt.isAfter(startOfMonth) || c.createdAt.isAtSameMomentAs(startOfMonth))
        .fold(0, (sum, c) => sum + c.coins);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Row(
          spacing: 6,
          children: [
            const Icon(Icons.access_time_filled, color: AppColors.brand, size: 16),
            const Text('忍币时段', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        Row(
          spacing: 10,
          children: [
            _RewardStatBox(title: '今日', value: '$todayCoins', icon: Icons.wb_sunny, color: Colors.yellow.shade700),
            _RewardStatBox(title: '本周', value: '$weekCoins', icon: Icons.calendar_today, color: Colors.indigo),
            _RewardStatBox(title: '本月', value: '$monthCoins', icon: Icons.calendar_view_week, color: Colors.purple),
          ],
        ),
      ],
    );
  }
}

class _RewardStatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _RewardStatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          spacing: 4,
          children: [
            Icon(icon, size: 16, color: color),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
