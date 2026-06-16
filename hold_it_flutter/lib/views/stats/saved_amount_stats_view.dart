import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class SavedAmountStatsView extends StatelessWidget {
  final List<ResistRecord> records;

  const SavedAmountStatsView({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    // This is a simplified version - full implementation would need AppState and StoreManager
    return Scaffold(
      appBar: AppBar(title: const Text('节省统计')),
      body: Center(
        child: Text('节省统计页面'),
      ),
    );
  }
}
