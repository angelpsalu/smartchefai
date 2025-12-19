import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/services/api_service.dart';

class RecipeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Recipe> _recipes = [];
  List<Recipe> _favorites = [];
  Set<String> _favoriteIds = {};
  Recipe? _currentRecipe;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Recipe> get recipes => _recipes;
  List<Recipe> get favorites => _favorites;
  List<Recipe> get favoriteRecipes => _favorites;
  Recipe? get currentRecipe => _currentRecipe;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RecipeProvider() {
    _loadFavoriteIds();
  }

  Future<void> _loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorite_ids') ?? [];
    _favoriteIds = ids.toSet();
    notifyListeners();
  }

  Future<void> _saveFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_ids', _favoriteIds.toList());
  }

  // Load recipes (initial load)
  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipes = await _apiService.getAllRecipes();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search recipes
  Future<List<Recipe>> searchRecipes(
    String query, {
    Map<String, dynamic>? filters,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipes = await _apiService.searchRecipes(query, filters: filters);
      _isLoading = false;
      notifyListeners();
      return _recipes;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Toggle favorite
  void toggleFavorite(String recipeId) {
    if (_favoriteIds.contains(recipeId)) {
      _favoriteIds.remove(recipeId);
      _favorites.removeWhere((r) => r.id == recipeId);
    } else {
      _favoriteIds.add(recipeId);
      
      // Try to find recipe in loaded recipes first
      Recipe? recipe;
      try {
        recipe = _recipes.firstWhere((r) => r.id == recipeId);
      } catch (e) {
        // If not in recipes list, use current recipe if available
        recipe = _currentRecipe;
      }
      
      // Only add if we have a valid recipe and it's not already in favorites
      if (recipe != null && !_favorites.any((r) => r.id == recipeId)) {
        _favorites.add(recipe);
      }
    }
    _saveFavoriteIds();
    notifyListeners();
  }

  bool isFavorite(String recipeId) {
    return _favoriteIds.contains(recipeId);
  }

  // Search by ingredients
  Future<List<Recipe>> searchByIngredients(List<String> ingredients) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipes = await _apiService.searchByIngredients(ingredients);
      _isLoading = false;
      notifyListeners();
      return _recipes;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get recipe by ID
  Future<Recipe?> getRecipe(String recipeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentRecipe = await _apiService.getRecipe(recipeId);
      _isLoading = false;
      notifyListeners();
      return _currentRecipe;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get all recipes
  Future<List<Recipe>> getAllRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipes = await _apiService.getAllRecipes();
      _isLoading = false;
      notifyListeners();
      return _recipes;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get favorites
  Future<void> getFavorites(String userId) async {
    try {
      _favorites = await _apiService.getFavorites(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add favorite
  Future<bool> addFavorite(String userId, String recipeId) async {
    try {
      await _apiService.addFavorite(userId, recipeId);
      if (_currentRecipe != null) {
        _favorites.add(_currentRecipe!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove favorite
  Future<bool> removeFavorite(String userId, String recipeId) async {
    try {
      await _apiService.removeFavorite(userId, recipeId);
      _favorites.removeWhere((r) => r.id == recipeId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Create user
  Future<bool> createUser(String name, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await _apiService.createUser({
        'name': name,
        'email': email,
      });
      await getUser(userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get user
  Future<void> getUser(String userId) async {
    try {
      _currentUser = await _apiService.getUser(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Set preferences
  Future<bool> setPreferences(
    List<String> dietaryPreferences,
    List<String> allergies,
  ) async {
    if (_currentUser == null) return false;

    try {
      await _apiService.setPreferences(
        _currentUser!.id,
        dietaryPreferences,
        allergies,
      );
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        dietaryPreferences: dietaryPreferences,
        allergies: allergies,
        favoriteRecipes: _currentUser!.favoriteRecipes,
        searchHistory: _currentUser!.searchHistory,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Dark mode support
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  void toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }
}

class GroceryListProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<GroceryList> _lists = [];
  GroceryList? _currentList;
  List<GroceryItem> _items = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<GroceryList> get lists => _lists;
  GroceryList? get currentList => _currentList;
  List<GroceryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GroceryListProvider() {
    _loadLocalItems();
  }

  Future<void> _loadLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList('grocery_items') ?? [];
    
    // Parse saved items: format is "name|quantity|unit|category|checked"
    _items = itemsJson.map((itemStr) {
      final parts = itemStr.split('|');
      if (parts.length >= 2) {
        return GroceryItem(
          name: parts[0],
          quantity: parts.length > 1 ? double.tryParse(parts[1]) ?? 1.0 : 1.0,
          unit: parts.length > 2 ? parts[2] : '',
          category: parts.length > 3 ? parts[3] : 'other',
          checked: parts.length > 4 ? parts[4] == 'true' : false,
          recipes: [],
        );
      }
      // Fallback for old format "name|checked"
      return GroceryItem(
        name: parts[0],
        quantity: 1.0,
        unit: '',
        category: 'other',
        checked: parts.length > 1 ? parts[1] == 'true' : false,
        recipes: [],
      );
    }).toList();
    
    notifyListeners();
  }

  Future<void> _saveLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = _items.map((e) => 
      '${e.name}|${e.quantity}|${e.unit}|${e.category}|${e.checked}'
    ).toList();
    await prefs.setStringList('grocery_items', itemsJson);
  }

  // Add item locally
  void addItem(GroceryItem item) {
    _items.add(item);
    _saveLocalItems();
    notifyListeners();
  }

  // Remove item
  void removeItem(String id) {
    _items.removeWhere((item) => item.name == id);
    _saveLocalItems();
    notifyListeners();
  }

  // Toggle item checked state
  void toggleItem(String id) {
    final index = _items.indexWhere((item) => item.name == id);
    if (index != -1) {
      _items[index].checked = !_items[index].checked;
      _saveLocalItems();
      notifyListeners();
    }
  }

  // Clear checked items
  void clearCheckedItems() {
    _items.removeWhere((item) => item.checked);
    _saveLocalItems();
    notifyListeners();
  }

  // Create grocery list
  Future<String?> createGroceryList(
    String userId,
    List<String> recipeIds, {
    Map<String, double>? servingsMultipliers,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final listId = await _apiService.createGroceryList(
        userId,
        recipeIds,
        servingsMultipliers: servingsMultipliers,
      );
      await getGroceryList(listId);
      _isLoading = false;
      notifyListeners();
      return listId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get grocery list
  Future<void> getGroceryList(String listId) async {
    try {
      _currentList = await _apiService.getGroceryList(listId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get user grocery lists
  Future<void> getUserGroceryLists(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lists = await _apiService.getUserGroceryLists(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle item (API - for cloud lists)
  Future<bool> toggleListItem(String listId, String itemName) async {
    try {
      await _apiService.toggleGroceryItem(listId, itemName);
      await getGroceryList(listId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete list
  Future<bool> deleteList(String listId) async {
    try {
      await _apiService.deleteGroceryList(listId);
      _lists.removeWhere((l) => l.id == listId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
