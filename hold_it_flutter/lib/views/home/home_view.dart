import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/store_manager.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../models/encourage_quote.dart';
import 'record_sheet.dart';
import 'celebration_view.dart';
import '../reward/reward_progress_card.dart';
import '../reward/reward_list_view.dart';
import '../timeline/timeline_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentQuoteIndex = EncourageQuote.todayIndex();
  bool _showCelebration = false;
  Reward? _unlockedReward;
  int _carouselIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final storeManager = context.watch<StoreManager>();
    final records = appState.records;
    final rewards = appState.rewards.where((r) => r.status == RewardStatus.inProgress).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final topRewards = rewards.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('忍一下'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildStatsCards(appState, records),
            const SizedBox(height: 12),
            _buildEncourageCard(),
            const SizedBox(height: 12),
            if (records.isNotEmpty) _buildLastRecordCard(records),
            const SizedBox(height: 12),
            _buildMainButton(),
            const SizedBox(height: 12),
            _buildRewardsSection(topRewards, rewards.length, storeManager),
          ],
        ),
      ),
      floatingActionButton: _showCelebration ? const CelebrationView() : null,
    );
  }

  Widget _buildStatsCards(AppState appState, List<ResistRecord> records) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: '今天已忍住',
            value: '${appState.todayCount()}',
            unit: '次',
            icon: Icons.check_circle,
            color: AppColors.brand,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordsListView(initialFilter: TimeFilter.today))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: '今天已节省',
            value: _todaySavedSummary(appState),
            unit: '',
            icon: Icons.account_balance_wallet,
            color: AppColors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedRecordsListView(initialFilter: TimeFilter.today))),
          ),
        ),
      ],
    );
  }

  String _todaySavedSummary(AppState appState) {
    final amount = appState.todaySavedAmount();
    if (amount == 0) return '¥0';
    return '¥${formatAmount(amount)}';
  }

  Widget _buildEncourageCard() {
    final quotes = EncourageQuote.allQuotes;
    final quote = quotes[_currentQuoteIndex % quotes.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: AppColors.brand, size: 16),
              const SizedBox(width: 4),
              Text(
                'To Myself',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quote,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastRecordCard(List<ResistRecord> records) {
    final record = records[_carouselIndex % records.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(record.categoryEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.category,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      relativeTimeString(record.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (record.amount != null && record.amount! > 0) ...[
                      Text('·', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 4),
                      Text(
                        '¥${formatAmount(record.amount!)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.brand),
                      ),
                    ],
                  ],
                ),
                if (record.note.isNotEmpty)
                  Text(
                    record.note,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.brand),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: () => _showRecordSheet(context),
      child: Container(
        width: 220,
        height: 220,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brand.withOpacity(0.12),
        ),
        child: Center(
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '忍一下',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '点击记录',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.brandDark.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordSheet(
        onSave: (unlocked) {
          setState(() {
            _showCelebration = true;
            _unlockedReward = unlocked;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _showCelebration = false);
            }
          });
        },
      ),
    );
  }

  Widget _buildRewardsSection(List<Reward> topRewards, int totalRewards, StoreManager storeManager) {
    return Column(
      children: [
        Row(
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: AppColors.brand, size: 18),
                const SizedBox(width: 6),
                const Text(
                  '进行中的奖励',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardListView())),
              child: Row(
                children: [
                  Text('管理', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (topRewards.isEmpty)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardListView())),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('还没有奖励目标', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(
                          '创建一个奖励，记录克制即可自动获得忍币',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.add_circle, color: AppColors.brand),
                ],
              ),
            ),
          )
        else
          ...topRewards.map((r) => RewardProgressCard(reward: r)),
        if (totalRewards > 3)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardListView())),
            child: Text(
              '查看全部 $totalRewards 个奖励',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const Spacer(),
                Icon(Icons.chevron_right, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
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
