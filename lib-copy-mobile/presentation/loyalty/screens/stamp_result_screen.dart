import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../domain/entities/customer.dart';
import '../../../../domain/entities/order.dart';
import '../../../../domain/entities/loyalty_stamp.dart';
import '../../../../data/local/providers.dart';
import '../widgets/stamp_card_widget.dart';
import '../../order/screens/receipt_screen.dart';

class StampResultScreen extends ConsumerStatefulWidget {
  final Customer customer;
  final Order order;

  const StampResultScreen({
    super.key,
    required this.customer,
    required this.order,
  });

  @override
  ConsumerState<StampResultScreen> createState() => _StampResultScreenState();
}

class _StampResultScreenState extends ConsumerState<StampResultScreen> {
  late ConfettiController _confettiController;
  bool _isAnimating = false;
  int _newTotalStamps = 0;
  int _stampsAdded = 0;
  bool _rewardReady = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _processStamps();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _processStamps() async {
    // Calculate eligible stamps (e.g., 1 stamp per item or based on total)
    // For this phase, let's assume 1 stamp per order containing items
    // Or simpler: 1 stamp per $5 (example logic, adjust as needed)
    // Rule: 1 stamp per drink. For now, let's default to 1 stamp per order for simplicity
    // unless order items suggest otherwise.
    // Let's count items.

    final eligibleCount = widget.order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    _stampsAdded = eligibleCount > 0
        ? eligibleCount
        : 1; // Fallback 1 if calculation fails

    // Max 9 stamps logic handled here or in repo?
    // Repository handles capping, but we want to show visual progress.

    final currentTotal = widget.customer.totalStamps;

    // Simulate API delay for dramatic effect
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final stamp = LoyaltyStamp(
        id: '', // Generate in repo
        customerId: widget.customer.id,
        orderId: widget.order.id,
        staffId: 'staff-001', // TODO: Get actual staff ID from auth
        stampsAdded: _stampsAdded,
        createdAt: DateTime.now(),
      );

      await ref.read(customerRepositoryProvider).addStamp(stamp);

      setState(() {
        _newTotalStamps = currentTotal + _stampsAdded;
        if (_newTotalStamps >= 9) {
          _rewardReady = true;
          _confettiController.play();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add stamps: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Loyalty Points',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer: ${widget.customer.name}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Stamp Card
                  StampCardWidget(
                    currentStamps: _newTotalStamps > 0
                        ? _newTotalStamps
                        : widget.customer.totalStamps,
                    maxStamps: 9,
                  ),

                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+$_stampsAdded Stamps Added!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  if (_rewardReady)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'FREE DRINK ELIGIBLE!',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text('Inform the customer they have a free reward.'),
                        ],
                      ),
                    ),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => ReceiptScreen(order: widget.order),
                          ),
                        );
                      },
                      child: const Text('DONE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
