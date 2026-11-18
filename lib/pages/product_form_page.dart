import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../utils/errors.dart';

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
  // The saved image link, and a newly picked image that is not uploaded yet.
  String _imageUrl = '';
  Uint8List? _pickedBytes;
  String? _pickedName;
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
      _imageUrl = product.imageUrl;
      _categoryId = product.categoryId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Smaller files upload faster and load faster in the shop.
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
      _pickedName = file.name;
    });
  }

  void _removeImage() {
    setState(() {
      _pickedBytes = null;
      _pickedName = null;
      _imageUrl = '';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _name.text.trim();
    try {
      final notifier = ref.read(productProvider.notifier);
      // Upload first, so the product row is saved with the image's link.
      var imageUrl = _imageUrl;
      if (_pickedBytes != null) {
        imageUrl = await notifier.uploadImage(_pickedBytes!, _pickedName!);
      }

      // we have 2 methods for creating & updating, hence the if/else
      if (_isEditing) {
        await notifier.updateProduct(
          widget.product!.copyWith(
            name: name,
            description: _desc.text.trim(),
            price: double.parse(_price.text.trim()),
            stock: int.parse(_stock.text.trim()),
            imageUrl: imageUrl,
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
            imageUrl: imageUrl,
            categoryId: _categoryId,
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, _isEditing ? 'Updated $name' : 'Added $name');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: ${friendlyError(error)}')),
      );
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
                    if (price == null || price < 0) {
                      return 'Enter a price of 0 or more';
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
                const SizedBox(height: 16),
                _ImagePickerField(
                  pickedBytes: _pickedBytes,
                  imageUrl: _imageUrl,
                  onPick: _saving ? null : _pickImage,
                  onRemove: _saving ? null : _removeImage,
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

// Shows the current or newly picked image with buttons to change or remove it.
class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.pickedBytes,
    required this.imageUrl,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? pickedBytes;
  final String imageUrl;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = pickedBytes != null || imageUrl.isNotEmpty;

    final Widget preview;
    if (pickedBytes != null) {
      preview = Image.memory(pickedBytes!, fit: BoxFit.cover);
    } else if (imageUrl.isNotEmpty) {
      preview = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image_outlined)),
      );
    } else {
      preview = const Center(child: Icon(Icons.image_outlined, size: 40));
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.square(
            dimension: 96,
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: preview,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Image (optional)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_outlined),
                    label: Text(hasImage ? 'Change image' : 'Choose image'),
                  ),
                  if (hasImage)
                    TextButton(
                      onPressed: onRemove,
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
