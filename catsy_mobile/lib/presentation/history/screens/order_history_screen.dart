import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';
import 'package:catsy_pos/config/routes/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/presentation/history/providers/history_provider.dart';
import 'package:catsy_pos/presentation/common_widgets/empty_state_widget.dart';
import 'package:catsy_pos/presentation/common_widgets/shimmer_loading.dart';
import 'package:catsy_pos/presentation/common_widgets/animated_list_item.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _currencyFmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  final _dateFmt = DateFormat('MMM d, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      ref
          .read(historyNotifierProvider.notifier)
          .setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyNotifierProvider);
    final summaryAsync = ref.watch(dailySummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by order ID…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(historyNotifierProvider.notifier)
                              .setSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background,
                isDense: true,
              ),
              onChanged: (v) =>
                  ref.read(historyNotifierProvider.notifier).setSearch(v),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(historyNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Filter chips ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _FilterChipsRow(
                current: state.preset,
                onSelect: (preset) {
                  if (preset == DatePreset.custom) {
                    _pickCustomRange();
                  } else {
                    ref
                        .read(historyNotifierProvider.notifier)
                        .setPreset(preset);
                  }
                },
              ),
            ),

            // ── Summary bar ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: summaryAsync.when(
                data: (summary) => _SummaryBar(
                  orderCount: summary.orderCount,
                  totalSales: summary.totalSales,
                  currencyFmt: _currencyFmt,
                ),
                loading: () => const SizedBox(
                  height: 72,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

            // ── Order list ──────────────────────────────────────────────
            if (state.orders.isEmpty && !state.isLoading)
              SliverFillRemaining(
                child: _EmptyState(hasSearch: state.searchQuery.isNotEmpty),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < state.orders.length) {
                    final order = state.orders[index];
                    return AnimatedListItem(
                      index: index,
                      child: _OrderCard(
                        order: order,
                        currencyFmt: _currencyFmt,
                        dateFmt: _dateFmt,
                        onTap: () {
                          context.pushNamed(
                            RouteNames.transactionDetail,
                            extra: order.id,
                          );
                        },
                      ),
                    );
                  }
                  // Loading indicator at bottom
                  return state.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: ShimmerListTile(),
                        )
                      : const SizedBox.shrink();
                }, childCount: state.orders.length + (state.isLoading ? 1 : 0)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.current, required this.onSelect});
  final DatePreset current;
  final void Function(DatePreset) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: DatePreset.values.map((preset) {
          final isSelected = current == preset;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(preset.label),
              selected: isSelected,
              onSelected: (_) => onSelect(preset),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.orderCount,
    required this.totalSales,
    required this.currencyFmt,
  });
  final int orderCount;
  final double totalSales;
  final NumberFormat currencyFmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _SummaryStat(
            label: 'Orders',
            value: '$orderCount',
            icon: Icons.receipt_long,
          ),
          const Spacer(),
          const VerticalDivider(color: Colors.white38, width: 1),
          const Spacer(),
          _SummaryStat(
            label: 'Total Sales',
            value: currencyFmt.format(totalSales),
            icon: Icons.payments_outlined,
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.currencyFmt,
    required this.dateFmt,
    required this.onTap,
  });
  final OrdersTableData order;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final method = order.paymentMethod ?? '—';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFmt.format(order.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _PaymentBadge(method: method),
                        const SizedBox(width: 8),
                        _OrderTypeBadge(type: order.orderType),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Total
              Text(
                currencyFmt.format(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.method});
  final String method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.toUpperCase(),
        style: const TextStyle(
          color: AppColors.info,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _OrderTypeBadge extends StatelessWidget {
  const _OrderTypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isDineIn = type == 'dineIn';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isDineIn ? AppColors.success : AppColors.warning).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isDineIn ? 'DINE-IN' : 'TAKE-OUT',
        style: TextStyle(
          color: isDineIn ? AppColors.success : AppColors.warning,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: hasSearch ? Icons.search_off : Icons.receipt_long_outlined,
      title: hasSearch
          ? 'No orders match your search'
          : 'No completed orders found',
      subtitle: hasSearch
          ? 'Try a different search term'
          : 'Complete some orders and they will appear here',
    );
  }
}
