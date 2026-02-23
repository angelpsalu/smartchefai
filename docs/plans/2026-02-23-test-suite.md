# Phase 3.1 — Unit & Widget Test Suite Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a comprehensive test suite covering models, all 5 providers, and 2 auth widget screens (login + signup).

**Architecture:** Small DI refactor (optional `service` param in each provider constructor) so tests can inject a Mockito-generated `MockFirebaseService`. Model tests are pure Dart. Provider tests use stubs. Widget tests use a minimal GoRouter + `MultiProvider`.

**Tech Stack:** Flutter test, mockito 5, build_runner, fake_cloud_firestore 3, firebase_auth_mocks

---

## Coding Rules
- Use `withValues(alpha: x)` not `withOpacity(x)`
- Check `mounted` after every `await`
- `super.key` constructor style
- No raw numbers — use `AppSpacing`

---

### Task 1: Add dev dependencies

**Files:**
- Modify: `pubspec.yaml` (dev_dependencies section)

**Step 1: Replace dev_dependencies block**

Find:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

Replace with:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.13
  fake_cloud_firestore: ^3.1.0
  firebase_auth_mocks: ^0.14.1
```

**Step 2: Run pub get**

```
flutter pub get
```

Expected: resolves without conflicts. If `firebase_auth_mocks` version conflicts, run `flutter pub outdated` and use the highest compatible version.

---

### Task 2: Provider DI refactor — all 5 providers

Each provider must accept an optional `FirebaseService? service` parameter so tests can inject a mock. The production code passes nothing and gets the real singleton.

**Files:**
- Modify: `lib/providers/firebase_providers.dart` (RecipeProvider, UserProvider, GroceryListProvider)
- Modify: `lib/providers/meal_plan_provider.dart` (MealPlanProvider)
- Modify: `lib/providers/nutrition_provider.dart` (NutritionProvider)

#### 2A — RecipeProvider

Find (class field + constructor):
```dart
class RecipeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
```
```dart
  RecipeProvider() {
    _loadFavoriteIds();
  }
```

Replace with:
```dart
class RecipeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
```
```dart
  RecipeProvider({FirebaseService? service})
      : _firebaseService = service ?? FirebaseService() {
    _loadFavoriteIds();
  }
```

#### 2B — UserProvider

Find:
```dart
class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
```
```dart
  UserProvider() {
    _initUser();
  }
```

Replace with:
```dart
class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
```
```dart
  UserProvider({FirebaseService? service})
      : _firebaseService = service ?? FirebaseService() {
    _initUser();
  }
```

#### 2C — GroceryListProvider

Find:
```dart
class GroceryListProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
```
```dart
  GroceryListProvider() {
    _init();
  }
```

Replace with:
```dart
class GroceryListProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
```
```dart
  GroceryListProvider({FirebaseService? service})
      : _firebaseService = service ?? FirebaseService() {
    _init();
  }
```

#### 2D — MealPlanProvider

In `lib/providers/meal_plan_provider.dart`, find:
```dart
  final FirebaseService _service = FirebaseService();
```
```dart
  MealPlanProvider() {
    loadMealPlan();
  }
```

Replace with:
```dart
  final FirebaseService _service;
```
```dart
  MealPlanProvider({FirebaseService? service})
      : _service = service ?? FirebaseService() {
    loadMealPlan();
  }
```

#### 2E — NutritionProvider

In `lib/providers/nutrition_provider.dart`, find:
```dart
  final FirebaseService _service = FirebaseService();
```
```dart
  NutritionProvider() {
    loadGoals();
    loadTodayIntake();
  }
```

Replace with:
```dart
  final FirebaseService _service;
```
```dart
  NutritionProvider({FirebaseService? service})
      : _service = service ?? FirebaseService() {
    loadGoals();
    loadTodayIntake();
  }
```

**Verify:**
```
flutter analyze
```
Expected: `No issues found!`

---

### Task 3: Create test helpers

**Files:**
- Create: `test/helpers/mock_firebase_service.dart`
- Create: `test/helpers/test_data.dart`

#### 3A — `test/helpers/mock_firebase_service.dart`

```dart
import 'package:mockito/annotations.dart';
import 'package:smartchefai/services/firebase_service.dart';

@GenerateMocks([FirebaseService])
void main() {}
```

This file triggers build_runner to generate `mock_firebase_service.mocks.dart`. Do NOT write the mocks file by hand — it is generated in Task 4.

#### 3B — `test/helpers/test_data.dart`

```dart
import 'package:smartchefai/models/models.dart';

/// Shared test fixtures — canonical, minimal data used across all tests.
class TestData {
  TestData._();

  static Nutrition nutrition = const Nutrition(
    calories: 350,
    protein: '25g',
    carbs: '40g',
    fat: '10g',
    fiber: '5g',
  );

  static Recipe recipe = Recipe(
    id: 'r1',
    name: 'Test Pasta',
    ingredients: ['pasta', 'tomato', 'cheese'],
    steps: ['Boil pasta', 'Add sauce', 'Serve'],
    prepTime: 10,
    cookTime: 20,
    difficulty: 'Easy',
    cuisine: 'Italian',
    dietaryTags: ['vegetarian'],
    nutrition: nutrition,
    servings: 2,
    imageUrl: 'https://example.com/pasta.jpg',
    rating: 4.5,
  );

  static Recipe recipe2 = Recipe(
    id: 'r2',
    name: 'Test Salad',
    ingredients: ['lettuce', 'tomato'],
    steps: ['Chop', 'Mix'],
    prepTime: 5,
    cookTime: 0,
    difficulty: 'Easy',
    cuisine: 'American',
    dietaryTags: ['vegan', 'gluten-free'],
    nutrition: const Nutrition(
      calories: 120,
      protein: '3g',
      carbs: '10g',
      fat: '2g',
      fiber: '3g',
    ),
    servings: 1,
    imageUrl: 'https://example.com/salad.jpg',
  );

  static AppUser appUser = AppUser(
    id: 'uid-1',
    name: 'Test User',
    email: 'test@example.com',
    dietaryPreferences: ['vegetarian'],
    allergies: ['nuts'],
    favoriteRecipes: ['r1'],
    searchHistory: [],
    recipesCooked: 5,
    currentStreak: 3,
  );

  static NutritionGoals nutritionGoals = const NutritionGoals(
    userId: 'uid-1',
    dailyCalories: 2000,
    dailyProtein: 50,
    dailyCarbs: 250,
    dailyFat: 70,
  );

  static GroceryItem groceryItem = const GroceryItem(
    name: 'Tomato',
    quantity: 2.0,
    unit: 'pcs',
    category: 'vegetables',
    recipes: ['r1'],
  );
}
```

---

### Task 4: Generate mocks with build_runner

**Step 1: Run build_runner**

```
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `test/helpers/mock_firebase_service.mocks.dart`.

**Step 2: Verify the file exists**

```
Get-ChildItem test\helpers\
```

Expected output includes `mock_firebase_service.dart` and `mock_firebase_service.mocks.dart`.

---

### Task 5: Model tests — Nutrition + Recipe

**Files:**
- Create: `test/models/nutrition_test.dart`
- Create: `test/models/recipe_test.dart`

#### 5A — `test/models/nutrition_test.dart`

```dart
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
```

**Run:**
```
flutter test test/models/nutrition_test.dart -v
```

#### 5B — `test/models/recipe_test.dart`

```dart
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
        'cuisine': '', 'dietary_tags': [],
        'nutrition': {}, 'servings': 1, 'image_url': '',
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
        'difficulty': '', 'cuisine': '', 'dietary_tags': [],
        'nutrition': {}, 'servings': 1, 'image_url': '',
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
```

**Run:**
```
flutter test test/models/ -v
```

---

### Task 6: Model tests — GroceryItem, GroceryList, MealPlan, NutritionGoals

**Files:**
- Create: `test/models/grocery_item_test.dart`
- Create: `test/models/meal_plan_test.dart`
- Create: `test/models/nutrition_goals_test.dart`

#### 6A — `test/models/grocery_item_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smartchefai/models/models.dart';
import '../helpers/test_data.dart';

void main() {
  group('GroceryItem', () {
    test('fromJson parses all fields', () {
      final item = GroceryItem.fromJson({
        'name': 'Tomato',
        'quantity': 2.0,
        'unit': 'pcs',
        'category': 'vegetables',
        'checked': false,
        'recipes': ['r1'],
      });
      expect(item.name, 'Tomato');
      expect(item.quantity, 2.0);
      expect(item.unit, 'pcs');
      expect(item.category, 'vegetables');
      expect(item.checked, false);
      expect(item.recipes, ['r1']);
    });

    test('fromJson uses defaults for missing fields', () {
      final item = GroceryItem.fromJson({'name': 'Sugar'});
      expect(item.quantity, 1.0);
      expect(item.unit, '');
      expect(item.category, 'other');
      expect(item.checked, false);
    });

    test('copyWith toggles checked', () {
      final item = TestData.groceryItem;
      final toggled = item.copyWith(checked: true);
      expect(toggled.checked, true);
      expect(toggled.name, item.name);
    });

    test('toJson round-trips', () {
      final item = TestData.groceryItem;
      final json = item.toJson();
      final restored = GroceryItem.fromJson(json);
      expect(restored.name, item.name);
      expect(restored.quantity, item.quantity);
      expect(restored.checked, item.checked);
    });
  });

  group('GroceryList', () {
    test('fromJson groups items by category', () {
      final list = GroceryList.fromJson({
        'id': 'gl1',
        'user_id': 'uid-1',
        'items': [
          {'name': 'Tomato', 'quantity': 1.0, 'unit': '', 'category': 'vegetables', 'checked': false, 'recipes': []},
          {'name': 'Apple',  'quantity': 2.0, 'unit': '', 'category': 'fruits',     'checked': false, 'recipes': []},
          {'name': 'Carrot', 'quantity': 1.0, 'unit': '', 'category': 'vegetables', 'checked': true,  'recipes': []},
        ],
        'recipes': [],
        'status': 'active',
        'created_at': '2024-01-01T00:00:00.000',
      });
      expect(list.byCategory['vegetables']!.length, 2);
      expect(list.byCategory['fruits']!.length, 1);
      expect(list.items.length, 3);
    });

    test('fromJson uses empty list for missing items', () {
      final list = GroceryList.fromJson({
        'id': 'gl2',
        'user_id': 'uid-1',
        'recipes': [],
        'created_at': '2024-01-01T00:00:00.000',
        'status': 'active',
      });
      expect(list.items, isEmpty);
    });
  });
}
```

#### 6B — `test/models/meal_plan_test.dart`

```dart
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
```

#### 6C — `test/models/nutrition_goals_test.dart`

```dart
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
```

---

### Task 7: Provider tests — RecipeProvider

**Files:**
- Create: `test/providers/recipe_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/providers/firebase_providers.dart';
import '../helpers/mock_firebase_service.mocks.dart';
import '../helpers/test_data.dart';

void main() {
  late MockFirebaseService mockService;
  late RecipeProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    when(mockService.getFavoriteIds()).thenAnswer((_) async => []);
    provider = RecipeProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('RecipeProvider', () {
    test('initial state: empty, not loading', () {
      expect(provider.recipes, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('loadRecipes() populates recipes list', () async {
      when(mockService.getAllRecipes()).thenAnswer(
        (_) async => [TestData.recipe, TestData.recipe2],
      );

      await provider.loadRecipes();

      expect(provider.recipes.length, 2);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('loadRecipes() sets error on exception', () async {
      when(mockService.getAllRecipes()).thenThrow(Exception('Network error'));

      await provider.loadRecipes();

      expect(provider.error, isNotNull);
      expect(provider.isLoading, false);
    });

    test('isFavorite() returns false for unknown id', () {
      expect(provider.isFavorite('unknown'), false);
    });

    test('toggleFavorite() adds recipe to favorites', () async {
      when(mockService.addFavorite(any)).thenAnswer((_) async {});
      when(mockService.removeFavorite(any)).thenAnswer((_) async {});

      when(mockService.getAllRecipes()).thenAnswer((_) async => [TestData.recipe]);
      await provider.loadRecipes();

      provider.toggleFavorite('r1');

      expect(provider.isFavorite('r1'), true);
      expect(provider.favorites.any((r) => r.id == 'r1'), true);
    });

    test('toggleFavorite() removes recipe already in favorites', () async {
      when(mockService.addFavorite(any)).thenAnswer((_) async {});
      when(mockService.removeFavorite(any)).thenAnswer((_) async {});

      when(mockService.getAllRecipes()).thenAnswer((_) async => [TestData.recipe]);
      await provider.loadRecipes();

      provider.toggleFavorite('r1'); // add
      provider.toggleFavorite('r1'); // remove

      expect(provider.isFavorite('r1'), false);
    });

    test('searchRecipes() returns matched recipes', () async {
      when(mockService.searchRecipes(any)).thenAnswer(
        (_) async => [TestData.recipe],
      );

      final results = await provider.searchRecipes('pasta');

      expect(results.length, 1);
      expect(results.first.name, 'Test Pasta');
    });
  });
}
```

**Run:**
```
flutter test test/providers/recipe_provider_test.dart -v
```

---

### Task 8: Provider tests — UserProvider

**Files:**
- Create: `test/providers/user_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/providers/firebase_providers.dart';
import '../helpers/mock_firebase_service.mocks.dart';
import '../helpers/test_data.dart';

void main() {
  late MockFirebaseService mockService;
  late UserProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    when(mockService.currentUser).thenReturn(null);
    provider = UserProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('UserProvider', () {
    test('initial state: no user, not loading', () {
      expect(provider.currentUser, null);
      expect(provider.isLoading, false);
    });

    test('isAuthenticated is false when no user', () {
      expect(provider.isAuthenticated, false);
    });

    test('createUser() sets appUser on success', () async {
      when(mockService.createUserProfile(name: anyNamed('name'), email: anyNamed('email')))
          .thenAnswer((_) async {});
      when(mockService.getUserProfile()).thenAnswer((_) async => TestData.appUser);

      final result = await provider.createUser('Test User', 'test@example.com');

      expect(result, true);
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.name, 'Test User');
    });

    test('createUser() sets error on exception', () async {
      when(mockService.createUserProfile(name: anyNamed('name'), email: anyNamed('email')))
          .thenThrow(Exception('Firestore error'));

      final result = await provider.createUser('Test', 'test@example.com');

      expect(result, false);
      expect(provider.error, isNotNull);
    });

    test('logout() clears user', () async {
      when(mockService.signOut()).thenAnswer((_) async {});
      when(mockService.createUserProfile(name: anyNamed('name'), email: anyNamed('email')))
          .thenAnswer((_) async {});
      when(mockService.getUserProfile()).thenAnswer((_) async => TestData.appUser);
      await provider.createUser('Test', 'test@example.com');

      await provider.logout();

      expect(provider.currentUser, null);
    });

    test('setPreferences() updates dietary preferences', () async {
      when(mockService.updatePreferences(
        dietaryPreferences: anyNamed('dietaryPreferences'),
        allergies: anyNamed('allergies'),
      )).thenAnswer((_) async {});

      when(mockService.getUserProfile()).thenAnswer((_) async => TestData.appUser);
      when(mockService.createUserProfile(name: anyNamed('name'), email: anyNamed('email')))
          .thenAnswer((_) async {});
      await provider.createUser('Test', 'test@example.com');

      final result = await provider.setPreferences(['vegan'], ['gluten']);
      expect(result, true);
      expect(provider.currentUser!.dietaryPreferences, ['vegan']);
    });

    test('isDarkMode defaults to false', () {
      expect(provider.isDarkMode, false);
    });

    test('toggleDarkMode() flips the flag', () async {
      provider.toggleDarkMode();
      expect(provider.isDarkMode, true);
      provider.toggleDarkMode();
      expect(provider.isDarkMode, false);
    });
  });
}
```

---

### Task 9: Provider tests — GroceryListProvider, MealPlanProvider, NutritionProvider

**Files:**
- Create: `test/providers/grocery_provider_test.dart`
- Create: `test/providers/meal_plan_provider_test.dart`
- Create: `test/providers/nutrition_provider_test.dart`

#### 9A — `test/providers/grocery_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/providers/firebase_providers.dart';
import '../helpers/mock_firebase_service.mocks.dart';
import '../helpers/test_data.dart';

void main() {
  late MockFirebaseService mockService;
  late GroceryListProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    when(mockService.currentUser).thenReturn(null);
    when(mockService.getGroceryLists()).thenAnswer((_) async => []);
    provider = GroceryListProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('GroceryListProvider', () {
    test('initial state: empty items', () {
      expect(provider.items, isEmpty);
      expect(provider.isLoading, false);
    });

    test('addItem() adds an item', () async {
      when(mockService.createGroceryList(
        name: anyNamed('name'),
        items: anyNamed('items'),
        recipes: anyNamed('recipes'),
      )).thenAnswer((_) async => 'list-id');

      await provider.addItem(TestData.groceryItem);

      expect(provider.items.length, 1);
      expect(provider.items.first.name, 'Tomato');
    });

    test('toggleItem() flips checked state', () async {
      when(mockService.createGroceryList(
        name: anyNamed('name'),
        items: anyNamed('items'),
        recipes: anyNamed('recipes'),
      )).thenAnswer((_) async => 'list-id');

      await provider.addItem(TestData.groceryItem);
      await provider.toggleItem('Tomato');

      expect(provider.items.first.checked, true);
    });

    test('clearAll() empties item list', () async {
      when(mockService.createGroceryList(
        name: anyNamed('name'),
        items: anyNamed('items'),
        recipes: anyNamed('recipes'),
      )).thenAnswer((_) async => 'list-id');

      await provider.addItem(TestData.groceryItem);
      await provider.clearAll();

      expect(provider.items, isEmpty);
    });
  });
}
```

> **Note:** If `addItem`, `toggleItem`, or `clearAll` method names differ, check `lib/providers/firebase_providers.dart` for the exact public API of `GroceryListProvider` and adjust accordingly.

#### 9B — `test/providers/meal_plan_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/providers/meal_plan_provider.dart';
import '../helpers/mock_firebase_service.mocks.dart';

void main() {
  late MockFirebaseService mockService;
  late MealPlanProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    when(mockService.currentUser).thenReturn(null);
    provider = MealPlanProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('MealPlanProvider', () {
    test('initial state: no meal plan loaded (user not signed in)', () {
      expect(provider.mealPlan, null);
      expect(provider.isLoading, false);
    });

    test('MealPlan.copyWith can assign recipe to day', () {
      final plan = MealPlan.empty('uid-1');
      final updated = plan.copyWith(days: {...plan.days, 'monday': 'r1'});
      expect(updated.days['monday'], 'r1');
    });

    test('assignedRecipes starts empty', () {
      expect(provider.assignedRecipes, isEmpty);
    });

    test('error starts null', () {
      expect(provider.error, null);
    });
  });
}
```

#### 9C — `test/providers/nutrition_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/providers/nutrition_provider.dart';
import '../helpers/mock_firebase_service.mocks.dart';
import '../helpers/test_data.dart';

void main() {
  late MockFirebaseService mockService;
  late NutritionProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    when(mockService.currentUser).thenReturn(null);
    when(mockService.getNutritionGoals()).thenAnswer((_) async => null);
    provider = NutritionProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('NutritionProvider', () {
    test('initial state: no goals, empty intake', () {
      expect(provider.goals, null);
      expect(provider.todayCalories, 0);
      expect(provider.todayProtein, 0);
      expect(provider.todayMeals, isEmpty);
    });

    test('logRecipe() adds intake from recipe', () async {
      await provider.logRecipe(TestData.recipe);

      expect(provider.todayCalories, 350);
      expect(provider.todayMeals.length, 1);
      expect(provider.todayMeals.first.name, 'Test Pasta');
    });

    test('logRecipe() accumulates multiple meals', () async {
      await provider.logRecipe(TestData.recipe);
      await provider.logRecipe(TestData.recipe2);

      expect(provider.todayCalories, 350 + 120);
      expect(provider.todayMeals.length, 2);
    });

    test('saveGoals() updates goals on success', () async {
      when(mockService.saveNutritionGoals(any)).thenAnswer((_) async {});

      await provider.saveGoals(
        calories: 1800,
        protein: 55,
        carbs: 230,
        fat: 60,
      );

      expect(provider.goals, isNotNull);
      expect(provider.goals!.dailyCalories, 1800);
    });

    test('todayProtein sums protein grams across meals', () async {
      await provider.logRecipe(TestData.recipe); // 25g protein

      expect(provider.todayProtein, 25);
    });
  });
}
```

**Run:**
```
flutter test test/providers/ -v
```

---

### Task 10: Widget tests — LoginScreen

**Files:**
- Create: `test/widgets/login_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/features/auth/login_screen.dart';
import 'package:smartchefai/providers/firebase_providers.dart';
import '../helpers/mock_firebase_service.mocks.dart';

Widget _buildTestApp(UserProvider userProvider) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('Home'))),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockFirebaseService mockService;
  late UserProvider userProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    when(mockService.currentUser).thenReturn(null);
    userProvider = UserProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('LoginScreen', () {
    testWidgets('renders at least 2 form fields', (tester) async {
      await tester.pumpWidget(_buildTestApp(userProvider));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('renders Login button', (tester) async {
      await tester.pumpWidget(_buildTestApp(userProvider));
      await tester.pumpAndSettle();

      // Look for button text — adjust if the button says 'Sign In' instead
      expect(find.text('Login'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows validation error when submitting empty form', (tester) async {
      await tester.pumpWidget(_buildTestApp(userProvider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Validation message should appear — adjust text to match actual validator message
      expect(find.text('Please enter your email'), findsOneWidget);
    });
  });
}
```

> **IMPORTANT:** Read `lib/features/auth/login_screen.dart` to verify the exact text of the Login button and validator messages before running this test. Adjust strings to match.

**Run:**
```
flutter test test/widgets/login_screen_test.dart -v
```

---

### Task 11: Widget tests — SignupScreen

**Files:**
- Create: `test/widgets/signup_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/features/auth/signup_screen.dart';
import 'package:smartchefai/providers/firebase_providers.dart';
import '../helpers/mock_firebase_service.mocks.dart';

Widget _buildTestApp(UserProvider userProvider) {
  final router = GoRouter(
    initialLocation: '/signup',
    routes: [
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('Home'))),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockFirebaseService mockService;
  late UserProvider userProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    when(mockService.currentUser).thenReturn(null);
    userProvider = UserProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('SignupScreen', () {
    testWidgets('renders at least 4 form fields', (tester) async {
      await tester.pumpWidget(_buildTestApp(userProvider));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsAtLeastNWidgets(4));
    });

    testWidgets('renders Create Account / Sign Up button', (tester) async {
      await tester.pumpWidget(_buildTestApp(userProvider));
      await tester.pumpAndSettle();

      // Adjust text to match the actual button label
      expect(find.textContaining('Create'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows validation when form submitted empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(userProvider));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Create').last);
      await tester.pumpAndSettle();

      // At least one validation error text must appear
      final hasValidationText =
          find.textContaining('required').evaluate().isNotEmpty ||
          find.textContaining('enter').evaluate().isNotEmpty ||
          find.textContaining('Please').evaluate().isNotEmpty;
      expect(hasValidationText, true);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(_buildTestApp(userProvider));
      await tester.pumpAndSettle();

      // Fill all fields but with mismatched passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different456');

      await tester.tap(find.textContaining('Create').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('match').evaluate().isNotEmpty ||
             find.byType(SnackBar).evaluate().isNotEmpty, true);
    });
  });
}
```

**Run:**
```
flutter test test/widgets/signup_screen_test.dart -v
```

---

### Task 12: Run full test suite + fix issues

**Step 1: Run all tests**

```
flutter test -v
```

**Step 2: Fix common issues**

| Issue | Fix |
|-------|-----|
| `GroceryListProvider.addItem` not found | Check `lib/providers/firebase_providers.dart` for the exact public method name and update test |
| `GroceryListProvider.toggleItem` not found | Same |
| `GroceryListProvider.clearAll` not found | Same |
| `MockFirebaseService.getNutritionGoals` not found | Check `lib/services/firebase_service.dart` for exact method signature and update stub |
| `MockFirebaseService.saveNutritionGoals` not found | Same |
| Widget test: label text mismatch (e.g. button says 'Sign In' not 'Login') | Read actual screen file and adjust expected strings |
| `when(mockService.currentUser)` type error | `currentUser` returns `firebase_auth.User?` — ensure mockito can stub it; if not, remove the stub and let it return default null |
| Missing stub for unrelated method | Add `when(mock.method()).thenAnswer(...)` or use `throwOnMissingStub(mock)` |

**Step 3: Final analyzer check**

```
flutter analyze
```

Expected: `No issues found!`
