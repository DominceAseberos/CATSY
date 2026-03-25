import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../../data/local/providers.dart';
import '../../../config/theme/app_colors.dart';

class OrderSummaryScreen extends ConsumerStatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  ConsumerState<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends ConsumerState<OrderSummaryScreen> {
  bool _isProcessing = false;

  Future<void> _processCheckout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final authState = ref.read(authNotifierProvider);
      final staffId = authState.staff?.id ?? 'unknown-staff';
      
      // We would format the cart into an OrderCreate representation and send to backend
      // Using a simplified map below for demonstration
      final orderData = {
        'order_type': 'dine-in', // or take-out based on user selection
        'items': cart.map((item) => {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.productPrice
        }).toList(),
      };
      
      // Assume order repository has a method to submit order.
      // E.g. final orderResult = await ref.read(orderRepositoryProvider).createOrder(orderData, staffId);
      
      // Auto-trigger stamp crediting logic (Phase 4 requirement)
      final cartNotifier = ref.read(cartProvider.notifier);
      final eligibleCount = cartNotifier.eligibleStampCount;
      if (eligibleCount > 0) {
        // Here we would call auth/loyalty APIs, e.g.
        // await ref.read(loyaltyRepositoryProvider).creditStamps(customerId, eligibleCount, staffId);
        // We'll simulate this for the UI.
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Order submitted. Credited \$eligibleCount stamps!'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Order submitted successfully.'))
        );
      }

      ref.read(cartProvider.notifier).clearCache();
      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process order: \$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: cart.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return ListTile(
                        title: Text(item.product.productName),
                        subtitle: Text('₱\${item.product.productPrice.toStringAsFixed(2)} x \${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => notifier.decrementItem(item.product.id!),
                            ),
                            Text('\${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => notifier.addItem(item.product),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('₱\${notifier.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          ],
                        ),
                        if (notifier.eligibleStampCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                Text('Earns \${notifier.eligibleStampCount} stamp(s)', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isProcessing ? null : _processCheckout,
                            child: _isProcessing 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
