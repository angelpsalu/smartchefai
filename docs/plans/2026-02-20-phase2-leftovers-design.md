# Phase 2 Leftovers — Meal Planning Calendar + Nutrition Goals

**Date:** 2026-02-20
**Status:** Approved, ready for implementation
**Scope:** Features 2.3 and 2.5 from ROADMAP.md
**Architecture choice:** Option B — full separate providers + Firestore collections

---

## Features

### 2.3 Meal Planning Calendar
7-day weekly view. Tap a day to assign a recipe. Generate grocery list with replace/merge choice.

### 2.5 Nutrition Goal Tracking (Goals only)
User sets daily targets (calories, protein, carbs, fat). No automatic tracking. Saved to Firestore.

---

## Data Models

### `MealPlan`
```dart
class MealPlan {
  final String userId;
  final Map<String, String?> days; // {"monday": recipeId, ..., "sunday": recipeId}
  final DateTime weekStart;        // Monday of the displayed week
  final DateTime updatedAt;
}
```
Firestore path: `meal_plans/{userId}` (one doc per user, overwritten on save)

### `NutritionGoals`
```dart
class NutritionGoals {
  final String userId;
  final int dailyCalories;  // kcal
  final int dailyProtein;   // grams
  final int dailyCarbs;     // grams
  final int dailyFat;       // grams
}
```
Firestore path: `nutrition_goals/{userId}`

---

## Providers

### `MealPlanProvider`
File: `lib/providers/meal_plan_provider.dart`

State:
- `MealPlan? _mealPlan`
- `Map<String, Recipe> _assignedRecipes` — keyed by recipeId, populated on load and on assign
- `bool _isLoading`

Methods:
- `loadMealPlan()` — fetch from Firestore; for each recipeId in the plan, look up the recipe from FirebaseService cache
- `assignRecipe(String day, Recipe recipe)` — update `_mealPlan.days[day]` + `_assignedRecipes[recipe.id]` + push to Firestore
- `removeRecipe(String day)` — clear slot + push to Firestore
- `generateGroceryItems()` → `List<GroceryItem>` from all assigned recipes' ingredients

### `NutritionProvider`
File: `lib/providers/nutrition_provider.dart`

State:
- `NutritionGoals? _goals`
- `bool _isLoading`

Methods:
- `loadGoals()` — fetch from `nutrition_goals/{uid}`
- `saveGoals({calories, protein, carbs, fat})` — write to Firestore + update local state

---

## FirebaseService Additions

```dart
// Meal plan
Future<MealPlan?> getMealPlan()
Future<void> saveMealPlan(MealPlan plan)

// Nutrition goals
Future<NutritionGoals?> getNutritionGoals()
Future<void> saveNutritionGoals(NutritionGoals goals)
```

---

## Screens

### `MealPlanScreen`
File: `lib/features/meal_plan/meal_plan_screen.dart`
Route: `/meal-plan` (inside ShellRoute — shows bottom nav)

Layout:
```
AppBar: "Meal Plan" + "Generate List" action (calendar_month icon)
Body: ListView of 7 DayCards (Monday → Sunday)

DayCard:
  - Day name + date label
  - If recipe assigned: thumbnail + name + remove (×) IconButton
  - If empty: dashed border card + "+ Add Recipe" tap area
    → context.push('/meal-plan/pick-recipe', extra: dayName)

"Generate List" button:
  → showDialog with 3 options:
    "Replace list"  → GroceryListProvider.clearCheckedItems() then addItem() for all
    "Add to list"   → addItem() for all (GroceryListProvider deduplicates)
    "Cancel"
```

### `RecipePickerScreen`
File: `lib/features/meal_plan/recipe_picker_screen.dart`
Route: `/meal-plan/pick-recipe` (pushed, no bottom nav)
Extra: `String dayName`

Layout:
```
AppBar: "Pick a Recipe for {day}"
Body:
  TextField (search filter)
  GridView/ListView of RecipeProvider.recipes filtered by search
  Tap → MealPlanProvider.assignRecipe(day, recipe) → context.pop()
```

### `NutritionGoalsScreen`
File: `lib/features/nutrition_goals/nutrition_goals_screen.dart`
Route: `/nutrition-goals` (pushed, no bottom nav)

Layout:
```
AppBar: "Nutrition Goals"
Body:
  4 labeled TextFields (Calories kcal, Protein g, Carbs g, Fat g)
  Pre-filled from NutritionProvider.goals
  All use numeric keyboard
  "Save Goals" GradientButton → NutritionProvider.saveGoals() → pop
```

---

## Navigation Changes

### New bottom nav tab
Add calendar tab to `ShellRoute` bottom nav bar (slot between existing tabs — check current tab count in routes.dart).
Icon: `Icons.calendar_month_outlined` / `Icons.calendar_month`

### New routes in `routes.dart`
```
GoRoute(path: '/meal-plan', ...)          — ShellRoute child
GoRoute(path: '/meal-plan/pick-recipe', ...) — pushed (extra: String dayName)
GoRoute(path: '/nutrition-goals', ...)    — pushed
```

### Profile screen
Wire the currently no-op "Nutrition Goals" tile:
```dart
onTap: () => context.push('/nutrition-goals'),
```

---

## Provider Registration (`main.dart`)
```dart
ChangeNotifierProvider(create: (_) => MealPlanProvider()),
ChangeNotifierProvider(create: (_) => NutritionProvider()),
```
Both call `loadMealPlan()` / `loadGoals()` in their constructors.

---

## Firestore Security Rules (additions to `firestore.rules`)
```
match /meal_plans/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
match /nutrition_goals/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

---

## Files to Create
- `lib/models/models.dart` — add `MealPlan`, `NutritionGoals`
- `lib/services/firebase_service.dart` — add 4 new methods
- `lib/providers/meal_plan_provider.dart` — new file
- `lib/providers/nutrition_provider.dart` — new file
- `lib/features/meal_plan/meal_plan_screen.dart` — new file
- `lib/features/meal_plan/recipe_picker_screen.dart` — new file
- `lib/features/nutrition_goals/nutrition_goals_screen.dart` — new file

## Files to Modify
- `lib/app/routes.dart` — 3 new routes + bottom nav tab
- `lib/main.dart` — register 2 new providers
- `lib/features/profile/profile_screen.dart` — wire Nutrition Goals tile
- `firestore.rules` — 2 new collection rules
