import 'package:flutter_test/flutter_test.dart';
import 'package:smartchefai/models/models.dart';
import '../helpers/test_data.dart';

void main() {
  group('Recipe', () {
    test('fromJson parses standard fields', () {
      final r = Recipe.fromJson({
        'id': 'r1',
        'name': 'Pasta',
        'ingredients': ['pasta', 'sauce'],
        'steps': ['Boil', 'Mix'],
        'prep_time': 10,
        'cook_time': 20,
        'difficulty': 'Easy',
        'cuisine': 'Italian',
        'dietary_tags': ['vegetarian'],
        'nutrition': {'calories': 350, 'protein': '25g', 'carbs': '40g', 'fat': '10g', 'fiber': '5g'},
        'servings': 2,
        'image_url': 'https://example.com/img.jpg',
        'rating': 4.5,
      });
      expect(r.id, 'r1');
      expect(r.name, 'Pasta');
      expect(r.ingredients, ['pasta', 'sauce']);
      expect(r.prepTime, 10);
      expect(r.cookTime, 20);
      expect(r.nutrition.calories, 350);
    });

    test('fromJson uses prepTime alias', () {
      final r = Recipe.fromJson({
        'id': 'x', 'name': 'X', 'ingredients': [], 'steps': [],
        'prepTime': 15, 'cookTime': 30, 'difficulty': 'Easy',
        'cuisine': '', 'dietary_tags': <String>[],
        'nutrition': <String, dynamic>{}, 'servings': 1, 'image_url': '',
      });
      expect(r.prepTime, 15);
      expect(r.cookTime, 30);
    });

    test('fromJson falls back to TheMealDB idMeal', () {
      final r = Recipe.fromJson({'idMeal': 'meal123', 'strMeal': 'Chicken'});
      expect(r.id, 'meal123');
      expect(r.name, 'Chicken');
    });

    test('fromJson parses string prep_time like "15 mins"', () {
      final r = Recipe.fromJson({
        'id': '', 'name': '', 'ingredients': [], 'steps': [],
        'prep_time': '15 mins', 'cook_time': '30 mins',
        'difficulty': '', 'cuisine': '', 'dietary_tags': <String>[],
        'nutrition': <String, dynamic>{}, 'servings': 1, 'image_url': '',
      });
      expect(r.prepTime, 15);
      expect(r.cookTime, 30);
    });

    test('instructions getter is alias for steps', () {
      expect(TestData.recipe.instructions, TestData.recipe.steps);
    });

    test('copyWith overrides only specified fields', () {
      final copy = TestData.recipe.copyWith(name: 'Updated');
      expect(copy.name, 'Updated');
      expect(copy.id, TestData.recipe.id);
      expect(copy.ingredients, TestData.recipe.ingredients);
    });

    test('toJson contains all required keys', () {
      final json = TestData.recipe.toJson();
      expect(json['id'], 'r1');
      expect(json['name'], 'Test Pasta');
      expect(json['ingredients'], isA<List>());
      expect(json['nutrition'], isA<Map>());
    });

    test('dietaryTags defaults to empty list', () {
      final r = Recipe.fromJson({'idMeal': '1', 'strMeal': 'X'});
      expect(r.dietaryTags, isEmpty);
    });
  });
}
