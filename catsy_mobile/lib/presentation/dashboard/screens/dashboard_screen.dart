import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/routes/route_names.dart';
import '../../../data/local/providers.dart';
import '../../../sync/sync_providers.dart';
import '../../common_widgets/sync_progress_widget.dart';
import '../../table_management/providers/table_provider.dart';
import '../../table_management/widgets/table_tile.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isRestaurantOpen = ref.watch(restaurantOpenProvider);
    final tablesAsync = ref.watch(tablesProvider);
    final pendingPayments = ref.watch(pendingPaymentsCountProvider);
    final pendingReservations = ref.watch(pendingReservationsCountProvider);
    final tablesAttention = ref
        .watch(tablesProvider)
        .whenData(
          (tables) =>
              tables.where((t) => t.status.label == 'Bill Ready').length,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Restaurant Status Toggle
                GestureDetector(
                  onTap: () {
                    ref.read(restaurantOpenProvider.notifier).toggle();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isRestaurantOpen
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRestaurantOpen
                            ? AppColors.success
                            : AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRestaurantOpen
                              ? Icons.wb_sunny
                              : Icons.nightlight_round,
                          size: 16,
                          color: isRestaurantOpen
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isRestaurantOpen ? 'OPEN' : 'CLOSED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isRestaurantOpen
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                const Text(
                  'CATSY POS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Pending Payments Badge
                pendingPayments > 0
                    ? GestureDetector(
                        onTap: () => context.pushNamed(RouteNames.orderHistory),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.payment,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pendingPayments.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(),
                const SizedBox(width: 12),
                // Sync indicator / nav
                Consumer(
                  builder: (context, ref, _) {
                    final status = ref.watch(syncStatusProvider);
                    return IconButton(
                      tooltip: 'Sync Status',
                      onPressed: () => context.pushNamed(RouteNames.syncStatus),
                      icon: Badge(
                        isLabelVisible: status.failedCount > 0,
                        label: Text(status.failedCount.toString()),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        textColor: Colors.white,
                        child: Icon(
                          status.isSyncing
                              ? Icons.sync
                              : Icons.cloud_done_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                // Profile Dropdown
                _ProfileDropdown(),
              ],
            ),
          ),
          // Sync progress bar (collapses when idle)
          const SyncProgressWidget(),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Required Card
                  _ActionRequiredCard(
                    pendingPayments: pendingPayments,
                    pendingReservations: pendingReservations,
                    tablesAttention: tablesAttention,
                  ),
                  const SizedBox(height: 20),

                  // Tables Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TABLES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.pushNamed(RouteNames.tableManagement),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  tablesAsync.when(
                    data: (tables) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: tables.length > 8 ? 8 : tables.length,
                      itemBuilder: (context, index) =>
                          TableTile(table: tables[index]),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  const SizedBox(height: 8),
                  // Table Legend
                  _TableLegend(tablesAsync: tablesAsync),
                ],
              ),
            ),
          ),

          // ── Quick Actions Bar ────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan',
                  onTap: () => context.pushNamed(RouteNames.claimReward),
                ),
                _QuickActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Order',
                  onTap: () => context.pushNamed(RouteNames.productCatalog),
                ),
                _QuickActionButton(
                  icon: Icons.card_giftcard,
                  label: 'Rewards',
                  onTap: () => context.pushNamed(RouteNames.claimReward),
                ),
                _QuickActionButton(
                  icon: Icons.payment,
                  label: 'Pay',
                  onTap: () => context.pushNamed(RouteNames.orderHistory),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(),
    );
  }
}

class _ProfileDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              user.when(
                data: (u) => u?.name ?? 'Staff',
                loading: () => '...',
                error: (_, _) => 'Staff',
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.when(
                  data: (u) => u?.name ?? '',
                  loading: () => 'Loading...',
                  error: (_, _) => 'Staff',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Staff',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'stats',
          child: Row(
            children: [
              Icon(Icons.bar_chart, size: 20),
              SizedBox(width: 12),
              Text('My Stats'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'shift',
          child: Row(
            children: [
              Icon(Icons.access_time, size: 20),
              SizedBox(width: 12),
              Text('Shift Log'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, size: 20),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: AppColors.error),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(color: AppColors.error)),
            ],
          ),
          onTap: () {
            ref.read(authNotifierProvider.notifier).logout();
            context.go('/login');
          },
        ),
      ],
    );
  }
}

class _ActionRequiredCard extends StatelessWidget {
  final int pendingPayments;
  final AsyncValue<int> pendingReservations;
  final AsyncValue<int> tablesAttention;

  const _ActionRequiredCard({
    required this.pendingPayments,
    required this.pendingReservations,
    required this.tablesAttention,
  });

  @override
  Widget build(BuildContext context) {
    final hasActions =
        pendingPayments > 0 ||
        (pendingReservations.value ?? 0) > 0 ||
        (tablesAttention.value ?? 0) > 0;

    if (!hasActions) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withValues(alpha: 0.1),
            AppColors.error.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'ACTION REQUIRED',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.error,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (pendingPayments > 0)
                _ActionChip(
                  icon: Icons.payment,
                  label: 'Pay',
                  count: pendingPayments,
                  color: AppColors.warning,
                  onTap: () {},
                ),
              if ((pendingReservations.value ?? 0) > 0)
                _ActionChip(
                  icon: Icons.calendar_today,
                  label: 'Confirm',
                  count: pendingReservations.value ?? 0,
                  color: AppColors.info,
                  onTap: () => context.pushNamed(RouteNames.reservations),
                ),
              if ((tablesAttention.value ?? 0) > 0)
                _ActionChip(
                  icon: Icons.receipt_long,
                  label: 'Bill',
                  count: tablesAttention.value ?? 0,
                  color: AppColors.warning,
                  onTap: () {},
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableLegend extends StatelessWidget {
  final AsyncValue<List<dynamic>> tablesAsync;

  const _TableLegend({required this.tablesAsync});

  @override
  Widget build(BuildContext context) {
    return tablesAsync.when(
      data: (tables) {
        final available = tables
            .where((t) => t.status.label == 'Available')
            .length;
        final occupied = tables
            .where((t) => t.status.label == 'Occupied')
            .length;
        final reserved = tables
            .where((t) => t.status.label == 'Reserved')
            .length;
        final billReady = tables
            .where((t) => t.status.label == 'Bill Ready')
            .length;

        return Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (available > 0)
              _LegendItem(
                color: AppColors.success,
                label: 'Available ($available)',
              ),
            if (occupied > 0)
              _LegendItem(
                color: AppColors.error,
                label: 'Occupied ($occupied)',
              ),
            if (reserved > 0)
              _LegendItem(color: AppColors.info, label: 'Reserved ($reserved)'),
            if (billReady > 0)
              _LegendItem(
                color: AppColors.warning,
                label: 'Bill Ready ($billReady)',
              ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'Home',
                isSelected: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.receipt_long,
                label: 'Orders',
                isSelected: false,
                onTap: () => context.pushNamed(RouteNames.orderHistory),
              ),
              _NavItem(
                icon: Icons.sync,
                label: 'Sync',
                isSelected: false,
                onTap: () => context.pushNamed(RouteNames.syncStatus),
              ),
              _NavItem(
                icon: Icons.settings,
                label: 'Settings',
                isSelected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
