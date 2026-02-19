import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/services/firebase_service.dart';

/// Recipe Provider - Manages recipe data and favorites
class RecipeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

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

  /// Load favorite IDs from local storage and Firebase
  Future<void> _loadFavoriteIds() async {
    // Load from local storage first (for offline support)
    final prefs = await SharedPreferences.getInstance();
    final localIds = prefs.getStringList('favorite_ids') ?? [];
    _favoriteIds = localIds.toSet();
    
    // Try to sync with Firebase
    try {
      final firebaseIds = await _firebaseService.getFavoriteIds();
      if (firebaseIds.isNotEmpty) {
        _favoriteIds.addAll(firebaseIds);
        await _saveFavoriteIds();
      }
    } catch (e) {
      // Use local favorites if Firebase fails
    }
    
    notifyListeners();
  }

  /// Save favorite IDs to local storage
  Future<void> _saveFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_ids', _favoriteIds.toList());
  }

  /// Load all recipes
  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipes = await _firebaseService.getAllRecipes();
      
      // Load favorites from recipes
      _favorites = _recipes.where((r) => _favoriteIds.contains(r.id)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search recipes by query
  Future<List<Recipe>> searchRecipes(
    String query, {
    Map<String, dynamic>? filters,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipes = await _firebaseService.searchRecipes(query);
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

  /// Toggle favorite status
  void toggleFavorite(String recipeId) async {
    if (_favoriteIds.contains(recipeId)) {
      _favoriteIds.remove(recipeId);
      _favorites.removeWhere((r) => r.id == recipeId);
      
      // Remove from Firebase
      try {
        await _firebaseService.removeFavorite(recipeId);
      } catch (e) {
        // Continue with local
      }
    } else {
      _favoriteIds.add(recipeId);
      
      // Find recipe and add to favorites
      Recipe? recipe;
      try {
        recipe = _recipes.firstWhere((r) => r.id == recipeId);
      } catch (e) {
        recipe = _currentRecipe;
      }
      
      if (recipe != null && !_favorites.any((r) => r.id == recipeId)) {
        _favorites.add(recipe);
      }
      
      // Add to Firebase
      try {
        await _firebaseService.addFavorite(recipeId);
      } catch (e) {
        // Continue with local
      }
    }
    
    _saveFavoriteIds();
    notifyListeners();
  }

  /// Check if recipe is favorite
  bool isFavorite(String recipeId) {
    return _favoriteIds.contains(recipeId);
  }

  /// Search recipes by ingredients
  Future<List<Recipe>> searchByIngredients(List<String> ingredients) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipes = await _firebaseService.searchByIngredients(ingredients);
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

  /// Get recipe by ID
  Future<Recipe?> getRecipe(String recipeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentRecipe = await _firebaseService.getRecipe(recipeId);
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

  /// Get all recipes
  Future<List<Recipe>> getAllRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipes = await _firebaseService.getAllRecipes();
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

  /// Get favorites (refresh from loaded recipes)
  Future<void> getFavorites(String userId) async {
    _favorites = _recipes.where((r) => _favoriteIds.contains(r.id)).toList();
    notifyListeners();
  }

  /// Add favorite
  Future<bool> addFavorite(String userId, String recipeId) async {
    toggleFavorite(recipeId);
    return true;
  }

  /// Remove favorite
  Future<bool> removeFavorite(String userId, String recipeId) async {
    toggleFavorite(recipeId);
    return true;
  }

  /// Set current recipe
  void setCurrentRecipe(Recipe recipe) {
    _currentRecipe = recipe;
    notifyListeners();
  }
}

/// User Provider - Manages user profile and settings
class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  AppUser? _appUser;
  bool _isLoading = false;
  String? _error;
  bool _isDarkMode = false;

  // Getters - currentUser returns legacy User model for compatibility
  User? get currentUser => _appUser != null
      ? User(
          id: _appUser!.id,
          name: _appUser!.name,
          email: _appUser!.email,
          dietaryPreferences: _appUser!.dietaryPreferences,
          allergies: _appUser!.allergies,
          favoriteRecipes: _appUser!.favoriteRecipes,
          searchHistory: _appUser!.searchHistory,
        )
      : null;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _appUser != null || _firebaseService.currentUser != null;
  bool get isDarkMode => _isDarkMode;

  UserProvider() {
    _initUser();
  }

  /// Initialize user (load existing user if authenticated)
  Future<void> _initUser() async {
    try {
      // Only load user profile if already signed in
      if (_firebaseService.currentUser != null) {
        _appUser = await _firebaseService.getUserProfile();
        
        // Create profile if doesn't exist (for existing Firebase auth users)
        if (_appUser == null) {
          final user = _firebaseService.currentUser!;
          await _firebaseService.createUserProfile(
            name: user.displayName ?? 'User',
            email: user.email ?? '',
          );
          _appUser = await _firebaseService.getUserProfile();
        }
      }
      // If no user signed in, leave _appUser as null
    } catch (e) {
      // Continue without user data
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Create user profile
  Future<bool> createUser(String name, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.createUserProfile(
        name: name,
        email: email,
      );
      _appUser = await _firebaseService.getUserProfile();
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

  /// Get user profile
  Future<void> getUser(String userId) async {
    try {
      _appUser = await _firebaseService.getUserProfile();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set user preferences
  Future<bool> setPreferences(
    List<String> dietaryPreferences,
    List<String> allergies,
  ) async {
    try {
      await _firebaseService.updatePreferences(
        dietaryPreferences: dietaryPreferences,
        allergies: allergies,
      );
      
      // Update local user
      if (_appUser != null) {
        _appUser = AppUser(
          id: _appUser!.id,
          name: _appUser!.name,
          email: _appUser!.email,
          dietaryPreferences: dietaryPreferences,
          allergies: allergies,
          favoriteRecipes: _appUser!.favoriteRecipes,
          searchHistory: _appUser!.searchHistory,
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      // Continue
    }
    _appUser = null;
    notifyListeners();
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _firebaseService.signInWithEmail(email, password);
      if (userCredential.user != null) {
        _appUser = await _firebaseService.getUserProfile();
        
        // Create profile if it doesn't exist (shouldn't happen but handle gracefully)
        if (_appUser == null) {
          await _firebaseService.createUserProfile(
            name: userCredential.user!.displayName ?? 'User',
            email: userCredential.user!.email ?? email,
          );
          _appUser = await _firebaseService.getUserProfile();
        }
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _firebaseService.registerWithEmail(
        email,
        password,
        name,
      );
      if (userCredential.user != null) {
        // registerWithEmail already creates the profile, just load it
        _appUser = await _firebaseService.getUserProfile();
        
        // Ensure profile was created (shouldn't be null but handle gracefully)
        if (_appUser == null) {
          await _firebaseService.createUserProfile(
            name: name,
            email: email,
          );
          _appUser = await _firebaseService.getUserProfile();
        }
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _firebaseService.signInWithGoogle();
      if (userCredential.user != null) {
        _appUser = await _firebaseService.getUserProfile();
        
        // Create profile if it doesn't exist (shouldn't happen as signInWithGoogle creates it)
        if (_appUser == null) {
          await _firebaseService.createUserProfile(
            name: userCredential.user!.displayName ?? 'User',
            email: userCredential.user!.email ?? '',
          );
          _appUser = await _firebaseService.getUserProfile();
        }
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.sendPasswordResetEmail(email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Recent searches
  List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  /// Load recent searches from Firebase
  Future<void> loadRecentSearches() async {
    try {
      final history = await _firebaseService.getSearchHistory();
      // Sort by timestamp descending, take latest 10, extract query strings
      final sorted = [...history]
        ..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
      _recentSearches = sorted
          .take(10)
          .map((e) => e['query'] as String)
          .toList();
      notifyListeners();
    } catch (_) {
      // Keep existing list on error
    }
  }

  /// Save a search query to Firebase and update local list
  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    // Update local list immediately
    _recentSearches.removeWhere((s) => s.toLowerCase() == query.toLowerCase());
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) _recentSearches = _recentSearches.take(10).toList();
    notifyListeners();
    // Persist to Firebase
    try {
      await _firebaseService.addSearchHistory(query);
    } catch (_) {
      // Continue — local update already applied
    }
  }

  /// Load theme preference
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  /// Toggle dark mode
  void toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }
}

/// Grocery List Provider - Manages grocery lists
class GroceryListProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

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

  /// Load items from local storage
  Future<void> _loadLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList('grocery_items') ?? [];

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

  /// Save items to local storage
  Future<void> _saveLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = _items
        .map((e) => '${e.name}|${e.quantity}|${e.unit}|${e.category}|${e.checked}')
        .toList();
    await prefs.setStringList('grocery_items', itemsJson);
  }

  /// Add item
  void addItem(GroceryItem item) {
    _items.add(item);
    _saveLocalItems();
    notifyListeners();
  }

  /// Remove item
  void removeItem(String id) {
    _items.removeWhere((item) => item.name == id);
    _saveLocalItems();
    notifyListeners();
  }

  /// Toggle item checked state (immutable pattern)
  void toggleItem(String id) {
    final index = _items.indexWhere((item) => item.name == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(checked: !_items[index].checked);
      _saveLocalItems();
      notifyListeners();
    }
  }

  /// Clear checked items
  void clearCheckedItems() {
    _items.removeWhere((item) => item.checked);
    _saveLocalItems();
    notifyListeners();
  }

  /// Create grocery list (Firebase)
  Future<String?> createGroceryList(
    String userId,
    List<String> recipeIds, {
    Map<String, double>? servingsMultipliers,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final listId = await _firebaseService.createGroceryList(
        name: 'Grocery List ${DateTime.now().toString().substring(0, 10)}',
        items: _items,
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

  /// Get grocery list
  Future<void> getGroceryList(String listId) async {
    try {
      _currentList = await _firebaseService.getGroceryList(listId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get user grocery lists
  Future<void> getUserGroceryLists(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lists = await _firebaseService.getGroceryLists();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle item in cloud list
  Future<bool> toggleListItem(String listId, String itemName) async {
    try {
      await _firebaseService.toggleGroceryItem(listId, itemName);
      await getGroceryList(listId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete list
  Future<bool> deleteList(String listId) async {
    try {
      await _firebaseService.deleteGroceryList(listId);
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
