// Limits used by the price slider, in pesos.
const double minPriceLimit = 0;
const double maxPriceLimit = 15000;

// How many products one page shows.
const int productsPerPage = 6;

// Everything the shopper has chosen on the products page.
// page starts at 0, so page 0 is shown to the user as "Page 1".
class ProductFilter {
  const ProductFilter({
    this.search = '',
    this.categoryId,
    this.minPrice = minPriceLimit,
    this.maxPrice = maxPriceLimit,
    this.page = 0,
  });

  final String search;
  final int? categoryId;
  final double minPrice;
  final double maxPrice;
  final int page;

  bool get hasFilters =>
      search.trim().isNotEmpty ||
      categoryId != null ||
      minPrice != minPriceLimit ||
      maxPrice != maxPriceLimit;

  // clearCategory is needed because passing null for categoryId would
  // otherwise mean "keep the old category".
  ProductFilter copyWith({
    String? search,
    int? categoryId,
    bool clearCategory = false,
    double? minPrice,
    double? maxPrice,
    int? page,
  }) {
    return ProductFilter(
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      page: page ?? this.page,
    );
  }
}
