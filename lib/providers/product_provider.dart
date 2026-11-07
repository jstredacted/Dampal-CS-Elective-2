import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../models/product_page.dart';
import '../services/product_service.dart';
import 'product_filter_provider.dart';
import 'supabase_provider.dart';

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(ref.watch(supabaseProvider));
});

final productProvider = AsyncNotifierProvider<ProductNotifier, ProductPage>(
  ProductNotifier.new,
);

class ProductNotifier extends AsyncNotifier<ProductPage> {
  // build runs again whenever productFilterProvider changes, so a new
  // search, category, price range, or page automatically re-queries Supabase.
  @override
  Future<ProductPage> build() {
    final filter = ref.watch(productFilterProvider);
    return ref.read(productServiceProvider).fetchProducts(filter);
  }

  Future<void> addProduct(Product product) async {
    await ref.read(productServiceProvider).addProduct(product);
    // New products are sorted first, so jump to page 1 to show it.
    ref.read(productFilterProvider.notifier).setPage(0);
    ref.invalidateSelf();
  }

  Future<void> updateProduct(Product product) async {
    await ref.read(productServiceProvider).updateProduct(product);
    ref.invalidateSelf();
  }

  Future<void> deleteProduct(int id) async {
    await ref.read(productServiceProvider).deleteProduct(id);

    // If that was the only product on this page, go back one page.
    final current = state.value;
    if (current != null && current.items.length == 1 && current.hasPrevious) {
      ref.read(productFilterProvider.notifier).setPage(current.page - 1);
    }
    ref.invalidateSelf();
  }
}
