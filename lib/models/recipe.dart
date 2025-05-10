import 'dart:convert';
import 'package:http/http.dart' as http;

class Recipe {
  final int id;
  final String title;
  final String image;
  final int readyInMinutes;
  final int servings;
  final String summary;
  final String? instructions;
  final List<ExtendedIngredient>? extendedIngredients;
  final String? difficulty;
  final double? calories;
  final List<String>? diets;

  bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.readyInMinutes,
    required this.servings,
    required this.summary,
    this.instructions,
    this.extendedIngredients,
    this.difficulty,
    this.calories,
    this.diets,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // ...autres parsing...

    // Logique pour calculer la difficulté selon le temps de préparation
    String? difficulty;
    if (json['readyInMinutes'] != null) {
      final int minutes = json['readyInMinutes'];
      if (minutes <= 20) {
        difficulty = 'Easy';
      } else if (minutes <= 40) {
        difficulty = 'Medium';
      } else {
        difficulty = 'Hard';
      }
    }

    // ...autres parsing...

    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 0,
      summary: json['summary'] ?? '',
      instructions: json['instructions'],
      extendedIngredients:
          json['extendedIngredients'] != null
              ? (json['extendedIngredients'] as List)
                  .map((e) => ExtendedIngredient.fromJson(e))
                  .toList()
              : null,
      difficulty: difficulty,
      calories: json['calories']?.toDouble(),
      diets: json['diets'] != null ? List<String>.from(json['diets']) : null,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'summary': summary,
      'instructions': instructions,
      'difficulty': difficulty,
      'calories': calories,
      'diets': diets,
    };
  }
}

class ExtendedIngredient {
  final int id;
  final String original;
  final double? amount;
  final String? unit;

  ExtendedIngredient({
    required this.id,
    required this.original,
    this.amount,
    this.unit,
  });

  factory ExtendedIngredient.fromJson(Map<String, dynamic> json) {
    return ExtendedIngredient(
      id: json['id'] ?? 0,
      original: json['original'] ?? '',
      amount: json['amount']?.toDouble(),
      unit: json['unit'],
    );
  }
}

Future<Recipe> fetchRecipeById(String recipeId) async {
  const apiKey = 'b146d12e5c9248d28b6110075f80a062';
  final url = Uri.parse(
    'https://api.spoonacular.com/recipes/$recipeId/information?apiKey=$apiKey',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return Recipe.fromJson(data);
  } else {
    throw Exception('Recipe not found');
  }
}
