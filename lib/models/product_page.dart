import 'product.dart';
import 'product_filter.dart';

// One page of products plus the total number of matching products,
// which is needed to know how many pages there are.
class ProductPage {
  const ProductPage({
    required this.items,
    required this.totalCount,
    required this.page,
  });

  final List<Product> items;
  final int totalCount;
  final int page;

  int get totalPages {
    if (totalCount == 0) return 1;
    // Round up: 21 products / 6 per page = 3.5, which means 4 pages.
    return (totalCount / productsPerPage).ceil();
  }

  bool get hasPrevious => page > 0;
  bool get hasNext => page < totalPages - 1;
}
