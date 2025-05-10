import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flavorgen/models/ingredient.dart';
import 'package:flavorgen/models/recipe.dart';

class RecipeService {
  static const String apiKey = 'b146d12e5c9248d28b6110075f80a062';
  static const String baseUrl = 'https://api.spoonacular.com';

  // Recherche de recettes par ingrédients
  Future<List<Recipe>> getRecipesByIngredients(
    List<Ingredient> ingredients,
  ) async {
    if (ingredients.isEmpty) return [];

    final ingredientNames = ingredients
        .map((i) => i.name.trim().toLowerCase())
        .join(',');
    final url = Uri.parse(
      '$baseUrl/recipes/findByIngredients?ingredients=$ingredientNames&number=5&ranking=1&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Appels parallèles pour récupérer les détails de chaque recette
        final futures =
            data.take(5).map<Future<Recipe?>>((recipe) {
              return getRecipeDetails(recipe['id']);
            }).toList();

        final results = await Future.wait(futures);
        return results.whereType<Recipe>().toList();
      } else {
        throw Exception(
          'Erreur API (getRecipesByIngredients): ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Erreur lors de la récupération des recettes par ingrédients: $e');
      return [];
    }
  }

  // Obtenir les détails d'une recette
  Future<Recipe?> getRecipeDetails(int recipeId) async {
    final url = Uri.parse(
      '$baseUrl/recipes/$recipeId/information?apiKey=$apiKey',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Recipe.fromJson(data);
      } else {
        throw Exception(
          'Erreur API (getRecipeDetails): ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Erreur lors de la récupération des détails de recette: $e');
      return null;
    }
  }

  // Recherche d'ingrédients via Spoonacular
  Future<List<Ingredient>> searchIngredients(String query) async {
    if (query.trim().length < 2) return [];

    final cleanedQuery = query.trim().toLowerCase();
    final url = Uri.parse(
      '$baseUrl/food/ingredients/autocomplete?query=$cleanedQuery&number=10&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) return [];
        return data.map((item) => Ingredient.fromJson(item)).toList();
      } else {
        throw Exception(
          'Erreur API (searchIngredients): ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Erreur lors de la recherche d\'ingrédients: $e');
      return [];
    }
  }
}
