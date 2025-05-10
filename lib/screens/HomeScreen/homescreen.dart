import 'package:flutter/material.dart';
import 'package:flavorgen/core/theme.dart';
import 'package:flavorgen/models/ingredient.dart';
import 'package:flavorgen/models/recipe.dart' as model;
import 'package:flavorgen/services/recipe_service.dart';
import 'ingredient_section.dart';
import 'manual_entry_view.dart';
import 'scan_view.dart';
import 'search_view.dart';
import 'package:flavorgen/screens/HomeScreen/recipe_view.dart';
import 'package:flavorgen/screens/Recipe/recipe_detail_screen.dart';
import 'package:flavorgen/screens/Camera/camerascreen.dart';
import 'package:flavorgen/services/favorite_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flavorgen/screens/ProfileScreen/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _currentView = 'scan';
  final TextEditingController _searchController = TextEditingController();
  final RecipeService _recipeService = RecipeService();
  final FavoriteService _favoriteService = FavoriteService();
  final List<Ingredient> _selectedIngredients = [];
  List<Ingredient> _searchResults = [];
  List<model.Recipe> _generatedRecipes = [];
  bool _isLoading = false;

  // Filtres
  String? _selectedDifficulty;
  int? _maxTotalTime;
  int? _maxCalories;
  String? _selectedDiet;

  // Nouvel état pour la recherche dans les favoris
  String _favoritesSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtres appliqués à la liste de recettes générées
  List<model.Recipe> get _filteredRecipes {
    return _generatedRecipes.where((recipe) {
      if (_selectedDifficulty != null &&
          (recipe.difficulty?.toLowerCase() ?? '') !=
              _selectedDifficulty!.toLowerCase()) {
        return false;
      }
      if (_maxTotalTime != null && (recipe.readyInMinutes) > _maxTotalTime!) {
        return false;
      }
      if (_maxCalories != null && (recipe.calories ?? 0) > _maxCalories!) {
        return false;
      }
      if (_selectedDiet != null &&
          !(recipe.diets
                  ?.map((e) => e.toLowerCase())
                  .contains(_selectedDiet!.toLowerCase()) ??
              false)) {
        return false;
      }
      return true;
    }).toList();
  }

  // Recherche d'ingrédients
  Future<void> _searchIngredients(String query) async {
    setState(() => _isLoading = true);
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }
    final results = await _recipeService.searchIngredients(query);
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  // Ajouter un ingrédient
  void _addIngredient(Ingredient ingredient) {
    if (!_selectedIngredients.any((item) => item.id == ingredient.id)) {
      setState(() {
        _selectedIngredients.add(ingredient);
        _searchController.clear();
        _searchResults = [];
      });
    }
  }

  // Supprimer un ingrédient
  void _removeIngredient(int id) {
    setState(() {
      _selectedIngredients.removeWhere((item) => item.id == id);
    });
  }

  // Générer des recettes
  Future<void> _generateRecipes() async {
    if (_selectedIngredients.isEmpty) return;
    setState(() => _isLoading = true);
    final recipes = await _recipeService.getRecipesByIngredients(
      _selectedIngredients,
    );

    for (var recipe in recipes) {
      // Pour vérifier si favori
      recipe.isFavorite = await _favoriteService.isFavorite(
        recipe.id.toString(),
      );
    }

    setState(() {
      _generatedRecipes = recipes;
      _isLoading = false;
      _currentView = 'recipe';
      _currentIndex = 1;
    });
  }

  // Démarrer la caméra (dummy ici, à intégrer avec ta logique de scan)
  Future<void> _startCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(), // Passe les callbacks si besoin
      ),
    );
    if (result != null && result is List<Ingredient>) {
      setState(() {
        _selectedIngredients.addAll(
          result.where((i) => !_selectedIngredients.any((e) => e.id == i.id)),
        );
      });
    }
  }

  // Ouvre le détail recette
  void _viewRecipeDetails(model.Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  // Dialogues de filtres
  void _showDifficultyFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? selected = _selectedDifficulty;
        return StatefulBuilder(
          builder:
              (context, setStateDialog) => SimpleDialog(
                title: const Text('Select Difficulty'),
                children: [
                  for (var diff in ['Easy', 'Medium', 'Hard'])
                    RadioListTile<String>(
                      value: diff,
                      groupValue: selected,
                      title: Text(diff),
                      onChanged: (v) {
                        setStateDialog(() => selected = v);
                      },
                    ),
                  SimpleDialogOption(
                    child: const Text('Clear'),
                    onPressed: () {
                      setState(() {
                        _selectedDifficulty = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDifficulty = selected;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Apply"),
                  ),
                ],
              ),
        );
      },
    );
  }

  void _showTimeFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int? selected = _maxTotalTime;
        return StatefulBuilder(
          builder:
              (context, setStateDialog) => SimpleDialog(
                title: const Text('Max Total Time (min)'),
                children: [
                  for (var t in [15, 30, 45, 60])
                    RadioListTile<int>(
                      value: t,
                      groupValue: selected,
                      title: Text('≤ $t min'),
                      onChanged: (v) => setStateDialog(() => selected = v),
                    ),
                  SimpleDialogOption(
                    child: const Text('Clear'),
                    onPressed: () {
                      setState(() => _maxTotalTime = null);
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _maxTotalTime = selected);
                      Navigator.pop(context);
                    },
                    child: const Text("Apply"),
                  ),
                ],
              ),
        );
      },
    );
  }

  void _showCaloriesFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int? selected = _maxCalories;
        return StatefulBuilder(
          builder:
              (context, setStateDialog) => SimpleDialog(
                title: const Text('Max Calories'),
                children: [
                  for (var t in [200, 400, 600, 800, 1000])
                    RadioListTile<int>(
                      value: t,
                      groupValue: selected,
                      title: Text('≤ $t kcal'),
                      onChanged: (v) => setStateDialog(() => selected = v),
                    ),
                  SimpleDialogOption(
                    child: const Text('Clear'),
                    onPressed: () {
                      setState(() => _maxCalories = null);
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _maxCalories = selected);
                      Navigator.pop(context);
                    },
                    child: const Text("Apply"),
                  ),
                ],
              ),
        );
      },
    );
  }

  void _showDietFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? selected = _selectedDiet;
        final diets = ['Vegetarian', 'Vegan', 'Gluten Free', 'Keto', 'Paleo'];
        return StatefulBuilder(
          builder:
              (context, setStateDialog) => SimpleDialog(
                title: const Text('Diet'),
                children: [
                  for (var d in diets)
                    RadioListTile<String>(
                      value: d,
                      groupValue: selected,
                      title: Text(d),
                      onChanged: (v) => setStateDialog(() => selected = v),
                    ),
                  SimpleDialogOption(
                    child: const Text('Clear'),
                    onPressed: () {
                      setState(() => _selectedDiet = null);
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedDiet = selected);
                      Navigator.pop(context);
                    },
                    child: const Text("Apply"),
                  ),
                ],
              ),
        );
      },
    );
  }

  void _toggleFavorite(model.Recipe recipe) async {
    setState(() {
      recipe.isFavorite = !recipe.isFavorite;
    });
    if (recipe.isFavorite) {
      // Pour ajouter aux favoris
      await _favoriteService.addFavorite(recipe);
      setState(() {
        _currentIndex = 2; // Index de l'onglet Favoris
        // Si tu as une variable pour la vue courante, adapte-la ici
        // _currentView = 'favorites';
      });
    } else {
      // Pour retirer des favoris
      await _favoriteService.removeFavorite(recipe.id.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    print('Utilisateur connecté : ${user?.uid}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent;
    if (_currentIndex == 2) {
      // Affiche la liste des favoris
      mainContent = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD0DBEA)),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _favoritesSearchQuery = value;
                        });
                      },
                      style: const TextStyle(color: Color(0xFF3E5481)),
                      decoration: const InputDecoration(
                        hintText: 'Search by title',
                        hintStyle: TextStyle(color: Color(0xFF9FA5C0)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF1FCC79),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<model.Recipe>>(
              stream: _favoriteService.getFavorites(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final favorites =
                    snapshot.data!
                        .where(
                          (recipe) => recipe.title.toLowerCase().contains(
                            _favoritesSearchQuery.toLowerCase(),
                          ),
                        )
                        .toList();
                if (favorites.isEmpty) {
                  return const Center(
                    child: Text('Aucun favori pour le moment.'),
                  );
                }
                return ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final recipe = favorites[index];
                    return ListTile(
                      leading: Image.network(
                        recipe.image,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                      title: Text(recipe.title),
                      subtitle: Text('${recipe.readyInMinutes} min'),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () async {
                          await _favoriteService.removeFavorite(
                            recipe.id.toString(),
                          );
                          // Pas de setState ici !
                        },
                      ),
                      onTap: () => _viewRecipeDetails(recipe),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    } else if (_currentIndex == 3) {
      // Onglet Profile : affiche SettingsScreen
      mainContent = const SettingsScreen();
    } else {
      switch (_currentView) {
        case 'scan':
          mainContent = ScanView(
            isLoading: _isLoading,
            selectedIngredients: _selectedIngredients,
            onScanPressed: _startCamera,
            onGenerateRecipes: _generateRecipes,
            onRemoveIngredient: _removeIngredient,
          );
          break;
        case 'manual':
          mainContent = ManualEntryView(
            searchController: _searchController,
            searchResults: _searchResults,
            selectedIngredients: _selectedIngredients,
            isLoading: _isLoading,
            onSearchChanged: (value) {
              _searchIngredients(value);
              setState(() {
                _currentView = value.isEmpty ? 'manual' : 'search';
              });
            },
            onAddIngredient: _addIngredient,
            onRemoveIngredient: _removeIngredient,
            onGenerateRecipes: _generateRecipes,
          );
          break;
        case 'search':
          mainContent = SearchView(
            searchController: _searchController,
            searchResults: _searchResults,
            selectedIngredients: _selectedIngredients,
            isLoading: _isLoading,
            onSearchChanged: (value) {
              _searchIngredients(value);
              setState(() {
                _currentView = value.isEmpty ? 'manual' : 'search';
              });
            },
            onAddIngredient: _addIngredient,
            onRemoveIngredient: _removeIngredient,
            onGenerateRecipes: _generateRecipes,
          );
          break;
        case 'recipe':
          mainContent = RecipeView(
            recipes: _filteredRecipes,
            isLoading: _isLoading,
            selectedIngredients: _selectedIngredients,
            onRemoveIngredient: _removeIngredient,
            onEditIngredients: () {
              setState(() {
                _currentView = 'scan';
                _currentIndex = 0;
              });
            },
            onRecipeTap: _viewRecipeDetails,
            onShowDifficultyFilter: _showDifficultyFilterDialog,
            onShowTimeFilter: _showTimeFilterDialog,
            onShowCaloriesFilter: _showCaloriesFilterDialog,
            onShowDietFilter: _showDietFilterDialog,
            onToggleFavorite: _toggleFavorite,
          );
          break;
        default:
          mainContent = ScanView(
            isLoading: _isLoading,
            selectedIngredients: _selectedIngredients,
            onScanPressed: _startCamera,
            onGenerateRecipes: _generateRecipes,
            onRemoveIngredient: _removeIngredient,
          );
      }
    }

    return Scaffold(
      backgroundColor:
          _currentIndex == 3
              ? const Color(0xFFFCFCFE) // Profile
              : Colors.white, // Home, Recipes, Favorites
      body: SafeArea(
        child: Column(
          children: [
            // Header affiché pour TOUS les onglets
            Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
                left: 16.0,
                right: 16.0,
                bottom: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications,
                      color: Color(0xFF200E32),
                      size: 28,
                    ),
                    onPressed: () {
                      // Action notification
                    },
                  ),
                ],
              ),
            ),
            // Switch Scan/Manual Entry UNIQUEMENT sur Home
            if (_currentIndex == 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentView = 'scan';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  _currentView == 'scan'
                                      ? const Color(0xFFE9FFF3)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  color:
                                      _currentView == 'scan'
                                          ? Color(0xFF1FCC79)
                                          : Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Scan Ingredients',
                                  style: TextStyle(
                                    color:
                                        _currentView == 'scan'
                                            ? Color(0xFF1FCC79)
                                            : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentView = 'manual';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  _currentView == 'manual'
                                      ? const Color(0xFFE9FFF3)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  color:
                                      _currentView == 'manual'
                                          ? Color(0xFF1FCC79)
                                          : Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Manual Entry',
                                  style: TextStyle(
                                    color:
                                        _currentView == 'manual'
                                            ? Color(0xFF1FCC79)
                                            : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Le contenu principal de chaque onglet
            Expanded(child: mainContent),
            // Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                    if (index == 0) {
                      _currentView = 'scan';
                    } else if (index == 1 && _generatedRecipes.isNotEmpty) {
                      _currentView = 'recipe';
                    }
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: AppTheme.primaryColor,
                unselectedItemColor: AppTheme.textSecondary,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_filled),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.ramen_dining_rounded),
                    label: 'Recipes',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.star_rounded),
                    label: 'Favorites',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
