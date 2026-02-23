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
  String? _error;

  MealPlan? get mealPlan => _mealPlan;
  Map<String, Recipe> get assignedRecipes => _assignedRecipes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MealPlanProvider({FirebaseService? service})
      : _service = service ?? FirebaseService() {
    loadMealPlan();
  }

  /// Fetch meal plan from Firestore. Initialises an empty plan if none exists.
  Future<void> loadMealPlan() async {
    if (_service.currentUser == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _mealPlan = await _service.getMealPlan() ??
          MealPlan.empty(_service.currentUser!.uid);
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
      await loadMealPlan();
    }
    if (_mealPlan == null) {
      final user = _service.currentUser;
      if (user == null) return;
      _mealPlan = MealPlan.empty(user.uid);
    }
    _assignedRecipes[recipe.id] = recipe;
    _mealPlan = _mealPlan!.copyWith(
      days: {..._mealPlan!.days, day: recipe.id},
    );
    notifyListeners();
    await _service.saveMealPlan(_mealPlan!);
  }

  /// Remove the recipe from [day] and persist.
  Future<void> removeRecipe(String day) async {
    if (_mealPlan == null) return;
    _mealPlan = _mealPlan!.copyWith(
      days: {..._mealPlan!.days, day: null},
    );
    notifyListeners();
    await _service.saveMealPlan(_mealPlan!);
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
