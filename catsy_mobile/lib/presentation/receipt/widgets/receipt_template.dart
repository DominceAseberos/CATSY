import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';

/// Branded on-screen receipt for Cutsy Café.
/// Accepts the raw Drift data objects so it can be used both
/// inside [ReceiptPreviewScreen] and for screenshot capture.
class ReceiptTemplate extends StatelessWidget {
  final OrdersTableData order;
  final List<(OrderItemsTableData, List<OrderItemAddonsTableData>)>
  itemsWithAddons;
  final TransactionsTableData? transaction;
  final String? receiptNumber;

  const ReceiptTemplate({
    super.key,
    required this.order,
    required this.itemsWithAddons,
    this.transaction,
    this.receiptNumber,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('₱#,##0.00', 'en_PH');
    final dateFmt = DateFormat('MMM d, yyyy  h:mm a');

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            color: const Color(0xFF5C3317),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: const Column(
              children: [
                Text(
                  'CUTSY CAFÉ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your Cozy Corner ☕',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '123 Brew Street, Café City\nTel: (02) 555-CAFE',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),

          // ── Receipt meta ─────────────────────────────────────────────
          Container(
            color: const Color(0xFFF5ECD7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                if (receiptNumber != null) ...[
                  _MetaRow(
                    label: 'Receipt #',
                    value: receiptNumber!,
                    bold: true,
                  ),
                  const _DottedLine(),
                ],
                _MetaRow(label: 'Date', value: dateFmt.format(order.createdAt)),
                _MetaRow(
                  label: 'Order #',
                  value: order.id.length > 8
                      ? order.id.substring(order.id.length - 8)
                      : order.id,
                ),
                _MetaRow(
                  label: 'Type',
                  value: order.orderType == 'dineIn' ? 'Dine-In' : 'Take-Out',
                ),
                if (order.tableId != null)
                  _MetaRow(label: 'Table', value: order.tableId!),
              ],
            ),
          ),

          const _DottedLine(horizontal: true),

          // ── Items ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ORDER ITEMS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C3317),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...itemsWithAddons.map(
                  (pair) => _ItemRow(
                    item: pair.$1,
                    addons: pair.$2,
                    currency: currency,
                  ),
                ),
              ],
            ),
          ),

          const _DottedLine(horizontal: true),

          // ── Totals ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                _TotalRow(
                  label: 'Subtotal',
                  value: currency.format(order.subtotal),
                ),
                if (order.discount > 0)
                  _TotalRow(
                    label: 'Discount',
                    value: '− ${currency.format(order.discount)}',
                    valueColor: AppColors.error,
                  ),
                _TotalRow(label: 'Tax', value: currency.format(order.tax)),
                const _DottedLine(),
                _TotalRow(
                  label: 'TOTAL',
                  value: currency.format(order.total),
                  bold: true,
                  fontSize: 18,
                ),
              ],
            ),
          ),

          // ── Payment ──────────────────────────────────────────────────
          if (transaction != null)
            Container(
              color: const Color(0xFFF5ECD7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DottedLine(),
                  const SizedBox(height: 4),
                  _MetaRow(
                    label: 'Payment',
                    value: transaction!.paymentMethod.toUpperCase(),
                  ),
                  _MetaRow(
                    label: 'Tendered',
                    value: currency.format(transaction!.amount),
                  ),
                  if (transaction!.change != null && transaction!.change! > 0)
                    _MetaRow(
                      label: 'Change',
                      value: currency.format(transaction!.change!),
                    ),
                ],
              ),
            ),

          const _DottedLine(horizontal: true),

          // ── Footer ───────────────────────────────────────────────────
          Container(
            color: const Color(0xFF5C3317),
            padding: const EdgeInsets.all(16),
            child: const Column(
              children: [
                Text(
                  'Thank you for visiting Cutsy Café!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Collect loyalty stamps with every purchase\nand earn FREE drinks! ☕',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _DottedLine extends StatelessWidget {
  final bool horizontal;
  const _DottedLine({this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: horizontal
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '- ' * 25,
        style: TextStyle(
          color: Colors.brown.withValues(alpha: 0.4),
          fontSize: 8,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF5C3317)),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(color: Colors.brown.withValues(alpha: 0.6)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
    this.fontSize = 13.0,
  });
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? const Color(0xFF1A1A1A) : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: valueColor ?? const Color(0xFF1A1A1A),
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
    required this.currency,
  });
  final OrderItemsTableData item;
  final List<OrderItemAddonsTableData> addons;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${item.quantity}×',
                style: const TextStyle(
                  color: Color(0xFF5C3317),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                currency.format(item.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
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
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ...addons.map(
            (a) => Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Row(
                children: [
                  const Text('+ ', style: TextStyle(color: Color(0xFF5C3317))),
                  Expanded(
                    child: Text(
                      a.addonName,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  Text(
                    currency.format(a.price),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
