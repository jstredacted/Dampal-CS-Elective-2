import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_filter.dart';

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(
      ProductFilterNotifier.new,
    );

class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => const ProductFilter();

  // Changing a filter goes back to the first page, because the old page
  // number may not exist in the new, smaller list.
  void setSearch(String search) {
    state = state.copyWith(search: search, page: 0);
  }

  void setCategory(int? categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
      page: 0,
    );
  }

  void setPriceRange(double minPrice, double maxPrice) {
    state = state.copyWith(minPrice: minPrice, maxPrice: maxPrice, page: 0);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void clear() {
    state = const ProductFilter();
  }
}
