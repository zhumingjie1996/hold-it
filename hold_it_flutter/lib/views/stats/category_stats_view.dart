import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class CategoryStatsView extends StatelessWidget {
  final List<ResistRecord> records;

  const CategoryStatsView({super.key, required this.records});

  List<Map<String, dynamic>> get _categoryStats {
    final merged = <String, Map<String, dynamic>>{};
    for (final r in records) {
      final key = r.effectiveCategoryID;
      if (merged.containsKey(key)) {
        merged[key]!['count'] = merged[key]!['count'] + 1;
      } else {
        merged[key] = {
          'emoji': r.categoryEmoji,
          'name': r.category,
          'count': 1,
        };
      }
    }
    final total = records.length;
    return merged.values.map((info) {
      final count = info['count'] as int;
      return {
        ...info,
        'percentage': total > 0 ? count / total : 0.0,
      };
    }).toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  @override
  Widget build(BuildContext context) {
    final stats = _categoryStats;

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
              const Icon(Icons.pie_chart, color: AppColors.brand, size: 18),
              const Text('分类统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (stats.isEmpty)
            Text('暂无数据', style: TextStyle(fontSize: 14, color: Colors.grey[600]))
          else
            Column(
              spacing: 12,
              children: stats.map((stat) => _CategoryBar(
                emoji: stat['emoji'] as String,
                name: stat['name'] as String,
                count: stat['count'] as int,
                percentage: stat['percentage'] as double,
              )).toList(),
            ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String emoji;
  final String name;
  final int count;
  final double percentage;

  const _CategoryBar({
    required this.emoji,
    required this.name,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 6,
      children: [
        Row(
          children: [
            Text('$emoji $name', style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Text('$count 次', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: constraints.maxWidth * percentage,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
