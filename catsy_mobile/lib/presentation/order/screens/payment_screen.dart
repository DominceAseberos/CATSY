// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:catsy_pos/config/routes/route_names.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';
import 'package:catsy_pos/core/error/app_error_handler.dart';
import 'package:catsy_pos/core/utils/app_audio.dart';
import 'package:catsy_pos/core/utils/app_haptics.dart';
import 'package:catsy_pos/data/local/providers.dart';
import 'package:catsy_pos/domain/enums/payment_method.dart';
import 'package:catsy_pos/domain/models/payment_details.dart';
import 'package:catsy_pos/presentation/common_widgets/error_snackbar.dart';
import 'package:catsy_pos/presentation/common_widgets/success_overlay.dart';
import 'package:catsy_pos/presentation/loyalty/screens/qr_scanner_screen.dart' as import_loyalty;
import 'package:catsy_pos/presentation/order/providers/cart_controller.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  Future<void> _processPayment(BuildContext context, dynamic cart) async {
    setState(() => _isProcessing = true);
    try {
      final payment = PaymentDetails(
        method: _selectedMethod,
        amountTendered: cart.total,
      );

      final order = await ref
          .read(orderRepositoryProvider)
          .createOrder(cart, payment);

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (!context.mounted) return;
      unawaited(AppAudio.playSuccess());
      unawaited(AppHaptics.mediumImpact());
      await SuccessOverlay.show(
        context,
        message: 'Payment Successful!',
      );

      if (!context.mounted) return;
      final wantLoyalty = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Collect Points?'),
          content: const Text(
            'Does the customer want to collect loyalty points?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('NO'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('YES'),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      if (wantLoyalty == true) {
        unawaited(Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => import_loyalty.QrScannerScreen(order: order),
          ),
        ));
      } else {
        context.goNamed(
          RouteNames.receiptPreview,
          extra: order.id,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorSnackBar.show(context, AppErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    '\$${cart.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ...PaymentMethod.values.map(
              (method) => RadioListTile<PaymentMethod>(
                title: Text(method.name.toUpperCase()),
                value: method,
                groupValue: _selectedMethod,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMethod = val);
                },
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed:
                    _isProcessing ? null : () => _processPayment(context, cart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'CHARGE & COMPLETE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
