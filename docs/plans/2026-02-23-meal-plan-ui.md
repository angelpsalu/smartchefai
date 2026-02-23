# Meal Plan UI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the Meal Planning screen — a 7-day vertical list where users assign recipes to days and push all ingredients to their grocery list.

**Architecture:** Full-screen GoRoute (`/meal-plan`) outside ShellRoute. `MealPlanProvider` (already built in `lib/providers/meal_plan_provider.dart`) needs registering in `main.dart`. Entry point is a card on the Home screen. Recipe picker is a DraggableScrollableSheet bottom sheet.

**Tech Stack:** Flutter + Provider (`MealPlanProvider`, `RecipeProvider`, `GroceryListProvider`) + GoRouter + Firebase (already wired)

---

## What Already Exists (DO NOT TOUCH)

- `lib/models/models.dart` → `MealPlan`, `NutritionGoals` models ✅
- `lib/providers/meal_plan_provider.dart` → `MealPlanProvider` with `loadMealPlan()`, `assignRecipe(day, recipe)`, `removeRecipe(day)`, `generateGroceryItems()` ✅
- `lib/services/firebase_service.dart` → `getMealPlan()`, `saveMealPlan()` ✅
- `MealPlan.dayNames` = `['monday','tuesday','wednesday','thursday','friday','saturday','sunday']` ✅

---

## Task 1: Register MealPlanProvider

**Files:**
- Modify: `lib/main.dart`

**Step 1:** Add import at top of `main.dart`:
```dart
import 'providers/meal_plan_provider.dart';
```

**Step 2:** Add `MealPlanProvider` to the `MultiProvider` list (after `GroceryListProvider`):
```dart
ChangeNotifierProvider(create: (_) => MealPlanProvider()),
```

**Step 3:** Verify the app still runs:
```bash
flutter analyze lib/main.dart
```
Expected: no errors.

---

## Task 2: Update Firestore Rules

**Files:**
- Modify: `firestore.rules`

**Step 1:** Add `meal_plans` rule inside the `match /databases/{database}/documents` block:
```
match /meal_plans/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

---

## Task 3: Create the Meal Plan Screen

**Files:**
- Create: `lib/features/meal_plan/meal_plan_screen.dart`

**Full implementation:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../app/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../providers/meal_plan_provider.dart';

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  static const List<String> _dayLabels = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("This Week's Meal Plan"),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<MealPlanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: provider.loadMealPlan,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final plan = provider.mealPlan;
          final assignedCount = plan?.days.values.whereType<String>().length ?? 0;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final dayKey = MealPlan.dayNames[index];
                    final dayLabel = _dayLabels[index];
                    final recipeId = plan?.days[dayKey];
                    final recipe = recipeId != null
                        ? provider.assignedRecipes[recipeId]
                        : null;

                    return _DayCard(
                      dayLabel: dayLabel,
                      dayKey: dayKey,
                      recipe: recipe,
                      onTap: () => _openRecipePicker(context, dayKey),
                      onRemove: () => provider.removeRecipe(dayKey),
                    );
                  },
                ),
              ),
              _GroceryButton(assignedCount: assignedCount),
            ],
          );
        },
      ),
    );
  }

  void _openRecipePicker(BuildContext context, String dayKey) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipePickerSheet(dayKey: dayKey),
    );
  }
}

// ─── Day Card ────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final String dayLabel;
  final String dayKey;
  final Recipe? recipe;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _DayCard({
    required this.dayLabel,
    required this.dayKey,
    required this.recipe,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return recipe == null ? _emptyCard(context) : _assignedCard(context);
  }

  Widget _emptyCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          border: Border.all(
            color: AppColors.primaryOrange.withValues(alpha: 0.4),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 90,
              child: Text(
                dayLabel,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                'Tap to add a recipe',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(Icons.add_circle_outline, color: AppColors.primaryOrange),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _assignedCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final r = recipe!;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppSpacing.borderRadiusMd),
            ),
            child: CachedNetworkImage(
              imageUrl: r.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: colorScheme.outlineVariant),
              errorWidget: (_, __, ___) => Container(
                color: colorScheme.outlineVariant,
                child: const Icon(Icons.restaurant),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Day + Recipe name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  r.name,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${r.prepTime + r.cookTime} min',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Remove
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// ─── Grocery Button ───────────────────────────────────────────────────────────

class _GroceryButton extends StatelessWidget {
  final int assignedCount;

  const _GroceryButton({required this.assignedCount});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: assignedCount == 0 ? null : () => _addToGrocery(context),
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(
              assignedCount == 0
                  ? 'Add all to Grocery List'
                  : 'Add all to Grocery List ($assignedCount recipes)',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
      ),
    );
  }

  void _addToGrocery(BuildContext context) {
    final items = context.read<MealPlanProvider>().generateGroceryItems();
    final grocery = context.read<GroceryListProvider>();
    for (final item in items) {
      grocery.addItem(item);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${items.length} ingredients added to your grocery list'),
        action: SnackBarAction(
          label: 'View List',
          onPressed: () => context.push('/grocery'),
        ),
      ),
    );
  }
}

// ─── Recipe Picker Bottom Sheet ───────────────────────────────────────────────

class _RecipePickerSheet extends StatefulWidget {
  final String dayKey;

  const _RecipePickerSheet({required this.dayKey});

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allRecipes = context.watch<RecipeProvider>().recipes;
    final filtered = _query.isEmpty
        ? allRecipes
        : allRecipes
            .where((r) => r.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Pick a Recipe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search recipes…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Recipe list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No recipes found',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final recipe = filtered[index];
                          return _RecipeTile(
                            recipe: recipe,
                            onTap: () {
                              context
                                  .read<MealPlanProvider>()
                                  .assignRecipe(widget.dayKey, recipe);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeTile({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: recipe.imageUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: colorScheme.outlineVariant),
          errorWidget: (_, __, ___) => Container(
            color: colorScheme.outlineVariant,
            child: const Icon(Icons.restaurant, size: 20),
          ),
        ),
      ),
      title: Text(recipe.name, style: textTheme.titleSmall),
      subtitle: Text(
        '${recipe.prepTime + recipe.cookTime} min · ${recipe.difficulty}',
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.add_rounded),
    );
  }
}
```

---

## Task 4: Register Route in routes.dart

**Files:**
- Modify: `lib/app/routes.dart`

**Step 1:** Add import at top:
```dart
import '../features/meal_plan/meal_plan_screen.dart';
```

**Step 2:** Add route inside the full-screen routes block (after `/grocery` route, before `/dietary-preferences`):
```dart
GoRoute(
  path: '/meal-plan',
  name: 'meal-plan',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => const MealPlanScreen(),
),
```

**Step 3:** Add `mealPlan` to `AppRoutes` constants at bottom of file:
```dart
static const String mealPlan = 'meal-plan';
```

---

## Task 5: Add Meal Plan Card to Home Screen

**Files:**
- Modify: `lib/features/home/home_screen.dart`

**Step 1:** Add `MealPlanProvider` import (it's already available via `app_providers.dart` export once added):
```dart
import '../../providers/meal_plan_provider.dart';
```

**Step 2:** Add a new sliver between Categories and Featured sections. Insert after `const SliverToBoxAdapter(child: Gap.lg()),` that follows categories and before `// Featured Recipes`:

```dart
// Meal Plan Banner
SliverToBoxAdapter(
  child: _buildMealPlanCard(context),
),

const SliverToBoxAdapter(child: Gap.lg()),
```

**Step 3:** Add the `_buildMealPlanCard` method to `_HomeScreenState`:

```dart
Widget _buildMealPlanCard(BuildContext context) {
  final provider = context.watch<MealPlanProvider>();
  final assignedCount = provider.mealPlan?.days.values
      .whereType<String>()
      .length ?? 0;

  return Padding(
    padding: AppSpacing.paddingHorizontalMd,
    child: GestureDetector(
      onTap: () => context.push('/meal-plan'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: AppColors.warmGradient,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        child: Row(
          children: [
            const Text('🗓️', style: TextStyle(fontSize: 36)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Meal Plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    assignedCount == 0
                        ? 'Plan your meals for the week'
                        : '$assignedCount of 7 days planned',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    ),
  );
}
```

---

## Task 6: Export MealPlanProvider from app_providers.dart

**Files:**
- Modify: `lib/providers/app_providers.dart`

Add export so screens can import via `app_providers.dart`:
```dart
export 'meal_plan_provider.dart';
```

> ⚠️ After adding this, remove the direct `meal_plan_provider.dart` import from `meal_plan_screen.dart` and `home_screen.dart` — use `app_providers.dart` instead.

---

## Task 7: Final Verify

Run analyzer:
```bash
flutter analyze lib/
```
Expected: zero errors. Warnings about unused imports are acceptable but fix them.

Run the app and verify:
1. Home screen shows the "Weekly Meal Plan" card
2. Tapping the card opens `/meal-plan`
3. Each day shows an empty slot
4. Tapping a slot opens the recipe picker bottom sheet
5. Searching and selecting a recipe assigns it to that day
6. The recipe card shows thumbnail, name, time
7. Tapping 🗑️ removes the recipe
8. "Add all to Grocery List" button is disabled when 0 assigned, enabled when ≥1
9. Tapping the button adds items + shows SnackBar with "View List" action
10. Refreshing the app (hot restart) persists the assigned recipes (Firestore)
