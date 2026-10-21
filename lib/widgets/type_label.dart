import 'package:flutter/material.dart';

const _typeColors = <String, Color>{
  'normal': Color(0xFF9FA19F),
  'fire': Color(0xFFE62829),
  'water': Color(0xFF2980EF),
  'grass': Color(0xFF3FA129),
  'electric': Color(0xFFFAC000),
  'ice': Color(0xFF3DCEF3),
  'fighting': Color(0xFFFF8000),
  'poison': Color(0xFF9141CB),
  'ground': Color(0xFF915121),
  'flying': Color(0xFF81B9EF),
  'psychic': Color(0xFFEF4179),
  'bug': Color(0xFF91A119),
  'rock': Color(0xFFAFA981),
  'ghost': Color(0xFF704170),
  'dragon': Color(0xFF5060E1),
  'dark': Color(0xFF624D4E),
  'steel': Color(0xFF60A1B8),
  'fairy': Color(0xFFEF70EF),
};

Color typeColor(String type) => _typeColors[type] ?? Colors.grey;

/// A small colored pill that shows one Pokémon type.
class TypeLabel extends StatelessWidget {
  const TypeLabel({required this.type, super.key});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: typeColor(type),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
