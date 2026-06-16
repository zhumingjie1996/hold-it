import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class WeekdayDistributionView extends StatelessWidget {
  final List<ResistRecord> records;

  const WeekdayDistributionView({super.key, required this.records});

  final List<String> _weekdayNames = const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  List<int> get _weekdayCounts {
    final counts = List.filled(7, 0);
    for (final r in records) {
      // weekday: 1=Mon, 2=Tue ... 7=Sun in Flutter
      final wd = r.createdAt.weekday - 1; // 0=Mon, 6=Sun
      counts[wd]++;
    }
    return counts;
  }

  int get _maxCount {
    final max = _weekdayCounts.reduce((a, b) => a > b ? a : b);
    return max > 0 ? max : 1;
  }

  String? get _busiestDay {
    final counts = _weekdayCounts;
    final maxIdx = counts.indexOf(counts.reduce((a, b) => a > b ? a : b));
    return counts[maxIdx] > 0 ? _weekdayNames[maxIdx] : null;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _weekdayCounts;
    final max = _maxCount;

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
              const Icon(Icons.calendar_view_week, color: AppColors.brand, size: 18),
              const Text('周几最忍住', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_busiestDay != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _busiestDay!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
          if (records.isEmpty)
            Text('暂无数据', style: TextStyle(fontSize: 14, color: Colors.grey[600]))
          else
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 4,
                children: List.generate(7, (index) {
                  final count = counts[index];
                  final isMax = count == max && count > 0;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: 6,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isMax ? AppColors.brand : Colors.grey[600],
                          ),
                        ),
                        Container(
                          width: 28,
                          height: count > 0 ? (count / max) * 100 : 4,
                          decoration: BoxDecoration(
                            color: isMax ? AppColors.brand : AppColors.brand.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Text(
                          _weekdayNames[index],
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
