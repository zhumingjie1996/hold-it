import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/store_manager.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';
import '../timeline/timeline_view.dart';
import 'heatmap_view.dart';
import 'category_stats_view.dart';
import 'monthly_trend_view.dart';
import 'time_of_day_view.dart';
import 'weekday_distribution_view.dart';
import 'saved_amount_stats_view.dart';
import 'reward_stats_view.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final storeManager = context.watch<StoreManager>();
    final records = appState.records;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('统计'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          spacing: 12,
          children: [
            _buildBasicStats(appState, records),
            _buildRecordsTimeline(records),
            _buildSavedAmountEntry(appState, records),
            _buildRewardStats(appState),
            if (storeManager.isVip)
              _buildVipContent(appState, records)
            else
              _buildVipLockView(storeManager),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicStats(AppState appState, List<ResistRecord> records) {
    return Column(
      spacing: 10,
      children: [
        Row(
          spacing: 10,
          children: [
            _BasicStatBox(title: '累计忍住', value: '${appState.totalCount()}', unit: '次', color: AppColors.brand),
            _BasicStatBox(title: '今年', value: '${appState.thisYearCount()}', unit: '次', color: Colors.indigo),
            _BasicStatBox(title: '本月', value: '${appState.thisMonthCount()}', unit: '次', color: Colors.purple),
          ],
        ),
        Row(
          spacing: 10,
          children: [
            _BasicStatBox(title: '今天', value: '${appState.todayCount()}', unit: '次', color: Colors.green),
            _BasicStatBox(title: '连续记录', value: '${appState.streakDays()}', unit: '天', color: Colors.orange),
            _BasicStatBox(title: '最长连续', value: '${appState.bestStreak()}', unit: '天', color: Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordsTimeline(List<ResistRecord> records) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordsListView())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          spacing: 14,
          children: [
            const Icon(Icons.access_time_filled, color: Colors.green, size: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  const Text('全部记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    records.isEmpty ? '暂无记录' : '共 ${records.length} 条忍住记录',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAmountEntry(AppState appState, List<ResistRecord> records) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavedAmountStatsView(records: records))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          spacing: 14,
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.green, size: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  const Text('节省统计', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    appState.totalSavedAmount() > 0
                        ? '累计节省 ¥${formatAmount(appState.totalSavedAmount())}'
                        : '多维度节省金额分析',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardStats(AppState appState) {
    final totalCoins = appState.coinRecords.fold(0, (sum, c) => sum + c.coins);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardStatsView())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          spacing: 14,
          children: [
            const Icon(Icons.card_giftcard, color: AppColors.brand, size: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  const Text('奖励统计', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    totalCoins > 0 ? '累计 $totalCoins 忍币' : '多维度奖励分析',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildVipContent(AppState appState, List<ResistRecord> records) {
    return Column(
      spacing: 12,
      children: [
        CategoryStatsView(records: records),
        WeekdayDistributionView(records: records),
        TimeOfDayView(records: records),
        HeatmapView(records: records),
        MonthlyTrendView(records: records),
      ],
    );
  }

  Widget _buildVipLockView(StoreManager storeManager) {
    return Column(
      spacing: 20,
      children: [
        // Blurred preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Row(
                spacing: 8,
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.brand, size: 18),
                  const Text('热力图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: List.generate(84, (i) {
                  final level = [0, 0, 1, 2, 0, 3, 1, 0, 0, 2, 1, 0, 3, 2, 0, 1, 0, 0, 2, 3, 1, 0, 0, 1, 2, 0, 3, 1][i % 28];
                  return Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: level == 0 ? Colors.grey[300] : AppColors.brand.withOpacity(level * 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        // Feature highlights
        Column(
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                _highlightItem(Icons.calendar_view_week, '周几分布', Colors.pink),
                _highlightItem(Icons.calendar_today, '热力图', Colors.orange),
              ],
            ),
            Row(
              spacing: 12,
              children: [
                _highlightItem(Icons.trending_up, '月度趋势', Colors.blue),
                _highlightItem(Icons.access_time_filled, '时段分析', Colors.purple),
              ],
            ),
            Row(
              spacing: 12,
              children: [
                _highlightItem(Icons.pie_chart, '分类分析', AppColors.brand),
              ],
            ),
          ],
        ),
        // Upgrade CTA
        GestureDetector(
          onTap: () => storeManager.purchase(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brand, AppColors.brandDark],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
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
                  '解锁全部高级统计',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _highlightItem(IconData icon, String title, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          spacing: 8,
          children: [
            Icon(icon, size: 18, color: color),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

class _BasicStatBox extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;

  const _BasicStatBox({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          spacing: 4,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
