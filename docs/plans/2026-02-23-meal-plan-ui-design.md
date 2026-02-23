# Meal Plan UI — Design Document

**Date:** 2026-02-23  
**Feature:** Phase 2.3 — Meal Planning Calendar  
**Status:** Approved, ready for implementation

---

## Problem

The `MealPlan` model, `MealPlanProvider`, and Firebase service methods (`getMealPlan`, `saveMealPlan`) are all implemented. There is no UI screen or route — users cannot access meal planning.

## Scope

Build a 7-day meal plan screen accessible from the Home screen. Users can assign recipes to days, remove them, and push all ingredients to the grocery list.

Out of scope: week navigation (prior/next week), nutrition summary per day, calendar widget.

---

## Architecture

- **Route:** `/meal-plan` — full-screen `GoRoute` outside `ShellRoute` (same pattern as `/grocery`)
- **State:** `MealPlanProvider` — already built, needs registration in `main.dart`
- **Entry point:** A "Weekly Meal Plan" card on the Home screen

---

## Screen Layout

```
AppBar: "This Week's Meal Plan"

[Monday]    → assigned: recipe card (thumbnail + name + time + remove btn)
             → empty:    dashed card ("Tap to add a recipe")
[Tuesday]   → …
[Wednesday] → …
[Thursday]  → …
[Friday]    → …
[Saturday]  → …
[Sunday]    → …

[Add all to Grocery List]  ← sticky bottom button, disabled when 0 assigned
```

### Day Card — Empty State
- Dashed border, `AppColors.primaryOrange` at low opacity
- Day name (bold) + "Tap to add a recipe" subtitle + `+` icon
- Full-width, tappable → opens recipe picker bottom sheet

### Day Card — Assigned State
- Recipe thumbnail (left, 72×72, rounded corners) + name + cook time (right)
- 🗑️ `IconButton` (trailing) → calls `removeRecipe(day)` with undo SnackBar

---

## Recipe Picker Bottom Sheet

- `DraggableScrollableSheet` — initially 60% height, max 90%
- Search bar at top filters `RecipeProvider.recipes` locally (no network call)
- Scrollable list of compact recipe tiles: thumbnail + name + time
- Tapping a tile → `MealPlanProvider.assignRecipe(day, recipe)` → sheet closes

---

## Grocery Integration

- "Add all to Grocery List" button (bottom, `ElevatedButton`, `AppColors.primaryOrange`)
- Calls `MealPlanProvider.generateGroceryItems()` → adds via `GroceryListProvider.addItems()`
- SnackBar: `"X ingredients added to your grocery list"` with action "View List" (`context.push('/grocery')`)
- Button disabled (greyed) when no recipes assigned

---

## Files Changed

| Action | File | Change |
|--------|------|--------|
| CREATE | `lib/features/meal_plan/meal_plan_screen.dart` | New screen |
| MODIFY | `lib/app/routes.dart` | Add `/meal-plan` GoRoute |
| MODIFY | `lib/features/home/home_screen.dart` | Add Meal Plan card |
| MODIFY | `lib/main.dart` | Register `MealPlanProvider` |
| MODIFY | `firestore.rules` | Allow `meal_plans/{uid}` owner access |

---

## Firestore Rules Addition

```
match /meal_plans/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

---

## Error Handling

- Loading state: `CircularProgressIndicator` centred on screen
- Error state: error message + "Retry" button → `loadMealPlan()`
- Save failures: SnackBar with error message (provider already catches exceptions)
