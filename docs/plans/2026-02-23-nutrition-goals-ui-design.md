# Nutrition Goals UI — Design Document

**Date:** 2026-02-23  
**Feature:** Phase 2.5 — Nutrition Goal Tracking  
**Status:** Approved, ready for implementation

---

## Problem

`NutritionGoals` model and `NutritionProvider` exist. `FirebaseService` can read/write goals. But:
- No UI screen to view or edit goals
- No daily intake tracking
- Profile screen tile `onTap` is empty
- `NutritionProvider` is not registered in `main.dart`

## Scope

Build a full-screen `/nutrition-goals` route accessible from the Profile screen. Shows today's macro progress (consumed vs target) using linear progress bars, lists today's logged meals, and lets the user edit their daily targets.

Out of scope: weekly summary, charts (`fl_chart`), history beyond today.

---

## Daily Intake Storage

`SharedPreferences`, key `nutrition_log_YYYY-MM-DD`, value = JSON list of `{name, calories, protein, carbs, fat}`.

- Resets automatically each calendar day (new key = empty list)
- No new Firestore collection needed

## Macro Parsing

`Nutrition.protein/carbs/fat` are Strings like `"25g"`. Parse with:
```dart
int _parseGrams(String s) =>
    int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
```

---

## NutritionProvider Changes

Add to existing provider:
- `List<_LoggedMeal> _todayMeals` — local list of what was cooked today
- `int get todayCalories / todayProtein / todayCarbs / todayFat` — summed from `_todayMeals`
- `Future<void> loadTodayIntake()` — reads from SharedPreferences on init
- `Future<void> logRecipe(Recipe recipe)` — parses nutrition, appends to `_todayMeals`, persists

---

## Screen Layout

```
AppBar: "Nutrition Goals"

📊 TODAY'S PROGRESS
  Calories  [████░░░]  850 / 2000 kcal
  Protein   [████░░░]   35 / 50 g
  Carbs     [██████░]  120 / 250 g
  Fat       [████░░░]   25 / 70 g

🍽️ TODAY'S MEALS
  • Spaghetti Bolognese — 620 kcal
  • Greek Salad          — 230 kcal
  [empty state: "No meals logged today. Cook a recipe to track intake."]

⚙️ DAILY GOALS          [ Edit ]
  Calories  2000 kcal
  Protein     50 g
  Carbs      250 g
  Fat         70 g
```

- Goals section shows defaults (`NutritionGoals.defaults()`) when user has never saved
- Progress bars use `LinearProgressIndicator` with `value` clamped to `[0.0, 1.0]`
- Bars turn red when intake exceeds goal (value > 1.0 shown as full red bar)

---

## Edit Goals Bottom Sheet

`DraggableScrollableSheet` (0.6 initial, 0.9 max):
- 4 `TextFormField`s with `keyboardType: TextInputType.number`
- Pre-filled with current goals
- "Save" → `NutritionProvider.saveGoals(...)` → sheet closes

---

## Files Changed

| Action | File | Change |
|--------|------|--------|
| MODIFY | `lib/providers/nutrition_provider.dart` | Add `logRecipe()`, `todayMeals`, `todayCalories/Protein/Carbs/Fat`, `loadTodayIntake()` |
| CREATE | `lib/features/nutrition/nutrition_goals_screen.dart` | New screen |
| MODIFY | `lib/app/routes.dart` | Add `/nutrition-goals` GoRoute + `AppRoutes.nutritionGoals` |
| MODIFY | `lib/main.dart` | Register `NutritionProvider` |
| MODIFY | `lib/providers/app_providers.dart` | Export `NutritionProvider` |
| MODIFY | `lib/features/profile/profile_screen.dart` | Wire tile `onTap` → `context.push('/nutrition-goals')` |
| MODIFY | `lib/features/recipe_detail/recipe_detail_screen.dart` | Call `logRecipe(recipe)` in `_startCooking()` |
| MODIFY | `firestore.rules` | Add `nutrition_goals/{uid}` owner-only rule |

---

## Error Handling

- Goals load error: show defaults silently (don't block UI)
- Goals save error: SnackBar with error message
- Macro parsing failure: fallback to 0 (no crash)
