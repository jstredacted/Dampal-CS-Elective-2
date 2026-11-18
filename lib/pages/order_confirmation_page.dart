import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/format.dart';
import 'order_history_page.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key, required this.receipt});

  final OrderReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Order placed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Thank you!', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Order #${receipt.orderId}',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                'Total paid ${formatPeso(receipt.total)}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                ),
                child: const Text('View my orders'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
