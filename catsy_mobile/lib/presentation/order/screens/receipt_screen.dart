import 'package:flutter/material.dart';
import 'package:catsy_pos/domain/entities/order.dart'; // Ensure this matches your Order entity location
import 'package:intl/intl.dart';

class ReceiptScreen extends StatelessWidget {
  final Order order;

  const ReceiptScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Order Complete!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #${order.id}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return ListTile(
                    title: Text('Item ${index + 1} - ${item.productName}'),
                    trailing: Text(
                      '\$${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}',
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)}',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Return to home/catalog
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('NEW ORDER'),
            ),
          ],
        ),
      ),
    );
  }
}
