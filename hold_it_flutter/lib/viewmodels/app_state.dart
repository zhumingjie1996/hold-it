import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class AppState extends ChangeNotifier {
  List<ResistRecord> _records = [];
  List<CustomCategory> _customCategories = [];
  List<Reward> _rewards = [];
  List<RewardCoinRecord> _coinRecords = [];

  List<ResistRecord> get records => _records;
  List<CustomCategory> get customCategories => _customCategories;
  List<Reward> get rewards => _rewards;
  List<RewardCoinRecord> get coinRecords => _coinRecords;

  AppState() {
    loadData();
  }

  Future<void> loadData() async {
    final db = await DatabaseHelper.instance.database;
    final recordMaps = await db.query('resist_records', orderBy: 'created_at DESC');
    final categoryMaps = await db.query('custom_categories', orderBy: 'created_at ASC');
    final rewardMaps = await db.query('rewards');
    final coinMaps = await db.query('reward_coin_records', orderBy: 'created_at DESC');

    _records = recordMaps.map((m) => ResistRecord.fromMap(m)).toList();
    _customCategories = categoryMaps.map((m) => CustomCategory.fromMap(m)).toList();
    _rewards = rewardMaps.map((m) => Reward.fromMap(m)).toList();
    _coinRecords = coinMaps.map((m) => RewardCoinRecord.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> addRecord(ResistRecord record) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('resist_records', record.toMap());
    await loadData();
  }

  Future<void> addCustomCategory(CustomCategory category) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('custom_categories', category.toMap());
    await loadData();
  }

  Future<void> deleteCustomCategory(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('custom_categories', where: 'id = ?', whereArgs: [id]);
    await loadData();
  }

  Future<void> addReward(Reward reward) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('rewards', reward.toMap());
    await loadData();
  }

  Future<void> updateReward(Reward reward) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('rewards', reward.toMap(), where: 'id = ?', whereArgs: [reward.id]);
    await loadData();
  }

  Future<void> deleteReward(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('rewards', where: 'id = ?', whereArgs: [id]);
    await db.delete('reward_coin_records', where: 'reward_id = ?', whereArgs: [id]);
    await loadData();
  }

  Future<void> addCoinRecord(RewardCoinRecord coinRecord) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('reward_coin_records', coinRecord.toMap());
    await loadData();
  }

  Future<void> clearAllData() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('resist_records');
    await db.delete('custom_categories');
    await db.delete('rewards');
    await db.delete('reward_coin_records');
    await loadData();
  }

  // MARK: - Statistics

  int todayCount() {
    final startOfDay = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return _records.where((r) => r.createdAt.isAfter(startOfDay) || r.createdAt.isAtSameMomentAs(startOfDay)).length;
  }

  int thisWeekCount() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return _records.where((r) => r.createdAt.isAfter(startOfWeek) || r.createdAt.isAtSameMomentAs(startOfWeek)).length;
  }

  int thisMonthCount() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _records.where((r) => r.createdAt.isAfter(startOfMonth) || r.createdAt.isAtSameMomentAs(startOfMonth)).length;
  }

  int thisYearCount() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    return _records.where((r) => r.createdAt.isAfter(startOfYear) || r.createdAt.isAtSameMomentAs(startOfYear)).length;
  }

  int streakDays() {
    if (_records.isEmpty) return 0;
    final sortedDates = _records.map((r) => DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day)).toSet().toList();
    sortedDates.sort((a, b) => b.compareTo(a));

    var streak = 0;
    var checkDate = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    if (!sortedDates.any((d) => d.isAtSameMomentAs(checkDate))) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    final dateSet = sortedDates.toSet();
    while (dateSet.any((d) => d.isAtSameMomentAs(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int bestStreak() {
    if (_records.isEmpty) return 0;
    final dateSet = _records.map((r) => DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day)).toSet().toList();
    dateSet.sort();
    var best = 1;
    var current = 1;
    for (int i = 1; i < dateSet.length; i++) {
      final diff = dateSet[i].difference(dateSet[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  int totalCount() => _records.length;

  double totalSavedAmount() => _records.where((r) => r.amount != null).fold(0.0, (sum, r) => sum + (r.amount ?? 0));

  double thisMonthSavedAmount() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _records
        .where((r) => r.createdAt.isAfter(startOfMonth) || r.createdAt.isAtSameMomentAs(startOfMonth))
        .where((r) => r.amount != null)
        .fold(0.0, (sum, r) => sum + (r.amount ?? 0));
  }

  double thisYearSavedAmount() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    return _records
        .where((r) => r.createdAt.isAfter(startOfYear) || r.createdAt.isAtSameMomentAs(startOfYear))
        .where((r) => r.amount != null)
        .fold(0.0, (sum, r) => sum + (r.amount ?? 0));
  }

  double thisWeekSavedAmount() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return _records
        .where((r) => r.createdAt.isAfter(startOfWeek) || r.createdAt.isAtSameMomentAs(startOfWeek))
        .where((r) => r.amount != null)
        .fold(0.0, (sum, r) => sum + (r.amount ?? 0));
  }

  double todaySavedAmount() {
    final startOfDay = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return _records
        .where((r) => r.createdAt.isAfter(startOfDay) || r.createdAt.isAtSameMomentAs(startOfDay))
        .where((r) => r.amount != null)
        .fold(0.0, (sum, r) => sum + (r.amount ?? 0));
  }

  List<Map<String, dynamic>> savedAmountByCategory() {
    final withAmount = _records.where((r) => r.amount != null).toList();
    final grouped = <String, List<ResistRecord>>{};
    for (final r in withAmount) {
      final key = r.effectiveCategoryID;
      grouped.putIfAbsent(key, () => []).add(r);
    }
    return grouped.entries.map((e) {
      final items = e.value;
      final emoji = items.first.categoryEmoji;
      final name = items.first.category;
      final total = items.where((r) => r.amount != null).fold(0.0, (sum, r) => sum + (r.amount ?? 0));
      return {
        'emoji': emoji,
        'name': name,
        'categoryID': e.key,
        'amount': total,
        'count': items.length,
      };
    }).toList()
      ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
  }

  List<Map<String, dynamic>> monthlySavedAmountTrend() {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int offset = -5; offset <= 0; offset++) {
      final date = DateTime(now.year, now.month + offset, 1);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final amount = _records
          .where((r) {
            final rKey = '${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}';
            return rKey == key && r.amount != null;
          })
          .fold(0.0, (sum, r) => sum + (r.amount ?? 0));
      final label = _monthLabel(date);
      result.add({'label': label, 'amount': amount});
    }
    return result;
  }

  String _monthLabel(DateTime date) {
    final labels = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    return labels[date.month - 1];
  }

  Map<String, dynamic>? bestSavedDay() {
    final withAmount = _records.where((r) => r.amount != null).toList();
    if (withAmount.isEmpty) return null;
    final grouped = <DateTime, double>{};
    for (final r in withAmount) {
      final day = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      grouped[day] = (grouped[day] ?? 0) + (r.amount ?? 0);
    }
    final best = grouped.entries.reduce((a, b) => a.value > b.value ? a : b);
    if (best.value <= 0) return null;
    return {'date': best.key, 'amount': best.value};
  }

  double averageSavedAmount() {
    final amounts = _records.where((r) => r.amount != null).map((r) => r.amount!).toList();
    if (amounts.isEmpty) return 0;
    return amounts.reduce((a, b) => a + b) / amounts.length;
  }

  int recordsWithAmountCount() => _records.where((r) => r.amount != null).length;
}
