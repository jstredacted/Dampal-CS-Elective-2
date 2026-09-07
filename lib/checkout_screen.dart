import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'product.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({required this.cart, super.key});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Confirmation')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Order Confirmed!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your shoes are ready for processing.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Order summary', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ...cart.items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(item.product.name),
                      subtitle: Text(
                        '${item.quantity} x ₱${item.product.price.toStringAsFixed(0)}',
                      ),
                      trailing: Text(
                        '₱${item.subtotal.toStringAsFixed(0)}',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Total: ₱${cart.total.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  key: const ValueKey('back-home-button'),
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
