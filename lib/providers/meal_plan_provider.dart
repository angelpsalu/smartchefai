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
  bool _hasLoaded = false;
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
  Future<void> loadMealPlan({bool force = false}) async {
    if (_service.currentUser == null) return;
    if (_hasLoaded && !force) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _mealPlan = await _service.getMealPlan() ??
          MealPlan.empty(_service.currentUser!.uid);
      _hasLoaded = true;
      // Rebuild _assignedRecipes cache from all slots
      for (final daySlots in _mealPlan!.days.values) {
        for (final recipeId in daySlots.values) {
          if (recipeId != null && !_assignedRecipes.containsKey(recipeId)) {
            final recipe = await _service.getRecipe(recipeId);
            if (recipe != null) _assignedRecipes[recipeId] = recipe;
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Assign [recipe] to [day] + [slot] (e.g. 'monday', 'breakfast') and persist.
  Future<void> assignRecipe(String day, String slot, Recipe recipe) async {
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
    final updatedDays = Map<String, Map<String, String?>>.from(
      _mealPlan!.days.map((k, v) => MapEntry(k, Map<String, String?>.from(v))),
    );
    updatedDays[day] = {...updatedDays[day] ?? {}, slot: recipe.id};
    _mealPlan = _mealPlan!.copyWith(days: updatedDays);
    notifyListeners();
    try {
      await _service.saveMealPlan(_mealPlan!);
    } catch (e) {
      _error = 'Failed to save meal plan: $e';
      debugPrint('assignRecipe save error: $e');
      notifyListeners();
    }
  }

  /// Remove the recipe from [day] + [slot] and persist.
  Future<void> removeRecipe(String day, String slot) async {
    if (_mealPlan == null) return;
    final updatedDays = Map<String, Map<String, String?>>.from(
      _mealPlan!.days.map((k, v) => MapEntry(k, Map<String, String?>.from(v))),
    );
    updatedDays[day] = {...updatedDays[day] ?? {}, slot: null};
    _mealPlan = _mealPlan!.copyWith(days: updatedDays);
    notifyListeners();
    try {
      await _service.saveMealPlan(_mealPlan!);
    } catch (e) {
      _error = 'Failed to save meal plan: $e';
      debugPrint('removeRecipe save error: $e');
      notifyListeners();
    }
  }

  /// Returns grocery items for all assigned recipes across all slots.
  List<GroceryItem> generateGroceryItems() {
    final items = <GroceryItem>[];
    final seen = <String>{};
    for (final daySlots in _mealPlan?.days.values ?? <Map<String, String?>>[]) {
      for (final recipeId in daySlots.values) {
        if (recipeId == null) continue;
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
            category: _categorizeIngredient(ingredient),
            checked: false,
            recipes: [recipe.name],
          ));
        }
      }
    }
    return items;
  }

  /// Simple keyword-based ingredient categorization.
  static String _categorizeIngredient(String ingredient) {
    final lower = ingredient.toLowerCase();
    if (_matchesAny(lower, _produceKeywords)) return 'Produce';
    if (_matchesAny(lower, _dairyKeywords)) return 'Dairy';
    if (_matchesAny(lower, _meatKeywords)) return 'Meat & Seafood';
    if (_matchesAny(lower, _bakeryKeywords)) return 'Bakery';
    if (_matchesAny(lower, _spiceKeywords)) return 'Spices & Herbs';
    return 'Pantry';
  }

  static bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  static const _produceKeywords = [
    'tomato', 'onion', 'garlic', 'pepper', 'lettuce', 'spinach', 'carrot',
    'potato', 'broccoli', 'mushroom', 'avocado', 'cucumber', 'celery',
    'zucchini', 'eggplant', 'corn', 'bean sprout', 'cabbage', 'kale',
    'lemon', 'lime', 'orange', 'apple', 'banana', 'mango', 'berry',
    'blueberr', 'strawberr', 'ginger', 'scallion', 'shallot', 'chili',
    'jalapeno', 'bell pepper', 'peas', 'asparagus', 'beet', 'radish',
  ];
  static const _dairyKeywords = [
    'milk', 'cheese', 'cream', 'butter', 'yogurt', 'sour cream',
    'mozzarella', 'parmesan', 'cheddar', 'feta', 'ricotta', 'whipping',
    'ghee', 'paneer',
  ];
  static const _meatKeywords = [
    'chicken', 'beef', 'pork', 'lamb', 'turkey', 'bacon', 'sausage',
    'fish', 'salmon', 'shrimp', 'prawn', 'tuna', 'cod', 'crab',
    'lobster', 'duck', 'steak', 'mince', 'ground meat', 'ham',
  ];
  static const _bakeryKeywords = [
    'bread', 'tortilla', 'pita', 'naan', 'baguette', 'roll', 'bun',
    'croissant', 'wrap',
  ];
  static const _spiceKeywords = [
    'cumin', 'turmeric', 'paprika', 'cinnamon', 'oregano', 'basil',
    'thyme', 'rosemary', 'bay leaf', 'coriander', 'nutmeg', 'clove',
    'cardamom', 'saffron', 'chili powder', 'cayenne', 'curry powder',
    'garam masala', 'mint', 'parsley', 'dill', 'cilantro', 'sage',
  ];
}
