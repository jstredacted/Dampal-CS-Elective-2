import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'product.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({required this.cart, super.key});

  final CartState cart;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: SafeArea(
        child: widget.cart.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your cart is empty',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Browse Shoes'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: widget.cart.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.cart.items[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    item.product.imagePath,
                                    width: 92,
                                    height: 92,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Subtotal: ₱${item.subtotal.toStringAsFixed(0)}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            key: ValueKey(
                                              'decrease-${item.product.id}',
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                widget.cart.decrease(
                                                  item.product,
                                                );
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: theme.textTheme.labelLarge,
                                          ),
                                          IconButton(
                                            key: ValueKey(
                                              'increase-${item.product.id}',
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                widget.cart.add(item.product);
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    color: theme.colorScheme.surfaceContainerLow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Total: ₱${widget.cart.total.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          key: const ValueKey('checkout-button'),
                          onPressed: () => context.push('/checkout'),
                          child: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
