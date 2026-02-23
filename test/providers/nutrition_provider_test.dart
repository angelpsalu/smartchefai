import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/providers/nutrition_provider.dart';
import '../helpers/mock_firebase_service.mocks.dart';
import '../helpers/test_data.dart';

/// Minimal fake Firebase user — only uid is needed.
class _FakeUser extends Fake implements firebase_auth.User {
  @override
  String get uid => 'uid-1';
}

void main() {
  late MockFirebaseService mockService;
  late NutritionProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    // currentUser = null → loadGoals() returns immediately without calling service
    when(mockService.currentUser).thenReturn(null);
    provider = NutritionProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('NutritionProvider', () {
    test('goals is null initially when not authenticated', () {
      expect(provider.goals, isNull);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('todayCalories is 0 when no meals have been logged', () {
      expect(provider.todayCalories, 0);
      expect(provider.todayMeals, isEmpty);
    });

    test('todayProtein, todayCarbs, todayFat are 0 initially', () {
      expect(provider.todayProtein, 0);
      expect(provider.todayCarbs, 0);
      expect(provider.todayFat, 0);
    });

    test('logRecipe() adds the recipe calories to todayCalories', () async {
      // TestData.nutrition: calories 350, protein 25g, carbs 40g, fat 10g
      await provider.logRecipe(TestData.recipe);

      expect(provider.todayCalories, 350);
      expect(provider.todayProtein, 25);
      expect(provider.todayCarbs, 40);
      expect(provider.todayFat, 10);
    });

    test('logRecipe() appends entry to todayMeals', () async {
      await provider.logRecipe(TestData.recipe);

      expect(provider.todayMeals.length, 1);
      expect(provider.todayMeals.first.name, TestData.recipe.name);
      expect(provider.todayMeals.first.calories, 350);
    });

    test('logRecipe() accumulates multiple recipes', () async {
      await provider.logRecipe(TestData.recipe);   // 350 cal
      await provider.logRecipe(TestData.recipe2);  // 120 cal

      expect(provider.todayCalories, 470);
      expect(provider.todayMeals.length, 2);
    });

    test('loadTodayIntake() restores persisted meals from SharedPreferences',
        () async {
      await provider.logRecipe(TestData.recipe);
      expect(provider.todayCalories, 350);

      // Create a fresh provider — it reads SharedPreferences in loadTodayIntake()
      final provider2 = NutritionProvider(service: mockService);
      await Future<void>.delayed(Duration.zero);

      expect(provider2.todayCalories, 350);
      expect(provider2.todayMeals.length, 1);
    });

    test('saveGoals() persists goals via service and updates local state',
        () async {
      await provider.saveGoals(
        calories: 2000,
        protein: 50,
        carbs: 250,
        fat: 70,
      );

      expect(provider.goals, isNotNull);
      expect(provider.goals!.dailyCalories, 2000);
      expect(provider.goals!.dailyProtein, 50);
      expect(provider.goals!.dailyCarbs, 250);
      expect(provider.goals!.dailyFat, 70);
      expect(provider.isLoading, false);
    });

    test('loadGoals() fetches goals from service when authenticated', () async {
      when(mockService.currentUser).thenReturn(_FakeUser());
      when(mockService.getNutritionGoals())
          .thenAnswer((_) async => TestData.nutritionGoals);

      final authProvider = NutritionProvider(service: mockService);
      await Future<void>.delayed(Duration.zero);

      expect(authProvider.goals, isNotNull);
      expect(authProvider.goals!.dailyCalories,
          TestData.nutritionGoals.dailyCalories);
    });
  });
}
