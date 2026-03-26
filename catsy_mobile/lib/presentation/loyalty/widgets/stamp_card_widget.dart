import 'package:flutter/material.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';

class StampCardWidget extends StatelessWidget {
  final int currentStamps;
  final int maxStamps;

  const StampCardWidget({
    super.key,
    required this.currentStamps,
    this.maxStamps = 9,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stamp Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: maxStamps,
          itemBuilder: (context, index) {
            final isStamped = index < currentStamps;
            final isRewardSlot = index == maxStamps - 1;

            return _AnimatedStampSlot(
              index: index,
              isStamped: isStamped,
              isRewardSlot: isRewardSlot,
            );
          },
        ),

        const SizedBox(height: 24),

        // Status Text
        if (currentStamps >= maxStamps)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              '🎉 REWARD UNLOCKED! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          )
        else
          Text(
            '${maxStamps - currentStamps} more stamps to verify reward',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
      ],
    );
  }
}

class _AnimatedStampSlot extends StatelessWidget {
  final int index;
  final bool isStamped;
  final bool isRewardSlot;

  const _AnimatedStampSlot({
    required this.index,
    required this.isStamped,
    required this.isRewardSlot,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween<double>(begin: isStamped ? 0.0 : 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              color: isStamped
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(100), // Circle
              border: Border.all(
                color: isStamped ? AppColors.primary : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: isStamped
                  ? const Icon(
                      Icons.pets, // Cat paw or similar
                      color: AppColors.primary,
                      size: 40,
                    )
                  : isRewardSlot
                  ? const Icon(
                      Icons.card_giftcard,
                      color: Colors.orange,
                      size: 32,
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
