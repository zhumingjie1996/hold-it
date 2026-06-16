import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/app_state.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.records;

    final grouped = _groupRecords(records);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('时间线'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: records.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final entry = grouped.entries.elementAt(index);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    ...entry.value.map((r) => _TimelineRow(record: r)),
                  ],
                );
              },
            ),
    );
  }

  Map<String, List<ResistRecord>> _groupRecords(List<ResistRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = <String, List<ResistRecord>>{};
    for (final r in records) {
      final day = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      String key;
      if (day.isAtSameMomentAs(today)) {
        key = '今天';
      } else if (day.isAtSameMomentAs(yesterday)) {
        key = '昨天';
      } else {
        key = '${r.createdAt.month}月${r.createdAt.day}日';
      }
      grouped.putIfAbsent(key, () => []).add(r);
    }
    return grouped;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          const Text('💔', style: TextStyle(fontSize: 40)),
          const Text('暂无记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            '去首页记录你的第一次忍住吧',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ResistRecord record;

  const _TimelineRow({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 14,
        children: [
          Text(record.categoryEmoji, style: const TextStyle(fontSize: 28)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Text(
                      record.category,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    if (record.amount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '省 ¥${formatAmount(record.amount!)}',
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
                if (record.note.isNotEmpty)
                  Text(
                    record.note,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            timeString(record.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class RecordsListView extends StatefulWidget {
  final TimeFilter initialFilter;

  const RecordsListView({super.key, this.initialFilter = TimeFilter.all});

  @override
  State<RecordsListView> createState() => _RecordsListViewState();
}

class _RecordsListViewState extends State<RecordsListView> {
  late TimeFilter _timeFilter;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _timeFilter = widget.initialFilter;
  }

  List<ResistRecord> _filterRecords(List<ResistRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    return records.where((r) {
      final day = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      bool passTime;
      switch (_timeFilter) {
        case TimeFilter.all:
          passTime = true;
          break;
        case TimeFilter.today:
          passTime = day.isAtSameMomentAs(today);
          break;
        case TimeFilter.week:
          passTime = day.isAtSameMomentAs(startOfWeek) || day.isAfter(startOfWeek);
          break;
        case TimeFilter.month:
          passTime = day.isAtSameMomentAs(startOfMonth) || day.isAfter(startOfMonth);
          break;
        case TimeFilter.year:
          passTime = day.isAtSameMomentAs(startOfYear) || day.isAfter(startOfYear);
          break;
      }
      final passCategory = _selectedCategory == null || r.effectiveCategoryID == _selectedCategory;
      return passTime && passCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.records;
    final filtered = _filterRecords(records);

    final availableCategories = <String, Map<String, String>>{};
    for (final r in records) {
      if (!availableCategories.containsKey(r.effectiveCategoryID)) {
        availableCategories[r.effectiveCategoryID] = {
          'emoji': r.categoryEmoji,
          'name': r.category,
        };
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('全部记录'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (_selectedCategory != null || _timeFilter != TimeFilter.all)
            TextButton(
              onPressed: () => setState(() {
                _timeFilter = TimeFilter.all;
                _selectedCategory = null;
              }),
              child: const Text('重置'),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.background,
            child: SegmentedButton<TimeFilter>(
              segments: TimeFilter.values.map((f) {
                return ButtonSegment(
                  value: f,
                  label: Text(f.label),
                );
              }).toList(),
              selected: {_timeFilter},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  setState(() => _timeFilter = set.first);
                }
              },
            ),
          ),
          if (availableCategories.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppColors.background,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  spacing: 8,
                  children: [
                    _FilterChip(
                      label: '全部',
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    ...availableCategories.entries.map((e) => _FilterChip(
                      label: '${e.value['emoji']} ${e.value['name']}',
                      isSelected: _selectedCategory == e.key,
                      onTap: () => setState(() => _selectedCategory = _selectedCategory == e.key ? null : e.key),
                    )),
                  ],
                ),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _TimelineRow(record: filtered[index]),
                  ),
          ),
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
          const Text('💔', style: TextStyle(fontSize: 40)),
          const Text('暂无记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            _selectedCategory != null || _timeFilter != TimeFilter.all
                ? '换个筛选条件试试'
                : '去首页记录你的第一次忍住吧',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class SavedRecordsListView extends StatefulWidget {
  final TimeFilter initialFilter;

  const SavedRecordsListView({super.key, this.initialFilter = TimeFilter.all});

  @override
  State<SavedRecordsListView> createState() => _SavedRecordsListViewState();
}

class _SavedRecordsListViewState extends State<SavedRecordsListView> {
  late TimeFilter _timeFilter;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _timeFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('节省记录')),
      body: Center(child: Text('节省记录列表')),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? AppColors.brandDark : Colors.black,
          ),
        ),
      ),
    );
  }
}

enum TimeFilter {
  all('全部'),
  today('今天'),
  week('本周'),
  month('本月'),
  year('今年');

  final String label;
  const TimeFilter(this.label);
}
