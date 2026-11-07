import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../models/product_filter.dart';
import '../models/product_page.dart';

class ProductService {
  // constructor that takes a SupabaseClient instance
  ProductService(this._client);

  final SupabaseClient _client;

  // Adds the search, category, and price filters to any products query.
  PostgrestFilterBuilder<T> _applyFilters<T>(
    PostgrestFilterBuilder<T> query,
    ProductFilter filter,
  ) {
    final term = filter.search.trim();
    if (term.isNotEmpty) {
      query = query.ilike('name', '%$term%');
    }
    if (filter.categoryId != null) {
      query = query.eq('category_id', filter.categoryId!);
    }
    return query.gte('price', filter.minPrice).lte('price', filter.maxPrice);
  }

  Future<ProductPage> fetchProducts(ProductFilter filter) async {
    try {
      return await _fetchPage(filter, filter.page);
    } on PostgrestException catch (error) {
      // PGRST103 means the page no longer exists, for example after the last
      // product on the last page was deleted. Load the new last page instead.
      if (error.code != 'PGRST103') rethrow;
      final total = await _applyFilters(
        _client.from('products').count(CountOption.exact),
        filter,
      );
      final lastPage = total == 0 ? 0 : (total - 1) ~/ productsPerPage;
      return _fetchPage(filter, lastPage);
    }
  }

  Future<ProductPage> _fetchPage(ProductFilter filter, int page) async {
    // range uses row positions that start at 0 and includes both ends.
    // Page 0 → rows 0-5, page 1 → rows 6-11, and so on.
    final from = page * productsPerPage;
    final to = from + productsPerPage - 1;

    final response =
        await _applyFilters(_client.from('products').select(), filter)
            .order('created_at', ascending: false)
            .range(from, to)
            .count(CountOption.exact);

    return ProductPage(
      items: response.data.map(Product.fromMap).toList(),
      totalCount: response.count,
      page: page,
    );
  }

  Future<void> addProduct(Product product) async {
    await _client.from('products').insert(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    final updatedProds = await _client
        .from('products')
        .update(product.toMap())
        .eq('id', product.id)
        .select();

    // Supabase returns no rows (instead of an error) when nothing matched,
    // including when a row-level security policy blocks the update.
    if (updatedProds.isEmpty) {
      throw Exception(
        'Product with id ${product.id} not found, or check the table RLS.',
      );
    }
  }

  Future<void> deleteProduct(int id) async {
    await _client.from('products').delete().eq('id', id);
  }
}
