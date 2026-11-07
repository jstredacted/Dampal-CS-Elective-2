import 'package:flutter/material.dart';

import '../models/product_page.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.productPage,
    required this.onPageChanged,
  });

  final ProductPage productPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final page = productPage.page;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: productPage.hasPrevious
              ? () => onPageChanged(page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Previous'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                'Page ${page + 1} of ${productPage.totalPages}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${productPage.totalCount} products',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: productPage.hasNext ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
          iconAlignment: IconAlignment.end,
          label: const Text('Next'),
        ),
      ],
    );
  }
}
