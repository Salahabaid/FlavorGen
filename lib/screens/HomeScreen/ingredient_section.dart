import 'package:flutter/material.dart';
import 'package:flavorgen/core/theme.dart';
import 'package:flavorgen/models/ingredient.dart';
import 'package:flavorgen/widgets/ingredient_chip.dart';

class IngredientSection extends StatelessWidget {
  final List<Ingredient> selectedIngredients;
  final void Function(int id) onRemove;

  const IngredientSection({
    super.key,
    required this.selectedIngredients,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Ingredients',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          selectedIngredients.isEmpty
              ? const Text(
                'No ingredients added yet.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              )
              : Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    selectedIngredients
                        .map(
                          (ingredient) => IngredientChip(
                            ingredient: ingredient,
                            onRemove: () => onRemove(ingredient.id),
                          ),
                        )
                        .toList(),
              ),
        ],
      ),
    );
  }
}
