// test/services/ingredient_matching_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smartchefai/models/models.dart';

// Standalone copy of the algorithm under test.
// Keep this in sync with FirebaseService.searchByIngredients.
List<({Recipe recipe, int matchCount})> filterByIngredients(
  List<Recipe> recipes,
  List<String> ingredients,
) {
  if (ingredients.isEmpty) return [];
  final n = ingredients.length;
  final threshold = (n / 2).ceil();
  final lower = ingredients.map((i) => i.toLowerCase()).toList();

  final results = <({Recipe recipe, int matchCount})>[];
  for (final recipe in recipes) {
    final count = lower
        .where((term) =>
            recipe.ingredients.any((i) => i.toLowerCase().contains(term)))
        .length;
    if (count >= threshold) {
      results.add((recipe: recipe, matchCount: count));
    }
  }
  results.sort((a, b) => b.matchCount.compareTo(a.matchCount));
  return results;
}

Recipe makeRecipe(String id, List<String> ingredients) => Recipe(
      id: id,
      name: 'Test $id',
      ingredients: ingredients,
      steps: const [],
      prepTime: 10,
      cookTime: 10,
      difficulty: 'Easy',
      cuisine: 'Test',
      dietaryTags: const [],
      nutrition: const Nutrition(
        calories: 100,
        protein: '10g',
        carbs: '10g',
        fat: '5g',
        fiber: '2g',
      ),
      servings: 4,
      imageUrl: '',
    );

void main() {
  final chickenRice = makeRecipe('r1', ['500g chicken breast', '2 cups rice', '1 onion']);
  final chickenOnly = makeRecipe('r2', ['600g chicken thighs', '2 garlic cloves']);
  final riceOnly = makeRecipe('r3', ['1 cup rice', '200ml coconut milk']);
  final beef = makeRecipe('r4', ['500g beef mince', '1 onion', '2 tomatoes']);

  group('filterByIngredients', () {
    test('empty ingredient list returns empty', () {
      expect(filterByIngredients([chickenRice], []), isEmpty);
    });

    test('empty recipe list returns empty', () {
      expect(filterByIngredients([], ['chicken']), isEmpty);
    });

    test('tier 1 — all ingredients present — included', () {
      final results = filterByIngredients([chickenRice, beef], ['chicken', 'rice']);
      expect(results.length, 1);
      expect(results.first.recipe.id, 'r1');
      expect(results.first.matchCount, 2);
    });

    test('tier 2 — majority present — included', () {
      final results = filterByIngredients(
        [chickenRice, chickenOnly],
        ['chicken', 'rice', 'garlic'],
      );
      expect(results.length, 2);
    });

    test('below threshold — excluded', () {
      final results = filterByIngredients(
        [chickenOnly],
        ['chicken', 'rice', 'tomato', 'beef'],
      );
      expect(results, isEmpty);
    });

    test('results sorted descending by matchCount', () {
      final results = filterByIngredients(
        [chickenOnly, chickenRice],
        ['chicken', 'rice'],
      );
      expect(results.first.recipe.id, 'r1');
      expect(results.last.recipe.id, 'r2');
    });

    test('case-insensitive matching', () {
      final results = filterByIngredients([chickenRice], ['CHICKEN', 'RICE']);
      expect(results.length, 1);
    });

    test('single ingredient — threshold is 1 — any match included', () {
      final results = filterByIngredients([chickenRice, beef], ['chicken']);
      expect(results.length, 1);
      expect(results.first.recipe.id, 'r1');
    });

    test('matchCount field is accurate', () {
      final results = filterByIngredients([chickenRice], ['chicken', 'rice', 'onion']);
      expect(results.first.matchCount, 3);
    });
  });
}
