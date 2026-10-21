import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/pokedex_notifier.dart';

class NicknameDialog extends ConsumerStatefulWidget {
  const NicknameDialog({required this.pokemon, super.key});

  final Pokemon pokemon;

  @override
  ConsumerState<NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends ConsumerState<NicknameDialog> {
  late final TextEditingController _controller;
  late final String? _currentNickname;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _currentNickname = ref.read(pokedexProvider).nicknameFor(widget.pokemon.id);
    _controller = TextEditingController(text: _currentNickname ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final nickname = _controller.text.trim();
    if (nickname.isEmpty) {
      // _errorText only matters to this dialog, so it uses setState.
      setState(() => _errorText = 'Enter a nickname first.');
      return;
    }
    ref.read(pokedexProvider.notifier).setNickname(widget.pokemon.id, nickname);
    Navigator.pop(context);
  }

  void _remove() {
    ref.read(pokedexProvider.notifier).removeNickname(widget.pokemon.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nickname for ${widget.pokemon.name}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        decoration: InputDecoration(
          labelText: 'Nickname',
          hintText: 'e.g. Sparky',
          errorText: _errorText,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        if (_currentNickname != null)
          TextButton(onPressed: _remove, child: const Text('Remove')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
