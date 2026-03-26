import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';
import 'package:catsy_pos/config/routes/route_names.dart';
import 'package:catsy_pos/data/local/providers.dart';
import 'package:catsy_pos/presentation/receipt/providers/receipt_provider.dart';
import 'package:catsy_pos/presentation/receipt/widgets/receipt_template.dart';

class ReceiptPreviewScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ReceiptPreviewScreen({super.key, required this.orderId});

  @override
  ConsumerState<ReceiptPreviewScreen> createState() =>
      _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
  @override
  void initState() {
    super.initState();
    // FamilyNotifier.build() auto-triggers PDF generation when first watched.
  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptNotifierProvider(widget.orderId));
    final receiptNumber = receiptState.receiptNumber;

    return Scaffold(
      backgroundColor: const Color(0xFFF5ECD7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C3317),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Receipt',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            receiptNumber.when(
              data: (rcptNum) => Text(
                rcptNum,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              loading: () => const Text(
                'Generating...',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              error: (_, st) => const SizedBox.shrink(),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Done',
          onPressed: () => context.goNamed(RouteNames.dashboard),
        ),
        elevation: 0,
      ),
      body: _OrderDetailLoader(
        orderId: widget.orderId,
        receiptState: receiptState,
      ),
      bottomNavigationBar: _ActionBar(
        orderId: widget.orderId,
        receiptState: receiptState,
      ),
    );
  }
}

// ── Order detail loader ───────────────────────────────────────────────────────

class _OrderDetailLoader extends ConsumerWidget {
  final String orderId;
  final ReceiptState receiptState;

  const _OrderDetailLoader({required this.orderId, required this.receiptState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderDao = ref.watch(orderDaoProvider);
    final txDao = ref.watch(transactionDaoProvider);

    return FutureBuilder(
      future: Future.wait([
        orderDao.getOrderWithItems(orderId),
        txDao.getTransactionForOrder(orderId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5C3317)),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                SizedBox(height: 12),
                Text('Could not load receipt'),
              ],
            ),
          );
        }

        final detail = snapshot.data![0] as dynamic;
        final tx = snapshot.data![1] as dynamic;
        final order = detail.order;

        if (order == null) {
          return const Center(child: Text('Order not found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.antiAlias,
                child: ReceiptTemplate(
                  order: order,
                  itemsWithAddons: detail.itemsWithAddons,
                  transaction: tx,
                  receiptNumber: receiptState.receiptNumber.asData?.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  final String orderId;
  final ReceiptState receiptState;

  const _ActionBar({required this.orderId, required this.receiptState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(receiptNotifierProvider(orderId).notifier);
    final receiptNumber = receiptState.receiptNumber.asData?.value ?? 'REC';

    return Container(
      color: const Color(0xFF5C3317),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.share_rounded,
              label: 'Share PDF',
              loading: receiptState.isSharingPdf,
              onTap: () async {
                await notifier.sharePdf(receiptNumber: receiptNumber);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.print_rounded,
              label: 'Print',
              loading: receiptState.isPrinting,
              onTap: () async {
                final success = await notifier.printSunmi();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '✅ Printed successfully'
                          : '⚠️ Printer not available on this device',
                    ),
                    backgroundColor: success
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.check_circle_rounded,
              label: 'Done',
              onTap: () => context.goNamed(RouteNames.dashboard),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
