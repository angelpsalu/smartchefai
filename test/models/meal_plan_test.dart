import 'package:flutter_test/flutter_test.dart';
import 'package:smartchefai/models/models.dart';

void main() {
  group('MealPlan', () {
    test('empty() creates 7 null slots', () {
      final plan = MealPlan.empty('uid-1');
      expect(plan.days.length, 7);
      expect(plan.days.values.every((v) => v == null), true);
      expect(plan.userId, 'uid-1');
    });

    test('fromFirestore parses assigned days', () {
      final plan = MealPlan.fromFirestore({
        'user_id': 'uid-1',
        'days': {'monday': 'r1', 'wednesday': 'r2'},
        'week_start': null,
        'updated_at': null,
      });
      expect(plan.days['monday'], 'r1');
      expect(plan.days['wednesday'], 'r2');
      expect(plan.days['tuesday'], null);
    });

    test('copyWith changes specific fields', () {
      final plan = MealPlan.empty('uid-1');
      final updated = plan.copyWith(userId: 'uid-2');
      expect(updated.userId, 'uid-2');
      expect(updated.days, plan.days);
    });

    test('dayNames has exactly 7 entries', () {
      expect(MealPlan.dayNames.length, 7);
      expect(MealPlan.dayNames.first, 'monday');
      expect(MealPlan.dayNames.last, 'sunday');
    });
  });
}
