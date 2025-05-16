import 'package:flutter/material.dart';
import 'package:flavorgen/core/theme.dart';
import 'package:flavorgen/models/ingredient.dart';
import 'ingredient_section.dart';

class ManualEntryView extends StatelessWidget {
  final TextEditingController searchController;
  final List<Ingredient> searchResults;
  final List<Ingredient> selectedIngredients;
  final bool isLoading;
  final void Function(String) onSearchChanged;
  final void Function(Ingredient) onAddIngredient;
  final void Function(int) onRemoveIngredient;
  final VoidCallback onGenerateRecipes;

  const ManualEntryView({
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
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Le contenu principal scrollable
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    // Search Bar
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: AppTheme.backgroundSecondary,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search ingredients...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                style: theme.textTheme.bodyMedium,
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
                    ),
                    const SizedBox(height: 20),
                    // Résultats de recherche
                    if (searchController.text.isNotEmpty)
                      isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            )
                          : searchResults.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'No ingredients found.',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: searchResults
                                      .map(
                                        (ingredient) => ActionChip(
                                          label: Text(ingredient.name, style: theme.textTheme.bodyMedium),
                                          onPressed: () => onAddIngredient(ingredient),
                                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                          avatar: const Icon(Icons.add, size: 18, color: AppTheme.primaryColor),
                                        ),
                                      )
                                      .toList(),
                                ),
                    if (searchController.text.isNotEmpty)
                      const SizedBox(height: 20),
                    // Popular Ingredients
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Popular Ingredients',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildPopularIngredientChip('Tomato', Icons.local_florist, theme),
                                _buildPopularIngredientChip('Chicken', Icons.egg, theme),
                                _buildPopularIngredientChip('Onion', Icons.spa, theme),
                                _buildPopularIngredientChip('Garlic', Icons.grain, theme),
                                _buildPopularIngredientChip('Pasta', Icons.ramen_dining, theme),
                                _buildPopularIngredientChip('Rice', Icons.rice_bowl, theme),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Your Ingredients Section
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Ingredients',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: selectedIngredients.isEmpty
                                  ? Text(
                                      'No ingredients added yet.',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: selectedIngredients
                                          .map((ingredient) => Chip(
                                                key: ValueKey(ingredient.id),
                                                label: Text(ingredient.name, style: theme.textTheme.bodyMedium),
                                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                                deleteIcon: const Icon(Icons.close, size: 18),
                                                onDeleted: () => onRemoveIngredient(ingredient.id),
                                              ))
                                          .toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Le bouton principal reste toujours visible
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: selectedIngredients.isEmpty || isLoading ? null : onGenerateRecipes,
                  icon: isLoading
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  label: Text(
                    isLoading ? 'Generating...' : 'Generate Recipe',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedIngredients.isEmpty
                        ? AppTheme.primaryColor.withOpacity(0.5)
                        : AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularIngredientChip(String name, IconData icon, ThemeData theme) {
    return GestureDetector(
      onTap: () => onAddIngredient(Ingredient(id: name.hashCode, name: name)),
      child: Chip(
        avatar: Icon(icon, size: 18, color: AppTheme.primaryColor),
        label: Text(
          name,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppTheme.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}
