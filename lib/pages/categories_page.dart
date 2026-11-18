import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../utils/errors.dart';
import '../widgets/message_view.dart';

// Admin only: add, rename, and delete product categories.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String success,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _CategoryNameDialog(title: 'Add category'),
    );
    if (name == null || !context.mounted) return;
    await _run(
      context,
      () => ref.read(categoryActionsProvider).add(name),
      'Added $name',
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryNameDialog(
        title: 'Rename category',
        initialName: category.name,
      ),
    );
    if (name == null || name == category.name || !context.mounted) return;
    await _run(
      context,
      () => ref.read(categoryActionsProvider).rename(category.id, name),
      'Renamed to $name',
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete "${category.name}"? Its products stay in the shop '
          'without a category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(
      context,
      () => ref.read(categoryActionsProvider).delete(category.id),
      'Deleted ${category.name}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const MessageView(
              icon: Icons.category_outlined,
              title: 'No categories yet.',
              detail: 'Tap "Add category" to create one.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Rename ${category.name}',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _rename(context, ref, category),
                    ),
                    IconButton(
                      tooltip: 'Delete ${category.name}',
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _delete(context, ref, category),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => MessageView(
          icon: Icons.cloud_off,
          title: 'Could not load categories.',
          detail: friendlyError(error),
          buttonLabel: 'Try again',
          onPressed: () => ref.invalidate(categoryProvider),
        ),
      ),
    );
  }
}

// A small dialog with one text field. It is a StatefulWidget so it can
// create and dispose its own TextEditingController.
class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.title, this.initialName = ''});

  final String title;
  final String initialName;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Name is required' : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
