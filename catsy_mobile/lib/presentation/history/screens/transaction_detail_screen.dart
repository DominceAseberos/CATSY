import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/routes/route_names.dart';
import '../../../data/local/providers.dart';
import '../../../data/local/database/app_database.dart';

// ── Detail provider (scoped to this screen) ───────────────────────────────────

final _orderDetailProvider = FutureProvider.family
    .autoDispose<
      ({
        OrdersTableData? order,
        List<(OrderItemsTableData, List<OrderItemAddonsTableData>)>
        itemsWithAddons,
      }),
      String
    >((ref, orderId) {
      return ref.watch(orderDaoProvider).getOrderWithItems(orderId);
    });

final _orderTransactionProvider = FutureProvider.family
    .autoDispose<TransactionsTableData?, String>(
      (ref, orderId) =>
          ref.watch(transactionDaoProvider).getTransactionForOrder(orderId),
    );

// ── Screen ────────────────────────────────────────────────────────────────────

class TransactionDetailScreen extends ConsumerWidget {
  /// The order ID passed via GoRouter extra.
  final String orderId;

  const TransactionDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_orderDetailProvider(orderId));
    final txAsync = ref.watch(_orderTransactionProvider(orderId));

    final currencyFmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load order: $e')),
        data: (detail) {
          final order = detail.order;
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Order header ──────────────────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Order Details',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          _StatusChip(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Date',
                        value: dateFmt.format(order.createdAt),
                      ),
                      _InfoRow(
                        label: 'Type',
                        value: order.orderType == 'dineIn'
                            ? 'Dine-In'
                            : 'Take-Out',
                      ),
                      if (order.tableId != null)
                        _InfoRow(label: 'Table', value: order.tableId!),
                      if (order.notes != null && order.notes!.isNotEmpty)
                        _InfoRow(label: 'Notes', value: order.notes!),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Items ─────────────────────────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items  (${detail.itemsWithAddons.length})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...detail.itemsWithAddons.map(
                        (pair) => _ItemRow(
                          item: pair.$1,
                          addons: pair.$2,
                          currencyFmt: currencyFmt,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Totals ────────────────────────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _TotalRow('Subtotal', currencyFmt.format(order.subtotal)),
                      if (order.discount > 0)
                        _TotalRow(
                          'Discount',
                          '− ${currencyFmt.format(order.discount)}',
                          valueColor: AppColors.error,
                        ),
                      _TotalRow('Tax', currencyFmt.format(order.tax)),
                      const Divider(height: 20),
                      _TotalRow(
                        'TOTAL',
                        currencyFmt.format(order.total),
                        bold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Payment info ──────────────────────────────────────
                txAsync.when(
                  loading: () => const SizedBox(
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (tx) => tx == null
                      ? const SizedBox.shrink()
                      : _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                label: 'Method',
                                value: tx.paymentMethod.toUpperCase(),
                              ),
                              _InfoRow(
                                label: 'Amount Paid',
                                value: currencyFmt.format(tx.amount),
                              ),
                              if (tx.change != null && tx.change! > 0)
                                _InfoRow(
                                  label: 'Change',
                                  value: currencyFmt.format(tx.change!),
                                ),
                              _InfoRow(
                                label: 'Time',
                                value: dateFmt.format(tx.transactedAt),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // ── View receipt button ───────────────────────────────
                ElevatedButton.icon(
                  onPressed: () => context.pushNamed(RouteNames.receiptPreview),
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('View / Print Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.bold = false, this.valueColor});
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 15 : 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 16 : 13,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.addons,
    required this.currencyFmt,
  });
  final OrderItemsTableData item;
  final List<OrderItemAddonsTableData> addons;
  final NumberFormat currencyFmt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${item.quantity}×',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                currencyFmt.format(item.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (item.specialInstructions != null &&
              item.specialInstructions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Text(
                '📝 ${item.specialInstructions}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (addons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Wrap(
                spacing: 4,
                children: addons.map((a) {
                  return Chip(
                    label: Text(
                      '${a.addonName} +${currencyFmt.format(a.price)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primaryLight.withValues(
                      alpha: 0.15,
                    ),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = AppColors.success;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
