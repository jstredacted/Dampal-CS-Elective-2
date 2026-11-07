import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';

// One page for both adding and editing.
// product == null → Add (empty form). product != null → Edit (prefilled).
class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _imageUrl = TextEditingController();
  int? _categoryId;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    // Prefill the fields only when editing; adding keeps them empty.
    if (product != null) {
      _name.text = product.name;
      _desc.text = product.description;
      _price.text = product.price.toStringAsFixed(2);
      _stock.text = product.stock.toString();
      _imageUrl.text = product.imageUrl;
      _categoryId = product.categoryId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _name.text.trim();
    try {
      final notifier = ref.read(productProvider.notifier);
      // we have 2 methods for creating & updating, hence the if/else
      if (_isEditing) {
        await notifier.updateProduct(
          widget.product!.copyWith(
            name: name,
            description: _desc.text.trim(),
            price: double.parse(_price.text.trim()),
            stock: int.parse(_stock.text.trim()),
            imageUrl: _imageUrl.text.trim(),
            categoryId: _categoryId,
          ),
        );
      } else {
        await notifier.addProduct(
          Product(
            id: 0, // Supabase creates the real id.
            name: name,
            description: _desc.text.trim(),
            price: double.parse(_price.text.trim()),
            stock: int.parse(_stock.text.trim()),
            imageUrl: _imageUrl.text.trim(),
            categoryId: _categoryId,
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, _isEditing ? 'Updated $name' : 'Added $name');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit product' : 'Add product')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) => _required(v, 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(
                    labelText: 'Price (₱)',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final empty = _required(v, 'Price');
                    if (empty != null) return empty;
                    final price = double.tryParse(v!.trim());
                    if (price == null || price <= 0) {
                      return 'Enter a price greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stock,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final empty = _required(v, 'Stock');
                    if (empty != null) return empty;
                    final stock = int.tryParse(v!.trim());
                    if (stock == null || stock < 0) {
                      return 'Enter a whole number, 0 or more';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  hint: Text(
                    categoriesAsync.isLoading
                        ? 'Loading categories…'
                        : 'Choose a category',
                  ),
                  items: [
                    for (final category in categoriesAsync.value ?? [])
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: (value) =>
                      value == null ? 'Choose a category' : null,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isEditing ? 'Save changes' : 'Add product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
