import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../services/category_service.dart';
import 'supabase_provider.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(ref.watch(supabaseProvider));
});

final categoryProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryServiceProvider).fetchCategories();
});
