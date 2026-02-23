import 'package:flutter_test/flutter_test.dart';
import 'package:smartchefai/models/models.dart';
import '../helpers/test_data.dart';

void main() {
  group('NutritionGoals', () {
    test('defaults() returns sensible values', () {
      final g = NutritionGoals.defaults('uid-1');
      expect(g.userId, 'uid-1');
      expect(g.dailyCalories, 2000);
      expect(g.dailyProtein, 50);
      expect(g.dailyCarbs, 250);
      expect(g.dailyFat, 70);
    });

    test('fromFirestore parses all fields', () {
      final g = NutritionGoals.fromFirestore({
        'user_id': 'uid-1',
        'daily_calories': 1800,
        'daily_protein': 60,
        'daily_carbs': 220,
        'daily_fat': 65,
      });
      expect(g.dailyCalories, 1800);
      expect(g.dailyProtein, 60);
      expect(g.dailyCarbs, 220);
      expect(g.dailyFat, 65);
    });

    test('fromFirestore falls back to defaults for missing fields', () {
      final g = NutritionGoals.fromFirestore({'user_id': 'uid-1'});
      final defaults = NutritionGoals.defaults('uid-1');
      expect(g.dailyCalories, defaults.dailyCalories);
      expect(g.dailyProtein, defaults.dailyProtein);
    });

    test('copyWith updates only specified fields', () {
      final g = TestData.nutritionGoals;
      final updated = g.copyWith(dailyCalories: 1500);
      expect(updated.dailyCalories, 1500);
      expect(updated.dailyProtein, g.dailyProtein);
      expect(updated.userId, g.userId);
    });
  });
}
