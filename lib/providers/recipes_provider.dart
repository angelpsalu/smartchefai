import 'package:flutter/foundation.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/services/api_service.dart';

/// Recipe Provider with improved state management
class RecipeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Recipe> _recipes = [];
  final List<Recipe> _favorites = [];
  Recipe? _currentRecipe;
  bool _isLoading = false;
  String? _error;
  final List<String> _searchHistory = [];

  // Getters
  List<Recipe> get recipes => _recipes;
  List<Recipe> get favorites => _favorites;
  Recipe? get currentRecipe => _currentRecipe;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get searchHistory => _searchHistory;

  /// Search recipes by query
  Future<void> searchRecipes(String query) async {
    if (query.isEmpty) return;
    
    _setLoading(true);
    _setError(null);
    _addToSearchHistory(query);

    try {
      _recipes = await _apiService.searchRecipes(query);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search recipes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Search recipes by ingredients
  Future<void> searchByIngredients(List<String> ingredients) async {
    _setLoading(true);
    _setError(null);

    try {
      _recipes = await _apiService.searchByIngredients(ingredients);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search by ingredients: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get all recipes
  Future<void> getAllRecipes() async {
    _setLoading(true);
    _setError(null);

    try {
      _recipes = await _apiService.getAllRecipes();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recipes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get single recipe by ID
  Future<void> getRecipe(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      _currentRecipe = await _apiService.getRecipe(id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recipe: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add recipe to favorites
  Future<void> addFavorite(String userId, String recipeId) async {
    try {
      final recipe = _recipes.firstWhere((r) => r.id == recipeId);
      if (!_favorites.any((r) => r.id == recipeId)) {
        _favorites.add(recipe);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to add favorite: $e');
    }
  }

  /// Remove recipe from favorites
  Future<void> removeFavorite(String recipeId) async {
    try {
      _favorites.removeWhere((r) => r.id == recipeId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove favorite: $e');
    }
  }

  /// Check if recipe is favorite
  bool isFavorite(String recipeId) {
    return _favorites.any((r) => r.id == recipeId);
  }

  /// Clear search history
  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  // Private helpers
  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String? error) {
    _error = error;
  }

  void _addToSearchHistory(String query) {
    if (!_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    }
  }
}
