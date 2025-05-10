import 'package:flutter/material.dart';
import 'package:flavorgen/core/theme.dart';
import 'package:flavorgen/models/ingredient.dart';
import 'ingredient_section.dart';

class SearchView extends StatelessWidget {
  final TextEditingController searchController;
  final List<Ingredient> searchResults;
  final List<Ingredient> selectedIngredients;
  final bool isLoading;
  final void Function(String) onSearchChanged;
  final void Function(Ingredient) onAddIngredient;
  final void Function(int) onRemoveIngredient;
  final VoidCallback onGenerateRecipes;

  const SearchView({
    super.key,
    required this.searchController,
    required this.searchResults,
    required this.selectedIngredients,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
    required this.onGenerateRecipes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search ingredients...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: AppTheme.textSecondary),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: const TextStyle(fontSize: 16),
                          onChanged: onSearchChanged,
                        ),
                      ),
                      if (searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Résultats de recherche
                isLoading
                    ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                    : searchResults.isEmpty
                    ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No ingredients found.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                    : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          searchResults
                              .map(
                                (ingredient) => ActionChip(
                                  label: Text(ingredient.name),
                                  onPressed: () => onAddIngredient(ingredient),
                                ),
                              )
                              .toList(),
                    ),
                const SizedBox(height: 24),
                // Your Ingredients Section
                IngredientSection(
                  selectedIngredients: selectedIngredients,
                  onRemove: onRemoveIngredient,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Generate Recipe Button (toujours visible en bas)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  selectedIngredients.isEmpty || isLoading
                      ? null
                      : onGenerateRecipes,
              icon:
                  isLoading
                      ? Container(
                        width: 20,
                        height: 20,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                isLoading ? 'Generating...' : 'Generate Recipe',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedIngredients.isEmpty
                        ? AppTheme.primaryColor.withOpacity(0.5)
                        : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
