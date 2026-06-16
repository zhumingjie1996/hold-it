import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class TimeOfDayView extends StatelessWidget {
  final List<ResistRecord> records;

  const TimeOfDayView({super.key, required this.records});

  List<Map<String, dynamic>> get _slots {
    final s = [
      {'label': '凌晨', 'shortLabel': '0-6', 'icon': Icons.nightlight_round, 'range': [0, 6], 'color': Colors.indigo, 'count': 0},
      {'label': '上午', 'shortLabel': '6-9', 'icon': Icons.wb_twilight, 'range': [6, 9], 'color': Colors.orange, 'count': 0},
      {'label': '午前', 'shortLabel': '9-12', 'icon': Icons.wb_sunny, 'range': [9, 12], 'color': Colors.yellow.shade700, 'count': 0},
      {'label': '下午', 'shortLabel': '12-15', 'icon': Icons.wb_cloudy, 'range': [12, 15], 'color': Colors.orange, 'count': 0},
      {'label': '傍晚', 'shortLabel': '15-18', 'icon': Icons.wb_twilight, 'range': [15, 18], 'color': Colors.pink, 'count': 0},
      {'label': '晚上', 'shortLabel': '18-24', 'icon': Icons.nights_stay, 'range': [18, 24], 'color': Colors.purple, 'count': 0},
    ];

    for (final r in records) {
      final hour = r.createdAt.hour;
      for (final slot in s) {
        final range = slot['range'] as List<int>;
        if (hour >= range[0] && hour < range[1]) {
          slot['count'] = (slot['count'] as int) + 1;
          break;
        }
      }
    }
    return s;
  }

  int get _total => _slots.fold(0, (sum, s) => sum + (s['count'] as int));

  Map<String, dynamic>? get _peakSlot {
    final max = _slots.reduce((a, b) => (a['count'] as int) > (b['count'] as int) ? a : b);
    return (max['count'] as int) > 0 ? max : null;
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slots;
    final total = _total;

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
              const Icon(Icons.access_time_filled, color: AppColors.brand, size: 18),
              const Text('时段分析', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_peakSlot != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    spacing: 4,
                    children: [
                      Icon(_peakSlot!['icon'] as IconData, size: 14, color: Colors.grey[600]),
                      Text(
                        _peakSlot!['label'] as String,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (records.isEmpty)
            Text('暂无数据', style: TextStyle(fontSize: 14, color: Colors.grey[600]))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: slots.map((slot) => _slotCircle(slot, total)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _slotCircle(Map<String, dynamic> slot, int total) {
    final pct = total > 0 ? (slot['count'] as int) / total : 0.0;
    final color = slot['color'] as Color;

    return SizedBox(
      width: 100,
      child: Column(
        spacing: 6,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 5,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                ),
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 5,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Icon(slot['icon'] as IconData, size: 16, color: color),
                ),
              ],
            ),
          ),
          Text(
            slot['shortLabel'] as String,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Text(
            '${slot['count']}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
