import 'package:flutter/material.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';

/// Small badge overlaid on an icon (e.g. notification count).
class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color iconColor;

  const BadgeIcon({
    super.key,
    required this.icon,
    this.count = 0,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: iconColor),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
