import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class MonthlyTrendView extends StatefulWidget {
  final List<ResistRecord> records;

  const MonthlyTrendView({super.key, required this.records});

  @override
  State<MonthlyTrendView> createState() => _MonthlyTrendViewState();
}

class _MonthlyTrendViewState extends State<MonthlyTrendView> {
  int _selectedYear = DateTime.now().year;

  List<int> get _availableYears {
    final years = widget.records.map((r) => r.createdAt.year).toSet().toList();
    if (!years.contains(_selectedYear)) years.add(_selectedYear);
    return years..sort((a, b) => b.compareTo(a));
  }

  List<Map<String, dynamic>> get _monthlyData {
    final grouped = <String, int>{};
    for (final r in widget.records) {
      final key = '${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}';
      grouped[key] = (grouped[key] ?? 0) + 1;
    }

    final data = <Map<String, dynamic>>[];
    for (int month = 1; month <= 12; month++) {
      final key = '$_selectedYear-${month.toString().padLeft(2, '0')}';
      final labels = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
      data.add({
        'label': labels[month - 1],
        'count': grouped[key] ?? 0,
      });
    }
    return data;
  }

  int get _maxCount {
    final max = _monthlyData.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b);
    return max > 0 ? max : 1;
  }

  @override
  Widget build(BuildContext context) {
    final data = _monthlyData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(Icons.trending_up, color: AppColors.brand, size: 18),
              const Text('月度趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: _availableYears.map((year) {
                final isSelected = year == _selectedYear;
                return GestureDetector(
                  onTap: () => setState(() => _selectedYear = year),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brand : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (widget.records.isEmpty)
            Text('暂无数据', style: TextStyle(fontSize: 14, color: Colors.grey[600]))
          else
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 4,
                children: data.map((item) {
                  final count = item['count'] as int;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: 4,
                      children: [
                        if (count > 0)
                          Text(
                            '$count',
                            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                          ),
                        Container(
                          height: count > 0 ? (count / _maxCount) * 100 : 4,
                          decoration: BoxDecoration(
                            color: count > 0 ? AppColors.brand : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          item['label'] as String,
                          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
