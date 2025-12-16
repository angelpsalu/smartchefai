import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:smartchefai/models/models.dart';

/// API Service using FREE APIs (TheMealDB + Spoonacular)
/// No backend server required!
class ApiService {
  // TheMealDB API (FREE - unlimited for development)
  static const String _mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1';
  
  // Spoonacular API (FREE - 150 requests/day)
  // Get your free API key at: https://spoonacular.com/food-api/console
  static const String _spoonacularBaseUrl = 'https://api.spoonacular.com';
  static const String _spoonacularApiKey = ''; // Add your free API key here
  
  late Dio _dio;
  
  // Local cache for recipes
  List<Recipe> _cachedRecipes = [];
  bool _recipesLoaded = false;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );
  }

  // ==================== RECIPE ENDPOINTS ====================

  /// Get all recipes (from local JSON + TheMealDB)
  Future<List<Recipe>> getAllRecipes({int limit = 100}) async {
    if (_recipesLoaded && _cachedRecipes.isNotEmpty) {
      return _cachedRecipes.take(limit).toList();
    }

    try {
      // Load local recipes first
      final localRecipes = await _loadLocalRecipes();
      
      // Fetch some from TheMealDB
      final mealDbRecipes = await _fetchMealDbRecipes();
      
      _cachedRecipes = [...localRecipes, ...mealDbRecipes];
      _recipesLoaded = true;
      
      return _cachedRecipes.take(limit).toList();
    } catch (e) {
      // Fallback to local only
      _cachedRecipes = await _loadLocalRecipes();
      _recipesLoaded = true;
      return _cachedRecipes.take(limit).toList();
    }
  }

  /// Load recipes from local JSON file
  Future<List<Recipe>> _loadLocalRecipes() async {
    try {
      final jsonString = await rootBundle.loadString('data/recipes.json');
      final jsonData = json.decode(jsonString);
      final recipes = (jsonData['recipes'] as List?) ?? jsonData;
      return (recipes as List).map((r) => Recipe.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch recipes from TheMealDB API
  Future<List<Recipe>> _fetchMealDbRecipes() async {
    final recipes = <Recipe>[];
    
    // Fetch from multiple categories
    final categories = ['Chicken', 'Beef', 'Vegetarian', 'Seafood', 'Pasta'];
    
    for (final category in categories) {
      try {
        final response = await _dio.get(
          '$_mealDbBaseUrl/filter.php',
          queryParameters: {'c': category},
        );
        
        final meals = response.data['meals'] as List?;
        if (meals != null) {
          for (final meal in meals.take(5)) {
            final recipe = _mealDbToRecipe(meal, category);
            recipes.add(recipe);
          }
        }
      } catch (e) {
        // Continue with next category
      }
    }
    
    return recipes;
  }

  /// Convert TheMealDB response to Recipe model
  Recipe _mealDbToRecipe(Map<String, dynamic> meal, String category) {
    return Recipe(
      id: meal['idMeal'] ?? '',
      name: meal['strMeal'] ?? '',
      ingredients: [],
      steps: [],
      prepTime: '15 mins',
      cookTime: '30 mins',
      difficulty: 'medium',
      cuisine: category,
      dietaryTags: category == 'Vegetarian' ? ['vegetarian'] : [],
      nutrition: Nutrition(
        calories: 350,
        protein: '25g',
        carbs: '30g',
        fat: '15g',
        fiber: '5g',
      ),
      servings: 4,
      imageUrl: meal['strMealThumb'] ?? '',
    );
  }

  /// Get single recipe by ID
  Future<Recipe> getRecipe(String recipeId) async {
    // Check local cache first
    if (_cachedRecipes.isNotEmpty) {
      final cached = _cachedRecipes.where((r) => r.id == recipeId).firstOrNull;
      if (cached != null) return cached;
    }
    
    // Try TheMealDB lookup
    try {
      final response = await _dio.get(
        '$_mealDbBaseUrl/lookup.php',
        queryParameters: {'i': recipeId},
      );
      
      final meals = response.data['meals'] as List?;
      if (meals != null && meals.isNotEmpty) {
        return _mealDbDetailToRecipe(meals.first);
      }
    } catch (e) {
      // Continue to fallback
    }
    
    throw Exception('Recipe not found');
  }

  /// Convert detailed TheMealDB response to Recipe
  Recipe _mealDbDetailToRecipe(Map<String, dynamic> meal) {
    // Extract ingredients
    final ingredients = <String>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add('${measure ?? ''} $ingredient'.trim());
      }
    }
    
    // Extract steps
    final instructions = meal['strInstructions'] ?? '';
    final steps = instructions.toString().split(RegExp(r'\r?\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    
    return Recipe(
      id: meal['idMeal'] ?? '',
      name: meal['strMeal'] ?? '',
      ingredients: ingredients,
      steps: steps,
      prepTime: '15 mins',
      cookTime: '30 mins',
      difficulty: 'medium',
      cuisine: meal['strArea'] ?? 'International',
      dietaryTags: _extractDietaryTags(meal),
      nutrition: Nutrition(
        calories: 350,
        protein: '25g',
        carbs: '30g',
        fat: '15g',
        fiber: '5g',
      ),
      servings: 4,
      imageUrl: meal['strMealThumb'] ?? '',
    );
  }

  List<String> _extractDietaryTags(Map<String, dynamic> meal) {
    final tags = <String>[];
    final category = meal['strCategory']?.toString().toLowerCase() ?? '';
    
    if (category.contains('vegetarian')) tags.add('vegetarian');
    if (category.contains('vegan')) tags.add('vegan');
    if (category.contains('seafood')) tags.add('seafood');
    
    return tags;
  }

  /// Search recipes by query (name, cuisine, etc.)
  Future<List<Recipe>> searchRecipes(
    String query, {
    int limit = 15,
    Map<String, dynamic>? filters,
  }) async {
    final results = <Recipe>[];
    
    // Search TheMealDB by name
    try {
      final response = await _dio.get(
        '$_mealDbBaseUrl/search.php',
        queryParameters: {'s': query},
      );
      
      final meals = response.data['meals'] as List?;
      if (meals != null) {
        for (final meal in meals) {
          results.add(_mealDbDetailToRecipe(meal));
        }
      }
    } catch (e) {
      // Continue with local search
    }
    
    // Also search local cache
    final queryLower = query.toLowerCase();
    final localMatches = _cachedRecipes.where((r) =>
        r.name.toLowerCase().contains(queryLower) ||
        r.cuisine.toLowerCase().contains(queryLower) ||
        r.ingredients.any((i) => i.toLowerCase().contains(queryLower))
    ).toList();
    
    // Combine and deduplicate
    for (final recipe in localMatches) {
      if (!results.any((r) => r.id == recipe.id)) {
        results.add(recipe);
      }
    }
    
    return results.take(limit).toList();
  }

  /// Search recipes by ingredients
  Future<List<Recipe>> searchByIngredients(
    List<String> ingredients, {
    int limit = 15,
  }) async {
    final results = <Recipe>[];
    
    // Search TheMealDB by main ingredient
    if (ingredients.isNotEmpty) {
      try {
        final response = await _dio.get(
          '$_mealDbBaseUrl/filter.php',
          queryParameters: {'i': ingredients.first},
        );
        
        final meals = response.data['meals'] as List?;
        if (meals != null) {
          for (final meal in meals.take(limit)) {
            // Get full details
            try {
              final detailResponse = await _dio.get(
                '$_mealDbBaseUrl/lookup.php',
                queryParameters: {'i': meal['idMeal']},
              );
              final detailMeals = detailResponse.data['meals'] as List?;
              if (detailMeals != null && detailMeals.isNotEmpty) {
                results.add(_mealDbDetailToRecipe(detailMeals.first));
              }
            } catch (e) {
              results.add(_mealDbToRecipe(meal, 'Mixed'));
            }
          }
        }
      } catch (e) {
        // Continue with local search
      }
    }
    
    // Also search local recipes
    if (results.length < limit) {
      final ingredientLower = ingredients.map((i) => i.toLowerCase()).toList();
      final localMatches = _cachedRecipes.where((r) =>
          r.ingredients.any((i) => 
              ingredientLower.any((ing) => i.toLowerCase().contains(ing))
          )
      ).toList();
      
      for (final recipe in localMatches) {
        if (!results.any((r) => r.id == recipe.id) && results.length < limit) {
          results.add(recipe);
        }
      }
    }
    
    return results;
  }

  // ==================== USER ENDPOINTS (Local Storage) ====================
  
  /// Create user (returns generated ID)
  Future<String> createUser(Map<String, dynamic> userData) async {
    // Generate unique ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    // In a real app, save to SharedPreferences or Hive
    return id;
  }

  /// Get user by ID
  Future<User> getUser(String userId) async {
    // In a real app, load from SharedPreferences or Hive
    return User(
      id: userId,
      name: 'Guest User',
      email: 'guest@example.com',
      dietaryPreferences: [],
      allergies: [],
      favoriteRecipes: [],
      searchHistory: [],
    );
  }

  /// Set user preferences
  Future<void> setPreferences(
    String userId,
    List<String> dietaryPreferences,
    List<String> allergies,
  ) async {
    // In a real app, save to SharedPreferences or Hive
  }

  /// Get user's favorite recipes
  Future<List<Recipe>> getFavorites(String userId) async {
    // In a real app, load from local storage
    return [];
  }

  /// Add to favorites
  Future<void> addFavorite(String userId, String recipeId) async {
    // In a real app, save to local storage
  }

  /// Remove from favorites
  Future<void> removeFavorite(String userId, String recipeId) async {
    // In a real app, remove from local storage
  }

  /// Get personalized recommendations
  Future<List<Recipe>> getPersonalizedRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    // Simple recommendation: return random recipes from cache
    if (_cachedRecipes.isEmpty) {
      await getAllRecipes();
    }
    
    final shuffled = List<Recipe>.from(_cachedRecipes)..shuffle();
    return shuffled.take(limit).toList();
  }

  // ==================== GROCERY LIST ENDPOINTS (Local) ====================

  Future<String> createGroceryList(
    String userId,
    List<String> recipeIds, {
    Map<String, double>? servingsMultipliers,
  }) async {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<GroceryList> getGroceryList(String listId) async {
    return GroceryList(
      id: listId,
      userId: '',
      name: 'My Grocery List',
      items: [],
      byCategory: {},
      totalItems: 0,
      recipes: [],
      createdAt: DateTime.now(),
      status: 'active',
    );
  }

  Future<List<GroceryList>> getUserGroceryLists(String userId) async {
    // In a real app, load from Hive/SharedPreferences
    return [];
  }

  Future<void> updateGroceryList(String listId, Map<String, dynamic> updates) async {
    // In a real app, update in local storage
  }

  Future<void> deleteGroceryList(String listId) async {
    // In a real app, delete from local storage
  }

  Future<void> toggleGroceryItem(String listId, String itemName) async {
    // In a real app, update item in local storage
  }

  // ==================== INGREDIENT DETECTION ====================
  
  /// Detect ingredients from image
  /// Note: For MVP, we return mock data. In production, use:
  /// - Google ML Kit (FREE, on-device)
  /// - Google Cloud Vision (1000/month free)
  /// - Clarifai Food Model (1000/month free)
  Future<List<DetectedIngredient>> detectIngredients(List<int> imageBytes) async {
    // Mock response for MVP demo
    // TODO: Integrate Google ML Kit for on-device detection
    return [
      DetectedIngredient(
        name: 'tomato',
        confidence: 0.95,
        bbox: BoundingBox(x1: 0.1, y1: 0.1, x2: 0.3, y2: 0.3),
      ),
      DetectedIngredient(
        name: 'onion',
        confidence: 0.88,
        bbox: BoundingBox(x1: 0.4, y1: 0.2, x2: 0.6, y2: 0.4),
      ),
      DetectedIngredient(
        name: 'garlic',
        confidence: 0.82,
        bbox: BoundingBox(x1: 0.7, y1: 0.3, x2: 0.9, y2: 0.5),
      ),
    ];
  }

  /// Detect ingredients and find matching recipes
  Future<List<Recipe>> detectIngredientsAndFindRecipes(List<int> imageBytes) async {
    final ingredients = await detectIngredients(imageBytes);
    final ingredientNames = ingredients.map((i) => i.name).toList();
    return searchByIngredients(ingredientNames);
  }

  // ==================== HEALTH CHECK ====================
  
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('$_mealDbBaseUrl/random.php');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
