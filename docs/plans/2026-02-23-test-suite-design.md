# Phase 3.1 Unit & Widget Tests — Design Document

**Date:** 2026-02-23  
**Feature:** Phase 3.1 — Test Suite  
**Status:** Approved, ready for implementation

---

## Problem

No tests exist. The app has no `test/` directory. `flutter_test` is in dev_dependencies but nothing else. All providers hard-code `FirebaseService()`, making them untestable without a DI refactor.

## Scope

- **Model unit tests** — all models: `fromJson`, `copyWith`, `fromFirestore`, edge cases
- **Provider unit tests** — all 5 providers: loading states, error states, data mutations
- **Widget tests** — auth screens (login, signup, forgot password) + home screen smoke tests

Out of scope: integration tests, full end-to-end flows, Firebase emulator setup.

---

## Infrastructure

### New dev dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  fake_cloud_firestore: ^3.1.0
  mockito: ^5.4.4
  build_runner: ^2.4.13
  firebase_auth_mocks: ^0.14.1
```

### Provider DI refactor (backward-compatible)

Each of the 5 providers (`RecipeProvider`, `UserProvider`, `GroceryListProvider`, `MealPlanProvider`, `NutritionProvider`) gets an optional `service` constructor parameter:

```dart
class RecipeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  RecipeProvider({FirebaseService? service})
      : _firebaseService = service ?? FirebaseService();
```

`main.dart` calls `RecipeProvider()` with no args — behavior unchanged in production. Tests pass `MockFirebaseService()`.

---

## Test Structure

```
test/
├── helpers/
│   ├── mock_firebase_service.dart   # @GenerateMocks([FirebaseService]) + generated file
│   └── test_data.dart               # Shared Recipe/AppUser/etc. fixtures
├── models/
│   ├── recipe_test.dart
│   ├── app_user_test.dart
│   ├── grocery_list_test.dart
│   ├── meal_plan_test.dart
│   └── nutrition_goals_test.dart
├── providers/
│   ├── recipe_provider_test.dart
│   ├── user_provider_test.dart
│   ├── grocery_list_provider_test.dart
│   ├── meal_plan_provider_test.dart
│   └── nutrition_provider_test.dart
└── widgets/
    ├── login_screen_test.dart
    ├── signup_screen_test.dart
    └── home_screen_test.dart
```

---

## Mocking Strategy

- `MockFirebaseService` generated via `@GenerateMocks([FirebaseService])` — run `dart run build_runner build`
- Widget tests wrap screens in `MultiProvider` with `ChangeNotifierProvider.value()` passing mock providers
- Widget tests use a simple `MaterialApp` (no GoRouter) for screens that don't need routing, or a minimal `GoRouter` for screens that do
- `firebase_auth_mocks` handles `FirebaseAuth` in provider tests if needed

---

## Model Test Coverage

For each model, test:
1. `fromJson` with complete valid data
2. `fromJson` with missing/null optional fields → defaults applied
3. `fromJson` with wrong types (e.g., `calories` as String when int expected)
4. `copyWith` — changing each field leaves others unchanged
5. `fromFirestore` factory (where applicable)
6. `toFirestore` / `toJson` round-trip

---

## Provider Test Coverage

For each provider, test:
1. Initial state (loading=false, data=null/empty, error=null)
2. Successful load — mock returns data → state updates correctly
3. Failed load — mock throws → `error` set, `isLoading` false
4. `notifyListeners()` called on state change (verify via listener count)
5. Mutations (add/remove/toggle) update local state immediately
6. Mutations propagate to `FirebaseService` (verify mock was called)

---

## Widget Test Coverage

### Auth screens (login, signup, forgot password)
- Screen renders without crash
- Form validation: submit with empty fields → validation errors shown
- Error display: provider sets error → snackbar/message visible
- Navigation links tap (sign in → forgot password, etc.)

### Home screen
- Renders with empty recipe list (loading state)
- Renders with recipe list (verify recipe cards appear)
- Scan button tap navigates correctly

---

## Running Tests

```bash
# Generate mockito mocks
dart run build_runner build --delete-conflicting-outputs

# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```
