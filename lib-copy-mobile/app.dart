import 'package:flutter/material.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'presentation/common_widgets/connectivity_banner.dart';

/// Root widget of the CATSY POS application.
class CatsyPosApp extends StatelessWidget {
  const CatsyPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CATSY POS',
      debugShowCheckedModeBanner: false,

      // ── Theme ────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,

      // ── Routing ──────────────────────────────────────────────────────
      routerConfig: AppRouter.router,

      // ── Connectivity overlay ─────────────────────────────────────────
      builder: (context, child) {
        return Column(
          children: [
            const ConnectivityBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
