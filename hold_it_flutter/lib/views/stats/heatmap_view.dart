import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class HeatmapView extends StatelessWidget {
  final List<ResistRecord> records;

  const HeatmapView({super.key, required this.records});

  List<Map<String, dynamic>> get _heatmapData {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 104)); // 15 columns * 7 days

    final grouped = <DateTime, int>{};
    for (final r in records) {
      final day = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      grouped[day] = (grouped[day] ?? 0) + 1;
    }

    final data = <Map<String, dynamic>>[];
    var currentDate = startDate;
    while (currentDate.isBefore(today) || currentDate.isAtSameMomentAs(today)) {
      data.add({
        'date': currentDate,
        'count': grouped[currentDate] ?? 0,
      });
      currentDate = currentDate.add(const Duration(days: 1));
    }
    return data;
  }

  Color _colorForCount(int count) {
    if (count == 0) return Colors.grey[300]!;
    if (count == 1) return Colors.green.withOpacity(0.3);
    if (count <= 3) return Colors.green.withOpacity(0.5);
    if (count <= 5) return Colors.green.withOpacity(0.7);
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final data = _heatmapData;

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
              const Icon(Icons.calendar_today, color: AppColors.brand, size: 18),
              const Text('热力图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (records.isEmpty)
            Text(
              '记录越多，热力图越丰富',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            )
          else
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: data.map((item) {
                return Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _colorForCount(item['count'] as int),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }).toList(),
            ),
          Row(
            spacing: 4,
            children: [
              Text('少', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              for (int i = 0; i < 5; i++)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _colorForCount(i),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Text('多', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}
