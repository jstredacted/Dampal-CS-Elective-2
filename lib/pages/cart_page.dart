import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../utils/errors.dart';
import '../utils/format.dart';
import '../widgets/message_view.dart';
import 'order_confirmation_page.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final receipt = await ref.read(checkoutProvider.notifier).checkout();

    if (receipt != null) {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationPage(receipt: receipt),
        ),
      );
      return;
    }
    final error = ref.read(checkoutProvider).error;
    // Replace any "Added to cart" message so the failure shows right away.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Checkout failed: ${error == null ? 'please try again.' : friendlyError(error)}',
        ),
      ),
    );
  }

  void _changeQuantity(
    BuildContext context,
    WidgetRef ref,
    CartItem item,
    int quantity,
  ) {
    final error = ref
        .read(cartProvider.notifier)
        .setQuantity(item.product.id, quantity);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);
    final checkingOut = ref.watch(checkoutProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: items.isEmpty
          ? MessageView(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty.',
              buttonLabel: 'Browse sneakers',
              onPressed: () => Navigator.pop(context),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final product = item.product;
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                '${formatPeso(product.price)} each · '
                                '${product.stock} in stock',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                formatPeso(item.subtotal),
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Decrease ${product.name}',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: checkingOut
                              ? null
                              : () => _changeQuantity(
                                  context,
                                  ref,
                                  item,
                                  item.quantity - 1,
                                ),
                        ),
                        Text(
                          '${item.quantity}',
                          style: theme.textTheme.titleMedium,
                        ),
                        IconButton(
                          tooltip: 'Increase ${product.name}',
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed:
                              checkingOut || item.quantity >= product.stock
                              ? null
                              : () => _changeQuantity(
                                  context,
                                  ref,
                                  item,
                                  item.quantity + 1,
                                ),
                        ),
                        IconButton(
                          tooltip: 'Remove ${product.name}',
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: checkingOut
                              ? null
                              : () => ref
                                    .read(cartProvider.notifier)
                                    .remove(product.id),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$count item${count == 1 ? '' : 's'}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'Total ${formatPeso(total)}',
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: checkingOut
                          ? null
                          : () => _checkout(context, ref),
                      icon: checkingOut
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_outline),
                      label: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
