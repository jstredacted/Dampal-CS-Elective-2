import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/format.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.categoryName,
    this.onEdit,
    this.onDelete,
    this.onAddToCart,
    this.inCart = 0,
  });

  final Product product;
  final String? categoryName;
  // Admins get onEdit/onDelete. Customers get onAddToCart instead.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToCart;
  // How many of this product are already in the customer's cart.
  final int inCart;

  bool get _isAdminCard => onEdit != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _ProductImage(url: product.imageUrl)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categoryName != null)
                    Text(
                      categoryName!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatPeso(product.price),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    product.stock > 0
                        ? '${product.stock} in stock'
                        : 'Out of stock',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: product.stock > 0
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            if (_isAdminCard)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Edit ${product.name}',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: 'Delete ${product.name}',
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.all(8),
                child: _AddToCartButton(
                  product: product,
                  inCart: inCart,
                  onPressed: onAddToCart,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({
    required this.product,
    required this.inCart,
    required this.onPressed,
  });

  final Product product;
  final int inCart;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock <= 0;
    final atLimit = inCart >= product.stock;

    final String label;
    if (outOfStock) {
      label = 'Out of stock';
    } else if (atLimit) {
      label = 'All $inCart in cart';
    } else if (inCart > 0) {
      label = 'Add ($inCart in cart)';
    } else {
      label = 'Add to cart';
    }

    return FilledButton.tonalIcon(
      // A null onPressed disables the button.
      onPressed: outOfStock || atLimit ? null : onPressed,
      icon: const Icon(Icons.add_shopping_cart, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_not_supported_outlined)),
    );

    if (url.isEmpty) return placeholder;

    return Image.network(
      url,
      fit: BoxFit.cover,
      // Shows the placeholder instead of a red error box for broken links.
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
