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

  Future<void> addCategory(String name) async {
    await _client.from('categories').insert({'name': name});
  }

  Future<void> updateCategory(int id, String name) async {
    final updated = await _client
        .from('categories')
        .update({'name': name})
        .eq('id', id)
        .select();
    if (updated.isEmpty) {
      throw const PostgrestException(
        message: 'Only admins can edit categories.',
        code: '42501',
      );
    }
  }

  Future<void> deleteCategory(int id) async {
    final deleted = await _client
        .from('categories')
        .delete()
        .eq('id', id)
        .select();
    if (deleted.isEmpty) {
      throw const PostgrestException(
        message: 'Only admins can delete categories.',
        code: '42501',
      );
    }
  }
}
