import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'product.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    required this.product,
    required this.cart,
    super.key,
  });

  final Product product;
  final CartState cart;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool addedToCart = false;

  @override
  void initState() {
    super.initState();
    addedToCart = widget.cart.contains(widget.product);
    widget.cart.addListener(_updateAddedToCart);
  }

  void _updateAddedToCart() {
    final isInCart = widget.cart.contains(widget.product);
    if (isInCart == addedToCart) {
      return;
    }
    setState(() {
      addedToCart = isInCart;
    });
  }

  @override
  void dispose() {
    widget.cart.removeListener(_updateAddedToCart);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Detail'),
        actions: [
          IconButton(
            key: const ValueKey('detail-cart-button'),
            tooltip: 'Open cart',
            onPressed: () => context.push('/cart'),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: Image.asset(
                        widget.product.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.product.name,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${widget.product.price.toStringAsFixed(0)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('About this pair', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.local_shipping_outlined),
                        SizedBox(width: 10),
                        Expanded(child: Text('Free delivery within the city')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    key: const ValueKey('add-to-cart-button'),
                    onPressed: addedToCart
                        ? null
                        : () => widget.cart.add(widget.product),
                    icon: Icon(
                      addedToCart ? Icons.check : Icons.shopping_bag_outlined,
                    ),
                    label: Text(addedToCart ? 'Added to Cart' : 'Add to Cart'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
