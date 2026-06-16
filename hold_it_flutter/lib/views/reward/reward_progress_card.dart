import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class RewardProgressCard extends StatelessWidget {
  final Reward reward;

  const RewardProgressCard({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to reward detail
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Row(
              spacing: 8,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: reward.imageData != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            reward.imageData!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(child: Text('🎁', style: TextStyle(fontSize: 16))),
                ),
                Expanded(
                  child: Text(
                    reward.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${reward.currentCoins} / ${reward.targetCoins}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brand),
                ),
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
                        width: constraints.maxWidth * reward.progress,
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
            if (reward.currentCoins < reward.targetCoins)
              Text(
                '距离解锁还差 ${reward.targetCoins - reward.currentCoins} 忍币',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }
}
