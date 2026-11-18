import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/product_page.dart';
import '../providers/cart_provider.dart';
import '../providers/category_provider.dart';
import '../providers/product_filter_provider.dart';
import '../providers/product_provider.dart';
import '../providers/user_provider.dart';
import '../utils/errors.dart';
import '../widgets/account_button.dart';
import '../widgets/message_view.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/price_filter.dart';
import '../widgets/product_card.dart';
import 'admin_orders_page.dart';
import 'cart_page.dart';
import 'categories_page.dart';
import 'order_history_page.dart';
import 'product_form_page.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // The same form page is used for adding (product == null) and editing.
  Future<void> _openForm(Product? product) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
    );
    if (message != null && mounted) _showMessage(message);
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(productProvider.notifier).deleteProduct(product.id);
      _showMessage('Deleted ${product.name}');
    } catch (error) {
      _showMessage('Could not delete product: ${friendlyError(error)}');
    }
  }

  void _addToCart(Product product) {
    final error = ref.read(cartProvider.notifier).add(product);
    _showMessage(error ?? 'Added ${product.name} to your cart');
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(productFilterProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);
    final categories = ref.watch(categoryProvider).value ?? const <Category>[];
    final isAdmin = ref.watch(isAdminProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Sole Street · Admin' : 'Sole Street'),
        actions: [
          IconButton(
            tooltip: 'Refresh products',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productProvider),
          ),
          if (isAdmin) ...[
            IconButton(
              tooltip: 'Categories',
              icon: const Icon(Icons.category_outlined),
              onPressed: () => _open(const CategoriesPage()),
            ),
            IconButton(
              tooltip: 'All orders',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => _open(const AdminOrdersPage()),
            ),
          ] else ...[
            IconButton(
              tooltip: 'My orders',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => _open(const OrderHistoryPage()),
            ),
            IconButton(
              tooltip: 'Cart',
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              onPressed: () => _open(const CartPage()),
            ),
          ],
          const AccountButton(),
          const SizedBox(width: 8),
        ],
      ),
      // Only admins can add products.
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _Filters(
                    searchController: _searchController,
                    categories: categories,
                    onClear: _clearFilters,
                  ),
                ),
              ),
              // Keeps the old products visible while the next page loads.
              if (productsAsync.isLoading && productsAsync.hasValue)
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
              ...productsAsync.when(
                skipLoadingOnReload: true,
                data: (productPage) =>
                    _productSlivers(productPage, categories, isAdmin),
                error: (error, stackTrace) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: MessageView(
                      icon: isPermissionDenied(error)
                          ? Icons.lock_outline
                          : Icons.cloud_off,
                      title: 'Could not load products.',
                      detail: friendlyError(error),
                      buttonLabel: 'Try again',
                      onPressed: () => ref.invalidate(productProvider),
                    ),
                  ),
                ],
                loading: () => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _productSlivers(
    ProductPage productPage,
    List<Category> categories,
    bool isAdmin,
  ) {
    if (productPage.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MessageView(
            icon: Icons.search_off,
            title: 'No sneakers match your filters.',
            buttonLabel: 'Clear filters',
            onPressed: _clearFilters,
          ),
        ),
      ];
    }

    String? categoryName(int? id) {
      for (final category in categories) {
        if (category.id == id) return category.name;
      }
      return null;
    }

    // Watching the cart here updates the "in cart" counts on each card.
    ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverGrid.builder(
          // Each card is at most 240 wide, so wider screens fit more columns.
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 340,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: productPage.items.length,
          itemBuilder: (context, index) {
            final product = productPage.items[index];
            return ProductCard(
              product: product,
              categoryName: categoryName(product.categoryId),
              onEdit: isAdmin ? () => _openForm(product) : null,
              onDelete: isAdmin ? () => _confirmDelete(product) : null,
              onAddToCart: isAdmin ? null : () => _addToCart(product),
              inCart: cart.quantityOf(product.id),
            );
          },
        ),
      ),
      SliverPadding(
        // Extra bottom space so the floating button does not cover the bar.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        sliver: SliverToBoxAdapter(
          child: PaginationBar(
            productPage: productPage,
            onPageChanged: (page) =>
                ref.read(productFilterProvider.notifier).setPage(page),
          ),
        ),
      ),
    ];
  }
}

class _Filters extends ConsumerWidget {
  const _Filters({
    required this.searchController,
    required this.categories,
    required this.onClear,
  });

  final TextEditingController searchController;
  final List<Category> categories;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);
    final filterNotifier = ref.read(productFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search sneakers',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: filterNotifier.setSearch,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: filter.categoryId == null,
              onSelected: (_) => filterNotifier.setCategory(null),
            ),
            for (final category in categories)
              ChoiceChip(
                label: Text(category.name),
                selected: filter.categoryId == category.id,
                onSelected: (_) => filterNotifier.setCategory(category.id),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const PriceFilter(),
        if (filter.hasFilters)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear filters'),
            ),
          ),
      ],
    );
  }
}
