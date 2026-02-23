import '../models/models.dart';

/// Classifies recipes into meal types using keyword matching on recipe name.
class MealClassifier {
  MealClassifier._();

  static const _breakfastKeywords = [
    'pancake', 'egg', 'toast', 'smoothie', 'oatmeal', 'cereal', 'waffle',
    'benedict', 'burrito', 'breakfast', 'brunch', 'muffin', 'granola',
    'porridge', 'french toast', 'crepe', 'bagel', 'frittata',
  ];

  static const _lunchKeywords = [
    'salad', 'sandwich', 'soup', 'wrap', 'bowl', 'pita', 'quesadilla',
    'bruschetta', 'crostini', 'spring roll', 'sushi',
  ];

  static const _snackKeywords = [
    'dessert', 'cake', 'cookie', 'brownie', 'ice cream', 'pudding',
    'smoothie', 'fruit', 'muffin', 'scone', 'tart', 'pie', 'mousse',
    'tiramisu', 'cheesecake', 'crème brûlée', 'panna cotta', 'churro',
    'baklava', 'mochi',
  ];

  /// Returns recipes sorted: suggested for this slot first, then the rest.
  static List<Recipe> sortedForSlot(List<Recipe> recipes, String slot) {
    if (slot == 'dinner') return recipes;
    final keywords = switch (slot) {
      'breakfast' => _breakfastKeywords,
      'lunch' => _lunchKeywords,
      'snack' => _snackKeywords,
      _ => <String>[],
    };
    final suggested = <Recipe>[];
    final rest = <Recipe>[];
    for (final recipe in recipes) {
      final name = recipe.name.toLowerCase();
      final isQuick = recipe.prepTime + recipe.cookTime <= 30;
      if (_matchesAny(name, keywords) || (slot == 'lunch' && isQuick)) {
        suggested.add(recipe);
      } else {
        rest.add(recipe);
      }
    }
    return [...suggested, ...rest];
  }

  /// Returns the count of suggested recipes for a slot (for UI badge).
  static int suggestedCount(List<Recipe> recipes, String slot) {
    if (slot == 'dinner') return recipes.length;
    final keywords = switch (slot) {
      'breakfast' => _breakfastKeywords,
      'lunch' => _lunchKeywords,
      'snack' => _snackKeywords,
      _ => <String>[],
    };
    return recipes.where((r) {
      final name = r.name.toLowerCase();
      return _matchesAny(name, keywords) ||
          (slot == 'lunch' && r.prepTime + r.cookTime <= 30);
    }).length;
  }

  static bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}
