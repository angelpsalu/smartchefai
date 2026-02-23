import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/providers/meal_plan_provider.dart';
import '../helpers/mock_firebase_service.mocks.dart';
import '../helpers/test_data.dart';

/// Minimal fake Firebase user — only uid is needed.
class _FakeUser extends Fake implements firebase_auth.User {
  @override
  String get uid => 'uid-1';
}

void main() {
  late MockFirebaseService mockService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
  });

  // ── Unauthenticated (currentUser == null) ────────────────────────────────

  group('MealPlanProvider – unauthenticated', () {
    late MealPlanProvider provider;

    setUp(() async {
      when(mockService.currentUser).thenReturn(null);
      provider = MealPlanProvider(service: mockService);
      await Future<void>.delayed(Duration.zero);
    });

    test('mealPlan is null when no user is signed in', () {
      expect(provider.mealPlan, isNull);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('assignRecipe is a no-op when mealPlan is null', () async {
      await provider.assignRecipe('monday', TestData.recipe);
      expect(provider.mealPlan, isNull);
    });

    test('assignedRecipes is empty initially', () {
      expect(provider.assignedRecipes, isEmpty);
    });
  });

  // ── Authenticated (currentUser != null) ──────────────────────────────────

  group('MealPlanProvider – authenticated', () {
    late MealPlanProvider provider;

    setUp(() async {
      when(mockService.currentUser).thenReturn(_FakeUser());
      // getMealPlan returns null → provider creates MealPlan.empty('uid-1')
      when(mockService.getMealPlan()).thenAnswer((_) async => null);
      provider = MealPlanProvider(service: mockService);
      await Future<void>.delayed(Duration.zero);
    });

    test('mealPlan is initialised as an empty plan after loadMealPlan', () {
      expect(provider.mealPlan, isNotNull);
      expect(provider.isLoading, false);
      // All 7 day slots should be null in an empty plan
      for (final day in MealPlan.dayNames) {
        expect(provider.mealPlan!.days[day], isNull,
            reason: '$day should be null in empty plan');
      }
    });

    test('assignRecipe() sets the recipe id for the given day', () async {
      await provider.assignRecipe('monday', TestData.recipe);

      expect(provider.mealPlan!.days['monday'], TestData.recipe.id);
    });

    test('assignRecipe() caches the recipe in assignedRecipes', () async {
      await provider.assignRecipe('tuesday', TestData.recipe);

      expect(provider.assignedRecipes[TestData.recipe.id], TestData.recipe);
    });

    test('removeRecipe() clears the day slot', () async {
      await provider.assignRecipe('wednesday', TestData.recipe);
      expect(provider.mealPlan!.days['wednesday'], isNotNull);

      await provider.removeRecipe('wednesday');

      expect(provider.mealPlan!.days['wednesday'], isNull);
    });

    test('isLoading is false after loadMealPlan completes', () {
      expect(provider.isLoading, false);
    });

    test('generateGroceryItems() returns ingredients of assigned recipes', () async {
      await provider.assignRecipe('thursday', TestData.recipe);

      final items = provider.generateGroceryItems();

      expect(items.length, TestData.recipe.ingredients.length);
      final names = items.map((i) => i.name).toList();
      for (final ingredient in TestData.recipe.ingredients) {
        expect(names, contains(ingredient));
      }
    });
  });
}
