import 'package:flutter/material.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';

/// Styled AppBar used across the app.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      automaticallyImplyLeading: showBackButton,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }
}
