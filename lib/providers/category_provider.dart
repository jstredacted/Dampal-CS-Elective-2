import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../services/category_service.dart';
import 'product_provider.dart';
import 'supabase_provider.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(ref.watch(supabaseProvider));
});

final categoryProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryServiceProvider).fetchCategories();
});

final categoryActionsProvider = Provider<CategoryActions>((ref) {
  return CategoryActions(ref);
});

// Admin actions for categories. After each change the category list and the
// product list (which shows category names) are reloaded.
class CategoryActions {
  CategoryActions(this._ref);

  final Ref _ref;

  Future<void> add(String name) async {
    await _ref.read(categoryServiceProvider).addCategory(name);
    _refresh();
  }

  Future<void> rename(int id, String name) async {
    await _ref.read(categoryServiceProvider).updateCategory(id, name);
    _refresh();
  }

  Future<void> delete(int id) async {
    await _ref.read(categoryServiceProvider).deleteCategory(id);
    _refresh();
  }

  void _refresh() {
    _ref.invalidate(categoryProvider);
    _ref.invalidate(productProvider);
  }
}
