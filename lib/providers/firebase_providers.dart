import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/services/firebase_service.dart';

/// Recipe Provider - Manages recipe data and favorites
class RecipeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

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

  RecipeProvider({FirebaseService? service})
      : _firebaseService = service ?? FirebaseService() {
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
  Future<void> toggleFavorite(String recipeId) async {
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
  final FirebaseService _firebaseService;

  AppUser? _appUser;
  bool _isLoading = false;
  String? _error;
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  bool _isUploadingPhoto = false;

  // Getters
  AppUser? get currentUser => _appUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _appUser != null || _firebaseService.currentUser != null;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get selectedLanguage => _selectedLanguage;
  bool get isUploadingPhoto => _isUploadingPhoto;

  UserProvider({FirebaseService? service})
      : _firebaseService = service ?? FirebaseService() {
    _initUser();
  }

  /// Initialize user (load existing user if authenticated)
  Future<void> _initUser() async {
    try {
      // Load app preferences
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';

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
        _appUser = _appUser!.copyWith(
          dietaryPreferences: dietaryPreferences,
          allergies: allergies,
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
          .map((e) => (e['query'] as String?) ?? '')
          .where((q) => q.trim().isNotEmpty)
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
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  /// Toggle notifications preference
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    notifyListeners();
  }

  /// Set language preference
  Future<void> setLanguage(String language) async {
    _selectedLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', language);
    notifyListeners();
  }

  /// Increment recipes cooked counter (call when user starts cooking)
  Future<void> incrementRecipesCooked() async {
    try {
      _appUser = await _firebaseService.incrementRecipesCooked();
      notifyListeners();
    } catch (e) {
      // Non-critical — ignore
    }
  }

  /// Upload a profile photo and update the user's photoUrl
  Future<void> uploadPhoto(XFile file) async {
    _isUploadingPhoto = true;
    _error = null;
    notifyListeners();
    try {
      final url = await _firebaseService.uploadProfilePhoto(file);
      _appUser = _appUser?.copyWith(photoUrl: url);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  /// Remove the profile photo from Storage and clear the URL
  Future<void> removePhoto() async {
    _isUploadingPhoto = true;
    _error = null;
    notifyListeners();
    try {
      await _firebaseService.removeProfilePhoto();
      _appUser = await _firebaseService.getUserProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }
}

/// Grocery List Provider - Manages grocery lists with auto-sync
class GroceryListProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  List<GroceryList> _lists = [];
  GroceryList? _currentList;
  List<GroceryItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String? _cloudListId; // ID of the active Firestore list for this session

  // Getters
  List<GroceryList> get lists => _lists;
  GroceryList? get currentList => _currentList;
  List<GroceryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSynced => _cloudListId != null;

  GroceryListProvider({FirebaseService? service})
      : _firebaseService = service ?? FirebaseService() {
    _init();
  }

  /// Load local items then try to merge with cloud
  Future<void> _init() async {
    await _loadLocalItems();
    await _syncFromCloud();
  }

  /// Load items from SharedPreferences
  Future<void> _loadLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    _cloudListId = prefs.getString('active_grocery_list_id');
    final itemsJson = prefs.getStringList('grocery_items') ?? [];

    _items = itemsJson.map((itemStr) {
      final parts = itemStr.split('|');
      return GroceryItem(
        name: parts.isNotEmpty ? parts[0] : '',
        quantity: parts.length > 1 ? double.tryParse(parts[1]) ?? 1.0 : 1.0,
        unit: parts.length > 2 ? parts[2] : '',
        category: parts.length > 3 ? parts[3] : 'other',
        checked: parts.length > 4 ? parts[4] == 'true' : false,
        recipes: [],
      );
    }).whereType<GroceryItem>().where((i) => i.name.isNotEmpty).toList();

    notifyListeners();
  }

  /// Save items to SharedPreferences
  Future<void> _saveLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = _items
        .map((e) => '${e.name}|${e.quantity}|${e.unit}|${e.category}|${e.checked}')
        .toList();
    await prefs.setStringList('grocery_items', itemsJson);
    if (_cloudListId != null) {
      await prefs.setString('active_grocery_list_id', _cloudListId!);
    }
  }

  /// Pull from Firestore and merge with local items (cloud checked state wins)
  Future<void> _syncFromCloud() async {
    if (_firebaseService.currentUser == null) return;
    try {
      GroceryList? cloudList;

      if (_cloudListId != null) {
        cloudList = await _firebaseService.getGroceryList(_cloudListId!);
      }

      // If no known list, fetch the most recent one
      if (cloudList == null) {
        final lists = await _firebaseService.getGroceryLists();
        if (lists.isNotEmpty) {
          cloudList = lists.first;
          _cloudListId = cloudList.id;
        }
      }

      if (cloudList != null) {
        _mergeWithCloud(cloudList.items);
        _currentList = cloudList;
        await _saveLocalItems();
        notifyListeners();
      }
    } catch (_) {
      // Stay with local items on network error
    }
  }

  /// Merge cloud items with local: union of names, cloud wins for checked state
  void _mergeWithCloud(List<GroceryItem> cloudItems) {
    final merged = <String, GroceryItem>{};

    // Start with local items
    for (final item in _items) {
      merged[item.name.toLowerCase()] = item;
    }

    // Overlay cloud items: cloud wins for checked state
    for (final cloudItem in cloudItems) {
      final key = cloudItem.name.toLowerCase();
      if (merged.containsKey(key)) {
        // Keep local item but use cloud's checked state
        merged[key] = merged[key]!.copyWith(checked: cloudItem.checked);
      } else {
        merged[key] = cloudItem;
      }
    }

    _items = merged.values.toList();
  }

  /// Push current items to Firestore (create or update)
  Future<void> _pushToCloud() async {
    if (_firebaseService.currentUser == null) return;
    try {
      if (_cloudListId == null) {
        // Create a new cloud list
        _cloudListId = await _firebaseService.createGroceryList(
          name: 'My Grocery List',
          items: _items,
        );
        final prefs = await SharedPreferences.getInstance();
        if (_cloudListId != null) {
          await prefs.setString('active_grocery_list_id', _cloudListId!);
        }
      } else {
        // Update existing cloud list
        await _firebaseService.updateGroceryList(_cloudListId!, items: _items);
      }
    } catch (_) {
      // Non-critical — local changes already saved
    }
  }

  /// Add item
  void addItem(GroceryItem item) {
    // Avoid duplicate names
    if (_items.any((i) => i.name.toLowerCase() == item.name.toLowerCase())) {
      return;
    }
    _items.add(item);
    _saveLocalItems();
    _pushToCloud();
    notifyListeners();
  }

  /// Remove item
  void removeItem(String name) {
    _items.removeWhere((item) => item.name == name);
    _saveLocalItems();
    _pushToCloud();
    notifyListeners();
  }

  /// Toggle item checked state (immutable pattern)
  void toggleItem(String name) {
    final index = _items.indexWhere((item) => item.name == name);
    if (index != -1) {
      _items[index] = _items[index].copyWith(checked: !_items[index].checked);
      _saveLocalItems();
      _pushToCloud();
      notifyListeners();
    }
  }

  /// Clear checked items
  void clearCheckedItems() {
    _items.removeWhere((item) => item.checked);
    _saveLocalItems();
    _pushToCloud();
    notifyListeners();
  }

  /// Force a full sync from cloud (call after login)
  Future<void> syncOnLogin() async {
    await _syncFromCloud();
  }

  /// Create grocery list (kept for explicit saves, e.g. from recipe detail)
  Future<String?> createGroceryList(
    String userId,
    List<String> recipeIds, {
    Map<String, double>? servingsMultipliers,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_cloudListId != null) {
        await _firebaseService.updateGroceryList(_cloudListId!, items: _items);
        _isLoading = false;
        notifyListeners();
        return _cloudListId;
      }
      final listId = await _firebaseService.createGroceryList(
        name: 'My Grocery List',
        items: _items,
      );
      _cloudListId = listId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_grocery_list_id', listId);
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
      if (_cloudListId == listId) {
        _cloudListId = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_grocery_list_id');
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
