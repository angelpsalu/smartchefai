import 'package:flutter/material.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/services/firebase_service.dart';

/// Manages the weekly meal plan and a local cache of assigned recipes.
class MealPlanProvider extends ChangeNotifier {
  final FirebaseService _service;

  MealPlan? _mealPlan;
  // keyed by recipeId — lets the UI render names/thumbnails without extra lookups
  final Map<String, Recipe> _assignedRecipes = {};
  bool _isLoading = false;
  bool _hasLoaded = false; // true once a successful Firestore load has completed
  String? _error;

  MealPlan? get mealPlan => _mealPlan;
  Map<String, Recipe> get assignedRecipes => _assignedRecipes;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  MealPlanProvider({FirebaseService? service})
      : _service = service ?? FirebaseService() {
    loadMealPlan();
  }

  /// Fetch meal plan from Firestore. Initialises an empty plan if none exists.
  /// Safe to call multiple times — skips if already loaded and not forced.
  Future<void> loadMealPlan({bool force = false}) async {
    if (_service.currentUser == null) return;
    // Skip redundant loads unless explicitly forced (e.g., pull-to-refresh)
    if (_hasLoaded && !force) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _mealPlan = await _service.getMealPlan() ??
          MealPlan.empty(_service.currentUser!.uid);
      _hasLoaded = true;
      // Rebuild _assignedRecipes cache from known recipe IDs
      for (final entry in _mealPlan!.days.entries) {
        final id = entry.value;
        if (id != null && !_assignedRecipes.containsKey(id)) {
          final recipe = await _service.getRecipe(id);
          if (recipe != null) _assignedRecipes[id] = recipe;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Assign [recipe] to [day] (e.g. 'monday') and persist.
  Future<void> assignRecipe(String day, Recipe recipe) async {
    // If not loaded yet, try to load first; fall back to creating an empty plan
    if (_mealPlan == null) {
      await loadMealPlan(force: true);
    }
    if (_mealPlan == null) {
      final user = _service.currentUser;
      if (user == null) return;
      _mealPlan = MealPlan.empty(user.uid);
      _hasLoaded = true;
    }
    _assignedRecipes[recipe.id] = recipe;
    _mealPlan = _mealPlan!.copyWith(
      days: {..._mealPlan!.days, day: recipe.id},
    );
    notifyListeners();
    try {
      await _service.saveMealPlan(_mealPlan!);
    } catch (e) {
      _error = 'Failed to save meal plan: $e';
      debugPrint('assignRecipe save error: $e');
      notifyListeners();
    }
  }

  /// Remove the recipe from [day] and persist.
  Future<void> removeRecipe(String day) async {
    if (_mealPlan == null) return;
    _mealPlan = _mealPlan!.copyWith(
      days: {..._mealPlan!.days, day: null},
    );
    notifyListeners();
    try {
      await _service.saveMealPlan(_mealPlan!);
    } catch (e) {
      _error = 'Failed to save meal plan: $e';
      debugPrint('removeRecipe save error: $e');
      notifyListeners();
    }
  }

  /// Returns grocery items for all assigned recipes (one item per ingredient).
  List<GroceryItem> generateGroceryItems() {
    final items = <GroceryItem>[];
    final seen = <String>{};
    for (final recipeId in _mealPlan?.days.values.whereType<String>() ?? []) {
      final recipe = _assignedRecipes[recipeId];
      if (recipe == null) continue;
      for (final ingredient in recipe.ingredients) {
        final key = ingredient.toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);
        items.add(GroceryItem(
          name: ingredient,
          quantity: 1.0,
          unit: '',
          category: 'meal-plan',
          checked: false,
          recipes: [recipe.name],
        ));
      }
    }
    return items;
  }
}
