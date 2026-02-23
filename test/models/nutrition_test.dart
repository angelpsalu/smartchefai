import 'package:flutter_test/flutter_test.dart';
import 'package:smartchefai/models/models.dart';
import '../helpers/test_data.dart';

void main() {
  group('Nutrition', () {
    test('fromJson parses int calories', () {
      final n = Nutrition.fromJson({
        'calories': 350,
        'protein': '25g',
        'carbs': '40g',
        'fat': '10g',
        'fiber': '5g',
      });
      expect(n.calories, 350);
      expect(n.protein, '25g');
    });

    test('fromJson parses string calories', () {
      final n = Nutrition.fromJson({'calories': '200', 'protein': '10g', 'carbs': '30g', 'fat': '5g', 'fiber': '2g'});
      expect(n.calories, 200);
    });

    test('fromJson uses 0 for missing calories', () {
      final n = Nutrition.fromJson({});
      expect(n.calories, 0);
      expect(n.protein, '0g');
    });

    test('copyWith overrides specific fields', () {
      final original = TestData.nutrition;
      final copy = original.copyWith(calories: 500);
      expect(copy.calories, 500);
      expect(copy.protein, original.protein);
      expect(copy.fat, original.fat);
    });

    test('toJson round-trips through fromJson', () {
      final n = TestData.nutrition;
      final json = n.toJson();
      final restored = Nutrition.fromJson(json);
      expect(restored.calories, n.calories);
      expect(restored.protein, n.protein);
      expect(restored.carbs, n.carbs);
    });
  });
}
