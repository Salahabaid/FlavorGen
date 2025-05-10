import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flavorgen/core/theme.dart';
import 'package:flavorgen/models/recipe.dart';
import 'package:share_plus/share_plus.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  void _shareRecipe(BuildContext context) {
    final String appName = "FlavorGen";
    final String title = recipe.title;
    // Génère le lien profond ou web vers la recette
    final String link = "https://flavorgen.com/recipes/${recipe.id}";
    final String message =
        "Check out this $title recipe on $appName 👨‍🍳\n\n$link";
    Share.share(message, subject: "$title - $appName");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SUPPRIME l'appBar ici
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false, // Pas de bouton retour auto
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Image.network(recipe.image, fit: BoxFit.cover),
                  ),
                  // Bouton retour personnalisé
                  Positioned(
                    top: 32,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.85),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF3E5481),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Bouton partage personnalisé
                  Positioned(
                    top: 32,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.85),
                      child: IconButton(
                        icon: const Icon(Icons.share, color: Color(0xFF3E5481)),
                        onPressed: () => _shareRecipe(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Cards
                  _buildInfoRow(),

                  const SizedBox(height: 24),

                  // Nutrition Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '22/03/2025',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Ingredients
                  const SectionTitle('Ingrédients'),
                  const SizedBox(height: 12),

                  if (recipe.extendedIngredients != null)
                    ...recipe.extendedIngredients!.map(
                      (ingredient) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                ingredient.original,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Instructions
                  const SectionTitle('Instructions'),
                  const SizedBox(height: 16),

                  if (recipe.instructions != null)
                    ..._parseInstructions(
                      recipe.instructions!,
                    ).asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoTile('Prep', '30 mins'),
        _buildInfoTile('Cook', '15 mins'),
        _buildInfoTile('Portions', '4'),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Column(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  List<String> _parseInstructions(String html) {
    // Simple HTML stripping for demonstration
    return html
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '')
        .split('\n')
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }
}

// Add this helper widget inside main.dart or in a separate file

class RecipeLoaderScreen extends StatelessWidget {
  final String recipeId;
  const RecipeLoaderScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Recipe>(
      future: fetchRecipeById(
        recipeId,
      ), // Implement this function to fetch your recipe
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Recipe not found')));
        } else if (snapshot.hasData) {
          return RecipeDetailScreen(recipe: snapshot.data!);
        } else {
          return Scaffold(body: Center(child: Text('Unknown error')));
        }
      },
    );
  }
}
