import 'package:flutter/material.dart';
import 'package:flavorgen/core/theme.dart';
import 'package:flavorgen/models/ingredient.dart';

class IngredientChip extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onRemove;

  const IngredientChip({
    super.key,
    required this.ingredient,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        ingredient.name, // Pas de majuscule
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      backgroundColor: const Color(0xFFF7F8F9), // Fond très clair
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      deleteIcon: const Icon(
        Icons.close,
        size: 18,
        color: AppTheme.textSecondary,
      ),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    );
  }
}
