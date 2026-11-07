import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';

class CategoryService {
  CategoryService(this._client);

  final SupabaseClient _client;

  Future<List<Category>> fetchCategories() async {
    final data = await _client
        .from('categories')
        .select()
        // order() sorts in descending order unless ascending is true.
        .order('name', ascending: true);
    return data.map(Category.fromMap).toList();
  }
}
