# Meal Planning Calendar + Nutrition Goals Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a 7-day meal planning calendar screen and a nutrition goals settings screen to SmartChef AI.

**Architecture:** Two new providers (`MealPlanProvider`, `NutritionProvider`) backed by separate Firestore collections (`meal_plans/{uid}`, `nutrition_goals/{uid}`). Meal Plan gets a dedicated bottom nav tab (slot 4, Profile shifts to 5). Recipe picker is a full push route.

**Tech Stack:** Flutter · Provider (ChangeNotifier) · GoRouter · Firestore · existing `AppColors`/`AppSpacing`/`AppTypography` theme · `GradientButton`, `EmptyState`, `SmartChefAppBar` shared widgets

---

## Nav bar context

Current bottom nav Row children (left→right):
```
Home(0) | Search(1) | [Camera-no index] | Favorites(3) | Profile(4)
```
After this plan:
```
Home(0) | Search(1) | [Camera-no index] | Favorites(3) | MealPlan(4) | Profile(5)
```
The `currentIndex` for `/meal-plan` = 4, `/profile` shifts from 4 → 5.

---

## Task 1: Add `MealPlan` and `NutritionGoals` models to `models.dart`

**Files:**
- Modify: `lib/models/models.dart` (append after `AppUser` class)

**Step 1: Add `MealPlan` model**

Append this class at the bottom of `lib/models/models.dart` (before the closing of the file):

```dart
/// Meal plan for a single week, stored as one Firestore doc per user
class MealPlan {
  final String userId;
  // Keys: 'monday'…'sunday'. Values: recipeId (null = empty slot)
  final Map<String, String?> days;
  final DateTime weekStart;
  final DateTime updatedAt;

  static const List<String> dayNames = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

  const MealPlan({
    required this.userId,
    required this.days,
    required this.weekStart,
    required this.updatedAt,
  });

  MealPlan copyWith({
    String? userId,
    Map<String, String?>? days,
    DateTime? weekStart,
    DateTime? updatedAt,
  }) {
    return MealPlan(
      userId: userId ?? this.userId,
      days: days ?? this.days,
      weekStart: weekStart ?? this.weekStart,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MealPlan.empty(String userId) {
    final now = DateTime.now();
    // Find Monday of this week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return MealPlan(
      userId: userId,
      days: {for (final d in dayNames) d: null},
      weekStart: DateTime(monday.year, monday.month, monday.day),
      updatedAt: now,
    );
  }

  factory MealPlan.fromFirestore(Map<String, dynamic> data) {
    final rawDays = data['days'] as Map<String, dynamic>? ?? {};
    return MealPlan(
      userId: data['user_id'] as String? ?? '',
      days: {
        for (final d in dayNames) d: rawDays[d] as String?,
      },
      weekStart: (data['week_start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'user_id': userId,
    'days': days,
    'week_start': Timestamp.fromDate(weekStart),
    'updated_at': FieldValue.serverTimestamp(),
  };
}

/// User's daily nutrition targets
class NutritionGoals {
  final String userId;
  final int dailyCalories;
  final int dailyProtein; // grams
  final int dailyCarbs;   // grams
  final int dailyFat;     // grams

  const NutritionGoals({
    required this.userId,
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyCarbs,
    required this.dailyFat,
  });

  NutritionGoals copyWith({
    String? userId,
    int? dailyCalories,
    int? dailyProtein,
    int? dailyCarbs,
    int? dailyFat,
  }) {
    return NutritionGoals(
      userId: userId ?? this.userId,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      dailyFat: dailyFat ?? this.dailyFat,
    );
  }

  factory NutritionGoals.defaults(String userId) => NutritionGoals(
    userId: userId,
    dailyCalories: 2000,
    dailyProtein: 50,
    dailyCarbs: 250,
    dailyFat: 70,
  );

  factory NutritionGoals.fromFirestore(Map<String, dynamic> data) {
    return NutritionGoals(
      userId: data['user_id'] as String? ?? '',
      dailyCalories: (data['daily_calories'] as num?)?.toInt() ?? 2000,
      dailyProtein: (data['daily_protein'] as num?)?.toInt() ?? 50,
      dailyCarbs: (data['daily_carbs'] as num?)?.toInt() ?? 250,
      dailyFat: (data['daily_fat'] as num?)?.toInt() ?? 70,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'user_id': userId,
    'daily_calories': dailyCalories,
    'daily_protein': dailyProtein,
    'daily_carbs': dailyCarbs,
    'daily_fat': dailyFat,
    'updated_at': FieldValue.serverTimestamp(),
  };
}
```

**Step 2: Verify it compiles**
```bash
flutter analyze lib/models/models.dart
```
Expected: no issues (the file already imports `cloud_firestore` which provides `Timestamp` and `FieldValue`).

**Step 3: Commit**
```bash
git add lib/models/models.dart
git commit -m "feat(models): add MealPlan and NutritionGoals models"
```

---

## Task 2: Add FirebaseService methods

**Files:**
- Modify: `lib/services/firebase_service.dart`

Add a new section `// ==================== MEAL PLAN ====================` before the `// ==================== HEALTH CHECK ====================` section. Also add a `// ==================== NUTRITION GOALS ====================` section right after.

**Step 1: Add meal plan methods**

Insert before `// ==================== HEALTH CHECK ====================`:

```dart
  // ==================== MEAL PLAN (Firestore) ====================

  /// Fetch the current user's meal plan. Returns null if none saved yet.
  Future<MealPlan?> getMealPlan() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('meal_plans').doc(user.uid).get();
      if (!doc.exists) return null;
      return MealPlan.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('getMealPlan error: $e');
      return null;
    }
  }

  /// Save (overwrite) the user's meal plan to Firestore.
  Future<void> saveMealPlan(MealPlan plan) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('meal_plans')
        .doc(user.uid)
        .set(plan.toFirestore());
  }

  // ==================== NUTRITION GOALS (Firestore) ====================

  /// Fetch the current user's nutrition goals. Returns null if none saved.
  Future<NutritionGoals?> getNutritionGoals() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc =
          await _firestore.collection('nutrition_goals').doc(user.uid).get();
      if (!doc.exists) return null;
      return NutritionGoals.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('getNutritionGoals error: $e');
      return null;
    }
  }

  /// Save (overwrite) the user's nutrition goals to Firestore.
  Future<void> saveNutritionGoals(NutritionGoals goals) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('nutrition_goals')
        .doc(user.uid)
        .set(goals.toFirestore());
  }
```

**Step 2: Verify**
```bash
flutter analyze lib/services/firebase_service.dart
```
Expected: no issues.

**Step 3: Commit**
```bash
git add lib/services/firebase_service.dart
git commit -m "feat(service): add getMealPlan, saveMealPlan, getNutritionGoals, saveNutritionGoals"
```

---

## Task 3: Create `MealPlanProvider`

**Files:**
- Create: `lib/providers/meal_plan_provider.dart`

**Step 1: Write the provider**

```dart
import 'package:flutter/material.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/services/firebase_service.dart';

/// Manages the weekly meal plan and a local cache of assigned recipes.
class MealPlanProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  MealPlan? _mealPlan;
  // keyed by recipeId — lets the UI render names/thumbnails without extra lookups
  final Map<String, Recipe> _assignedRecipes = {};
  bool _isLoading = false;
  String? _error;

  MealPlan? get mealPlan => _mealPlan;
  Map<String, Recipe> get assignedRecipes => _assignedRecipes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MealPlanProvider() {
    loadMealPlan();
  }

  /// Fetch meal plan from Firestore. Initialises an empty plan if none exists.
  Future<void> loadMealPlan() async {
    if (_service.currentUser == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _mealPlan = await _service.getMealPlan() ??
          MealPlan.empty(_service.currentUser!.uid);
      // Rebuild _assignedRecipes cache from known recipe IDs
      // (recipes already loaded into RecipeProvider cache are also in FirebaseService cache)
      for (final entry in _mealPlan!.days.entries) {
        final id = entry.value;
        if (id != null && !_assignedRecipes.containsKey(id)) {
          final recipe = await _service.getRecipe(id);
          if (recipe != null) _assignedRecipes[id] = recipe;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Assign [recipe] to [day] (e.g. 'monday') and persist.
  Future<void> assignRecipe(String day, Recipe recipe) async {
    if (_mealPlan == null) return;
    _assignedRecipes[recipe.id] = recipe;
    _mealPlan = _mealPlan!.copyWith(
      days: {..._mealPlan!.days, day: recipe.id},
    );
    notifyListeners();
    await _service.saveMealPlan(_mealPlan!);
  }

  /// Remove the recipe from [day] and persist.
  Future<void> removeRecipe(String day) async {
    if (_mealPlan == null) return;
    _mealPlan = _mealPlan!.copyWith(
      days: {..._mealPlan!.days, day: null},
    );
    notifyListeners();
    await _service.saveMealPlan(_mealPlan!);
  }

  /// Returns grocery items for all assigned recipes (one item per ingredient).
  List<GroceryItem> generateGroceryItems() {
    final items = <GroceryItem>[];
    final seen = <String>{};
    for (final recipeId in _mealPlan?.days.values.whereType<String>() ?? []) {
      final recipe = _assignedRecipes[recipeId];
      if (recipe == null) continue;
      for (final ingredient in recipe.ingredients) {
        final key = ingredient.toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);
        items.add(GroceryItem(
          name: ingredient,
          quantity: 1.0,
          unit: '',
          category: 'meal-plan',
          checked: false,
          recipes: [recipe.name],
        ));
      }
    }
    return items;
  }
}
```

**Step 2: Verify**
```bash
flutter analyze lib/providers/meal_plan_provider.dart
```
Expected: no issues.

**Step 3: Commit**
```bash
git add lib/providers/meal_plan_provider.dart
git commit -m "feat(provider): add MealPlanProvider with load/assign/remove/generateGroceryItems"
```

---

## Task 4: Create `NutritionProvider`

**Files:**
- Create: `lib/providers/nutrition_provider.dart`

**Step 1: Write the provider**

```dart
import 'package:flutter/material.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/services/firebase_service.dart';

/// Manages the user's daily nutrition goals.
class NutritionProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  NutritionGoals? _goals;
  bool _isLoading = false;
  String? _error;

  NutritionGoals? get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NutritionProvider() {
    loadGoals();
  }

  /// Fetch goals from Firestore. Leaves _goals null if none saved yet.
  Future<void> loadGoals() async {
    if (_service.currentUser == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _goals = await _service.getNutritionGoals();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save new goals to Firestore and update local state.
  Future<void> saveGoals({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = _service.currentUser?.uid ?? '';
      final goals = NutritionGoals(
        userId: uid,
        dailyCalories: calories,
        dailyProtein: protein,
        dailyCarbs: carbs,
        dailyFat: fat,
      );
      await _service.saveNutritionGoals(goals);
      _goals = goals;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**Step 2: Verify**
```bash
flutter analyze lib/providers/nutrition_provider.dart
```
Expected: no issues.

**Step 3: Commit**
```bash
git add lib/providers/nutrition_provider.dart
git commit -m "feat(provider): add NutritionProvider with loadGoals/saveGoals"
```

---

## Task 5: Update Firestore security rules

**Files:**
- Modify: `firestore.rules`

**Step 1: Insert two new collection rules**

Insert the following **before** the `// ── Default: deny everything else` block:

```
    // ── Meal Plans ────────────────────────────────────────────────────────────
    // Each user can only read/write their own meal plan document.
    match /meal_plans/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }

    // ── Nutrition Goals ───────────────────────────────────────────────────────
    // Each user can only read/write their own nutrition goals document.
    match /nutrition_goals/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
```

**Step 2: Commit**
```bash
git add firestore.rules
git commit -m "security(firestore): add meal_plans and nutrition_goals collection rules"
```

---

## Task 6: Register providers in `main.dart`

**Files:**
- Modify: `lib/main.dart`

**Step 1: Add imports**

Add these two imports after `import 'providers/app_providers.dart';`:
```dart
import 'providers/meal_plan_provider.dart';
import 'providers/nutrition_provider.dart';
```

**Step 2: Register providers**

In the `MultiProvider` providers list, after `ChangeNotifierProvider(create: (_) => GroceryListProvider()),` add:
```dart
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
```

**Step 3: Verify**
```bash
flutter analyze lib/main.dart
```

**Step 4: Commit**
```bash
git add lib/main.dart
git commit -m "feat(main): register MealPlanProvider and NutritionProvider"
```

---

## Task 7: Add routes + new nav tab to `routes.dart`

**Files:**
- Modify: `lib/app/routes.dart`

### Step 1: Add imports at the top (after existing feature imports)

```dart
import '../features/meal_plan/meal_plan_screen.dart';
import '../features/meal_plan/recipe_picker_screen.dart';
import '../features/nutrition_goals/nutrition_goals_screen.dart';
```

### Step 2: Add `/meal-plan` to the ShellRoute routes list

Inside the `ShellRoute` `routes:` list, after the `/favorites` GoRoute, add:

```dart
        // Meal Plan
        GoRoute(
          path: '/meal-plan',
          name: 'meal-plan',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MealPlanScreen(),
          ),
        ),
```

### Step 3: Add pushed routes (outside ShellRoute, alongside `/grocery`)

After the `/grocery` GoRoute, add:

```dart
    // Recipe Picker (for meal plan day assignment)
    GoRoute(
      path: '/meal-plan/pick-recipe',
      name: 'pick-recipe',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final day = state.extra as String? ?? 'monday';
        return RecipePickerScreen(day: day);
      },
    ),

    // Nutrition Goals
    GoRoute(
      path: '/nutrition-goals',
      name: 'nutrition-goals',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NutritionGoalsScreen(),
    ),
```

### Step 4: Update `_buildBottomNavBar` to detect `/meal-plan`

Replace the `currentIndex` detection block:
```dart
    int currentIndex = 0;
    if (location.startsWith('/search')) {
      currentIndex = 1;
    } else if (location.startsWith('/favorites')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      currentIndex = 4;
    }
```
with:
```dart
    int currentIndex = 0;
    if (location.startsWith('/search')) {
      currentIndex = 1;
    } else if (location.startsWith('/favorites')) {
      currentIndex = 3;
    } else if (location.startsWith('/meal-plan')) {
      currentIndex = 4;
    } else if (location.startsWith('/profile')) {
      currentIndex = 5;
    }
```

### Step 5: Add Meal Plan nav item and shift Profile index in `_BottomNavBar.build`

In the `Row` children list, **between** the Favorites `_NavItem` and the Profile `_NavItem`, add:
```dart
              _NavItem(
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month,
                label: 'Meal Plan',
                isSelected: currentIndex == 4,
                onTap: () => context.go('/meal-plan'),
              ),
```

Also update the Profile `_NavItem` `isSelected` from `currentIndex == 4` → `currentIndex == 5`.

### Step 6: Verify
```bash
flutter analyze lib/app/routes.dart
```
Expected: errors about missing screen files — that's fine, they'll be created in Tasks 8–10.

### Step 7: Commit (after screens created in tasks 8–10 — commit together)
> Hold this commit until Tasks 8–10 are done to avoid broken state.

---

## Task 8: Create `NutritionGoalsScreen`

**Files:**
- Create: `lib/features/nutrition_goals/nutrition_goals_screen.dart`

**Step 1: Write the screen**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/nutrition_provider.dart';

class NutritionGoalsScreen extends StatefulWidget {
  const NutritionGoalsScreen({super.key});

  @override
  State<NutritionGoalsScreen> createState() => _NutritionGoalsScreenState();
}

class _NutritionGoalsScreenState extends State<NutritionGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  bool _initialised = false;

  @override
  void dispose() {
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  void _initControllers(NutritionProvider provider) {
    if (_initialised) return;
    final g = provider.goals;
    _caloriesCtrl = TextEditingController(text: '${g?.dailyCalories ?? 2000}');
    _proteinCtrl  = TextEditingController(text: '${g?.dailyProtein  ?? 50}');
    _carbsCtrl    = TextEditingController(text: '${g?.dailyCarbs    ?? 250}');
    _fatCtrl      = TextEditingController(text: '${g?.dailyFat      ?? 70}');
    _initialised = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<NutritionProvider>();
    await provider.saveGoals(
      calories: int.parse(_caloriesCtrl.text.trim()),
      protein:  int.parse(_proteinCtrl.text.trim()),
      carbs:    int.parse(_carbsCtrl.text.trim()),
      fat:      int.parse(_fatCtrl.text.trim()),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goals saved!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !_initialised) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        _initControllers(provider);
        return Scaffold(
          appBar: const SmartChefAppBar(title: 'Nutrition Goals'),
          body: SingleChildScrollView(
            padding: AppSpacing.paddingMd,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set your daily nutrition targets.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap.lg(),
                  _GoalField(
                    controller: _caloriesCtrl,
                    label: 'Daily Calories',
                    unit: 'kcal',
                    icon: Icons.local_fire_department,
                    color: AppColors.primaryOrange,
                  ),
                  const Gap.md(),
                  _GoalField(
                    controller: _proteinCtrl,
                    label: 'Daily Protein',
                    unit: 'g',
                    icon: Icons.fitness_center,
                    color: AppColors.accentGreen,
                  ),
                  const Gap.md(),
                  _GoalField(
                    controller: _carbsCtrl,
                    label: 'Daily Carbs',
                    unit: 'g',
                    icon: Icons.grain,
                    color: AppColors.accentYellow,
                  ),
                  const Gap.md(),
                  _GoalField(
                    controller: _fatCtrl,
                    label: 'Daily Fat',
                    unit: 'g',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                  ),
                  const Gap.xl(),
                  GradientButton(
                    text: 'Save Goals',
                    icon: Icons.check_rounded,
                    onPressed: provider.isLoading ? null : _save,
                  ),
                  const Gap.lg(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final Color color;

  const _GoalField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '$label ($unit)',
        prefixIcon: Icon(icon, color: color),
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        final n = int.tryParse(v.trim());
        if (n == null || n <= 0) return 'Enter a positive number';
        return null;
      },
    );
  }
}
```

**Step 2: Verify**
```bash
flutter analyze lib/features/nutrition_goals/nutrition_goals_screen.dart
```

---

## Task 9: Create `RecipePickerScreen`

**Files:**
- Create: `lib/features/meal_plan/recipe_picker_screen.dart`

**Step 1: Write the screen**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/meal_plan_provider.dart';
import '../../shared/widgets/widgets.dart';

class RecipePickerScreen extends StatefulWidget {
  final String day;

  const RecipePickerScreen({super.key, required this.day});

  @override
  State<RecipePickerScreen> createState() => _RecipePickerScreenState();
}

class _RecipePickerScreenState extends State<RecipePickerScreen> {
  String _query = '';

  String get _displayDay =>
      widget.day[0].toUpperCase() + widget.day.substring(1);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pick a Recipe for $_displayDay'),
        backgroundColor: colorScheme.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.paddingMd,
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search recipes…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, recipeProvider, _) {
                final recipes = recipeProvider.recipes.where((r) {
                  if (_query.isEmpty) return true;
                  return r.name.toLowerCase().contains(_query) ||
                      r.cuisine.toLowerCase().contains(_query);
                }).toList();

                if (recipes.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: 'No recipes found',
                    subtitle: _query.isEmpty
                        ? 'Load recipes from home first'
                        : 'Try a different search term',
                  );
                }

                return ListView.builder(
                  padding: AppSpacing.paddingMd,
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(AppSpacing.sm),
                        leading: ClipRRect(
                          borderRadius: AppSpacing.borderRadiusSm,
                          child: recipe.imageUrl.isNotEmpty
                              ? Image.network(
                                  recipe.imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 56,
                                    height: 56,
                                    color: colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.restaurant),
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.restaurant),
                                ),
                        ),
                        title: Text(
                          recipe.name,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${recipe.cuisine.isNotEmpty ? recipe.cuisine + ' • ' : ''}'
                          '${recipe.prepTime + recipe.cookTime} min',
                          style: textTheme.bodySmall,
                        ),
                        onTap: () async {
                          await context
                              .read<MealPlanProvider>()
                              .assignRecipe(widget.day, recipe);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Verify**
```bash
flutter analyze lib/features/meal_plan/recipe_picker_screen.dart
```

---

## Task 10: Create `MealPlanScreen`

**Files:**
- Create: `lib/features/meal_plan/meal_plan_screen.dart`

**Step 1: Write the screen**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/meal_plan_provider.dart';
import '../../shared/widgets/widgets.dart';

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  static const List<String> _dayNames = MealPlan.dayNames;

  // Returns the date for a given weekday offset from weekStart.
  String _dayLabel(DateTime weekStart, int offset) {
    final date = weekStart.add(Duration(days: offset));
    return '${date.day}/${date.month}';
  }

  Future<void> _onGenerateGroceryList(
    BuildContext context,
    MealPlanProvider planProvider,
    GroceryListProvider groceryProvider,
  ) async {
    final items = planProvider.generateGroceryItems();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recipes assigned yet.')),
      );
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Grocery List'),
        content: Text(
          'Found ${items.length} unique ingredients from your meal plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'add'),
            child: const Text('Add to List'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'replace'),
            child: const Text('Replace List'),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel' || !context.mounted) return;

    if (choice == 'replace') {
      groceryProvider.clearCheckedItems();
      // Also remove unchecked items by rebuilding from scratch
      for (final item in List.of(groceryProvider.items)) {
        groceryProvider.removeItem(item.name);
      }
    }

    for (final item in items) {
      groceryProvider.addItem(item);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${items.length} items added to grocery list.'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => context.go('/grocery'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MealPlanProvider, GroceryListProvider>(
      builder: (context, planProvider, groceryProvider, _) {
        final plan = planProvider.mealPlan;

        return Scaffold(
          appBar: SmartChefAppBar(
            title: 'Meal Plan',
            actions: [
              IconButton(
                tooltip: 'Generate Grocery List',
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => _onGenerateGroceryList(
                  context,
                  planProvider,
                  groceryProvider,
                ),
              ),
            ],
          ),
          body: planProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : plan == null
                  ? const EmptyState(
                      icon: Icons.calendar_month,
                      title: 'No meal plan yet',
                      subtitle: 'Add recipes to your week to get started',
                    )
                  : ListView.builder(
                      padding: AppSpacing.paddingMd,
                      itemCount: _dayNames.length,
                      itemBuilder: (context, index) {
                        final day = _dayNames[index];
                        final recipeId = plan.days[day];
                        final recipe = recipeId != null
                            ? planProvider.assignedRecipes[recipeId]
                            : null;
                        return _DayCard(
                          day: day,
                          dateLabel: _dayLabel(plan.weekStart, index),
                          recipe: recipe,
                          onAdd: () => context.push(
                            '/meal-plan/pick-recipe',
                            extra: day,
                          ),
                          onRemove: () => planProvider.removeRecipe(day),
                        );
                      },
                    ),
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  final String day;
  final String dateLabel;
  final Recipe? recipe;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _DayCard({
    required this.day,
    required this.dateLabel,
    required this.recipe,
    required this.onAdd,
    required this.onRemove,
  });

  String get _displayDay => day[0].toUpperCase() + day.substring(1);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            // Day label
            SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayDay,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const HGap.md(),
            // Recipe or empty slot
            Expanded(
              child: recipe != null
                  ? _AssignedRecipeTile(
                      recipe: recipe!,
                      onRemove: onRemove,
                    )
                  : _EmptySlot(onAdd: onAdd),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedRecipeTile extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onRemove;

  const _AssignedRecipeTile({required this.recipe, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusSm,
          child: recipe.imageUrl.isNotEmpty
              ? Image.network(
                  recipe.imageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    color: colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.restaurant, size: 24),
                  ),
                )
              : Container(
                  width: 52,
                  height: 52,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.restaurant, size: 24),
                ),
        ),
        const HGap.sm(),
        Expanded(
          child: Text(
            recipe.name,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: colorScheme.error, size: 20),
          onPressed: onRemove,
          tooltip: 'Remove',
        ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptySlot({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outlineVariant,
            style: BorderStyle.solid,
            width: 1.5,
          ),
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18, color: colorScheme.primary),
              const HGap.xs(),
              Text(
                'Add Recipe',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Verify + commit everything from Tasks 7–10 together**
```bash
flutter analyze
```
Expected: No issues found.

```bash
git add lib/app/routes.dart lib/features/meal_plan/ lib/features/nutrition_goals/
git commit -m "feat: add MealPlanScreen, RecipePickerScreen, NutritionGoalsScreen + routes + nav tab"
```

---

## Task 11: Wire Nutrition Goals tile in profile screen + update ROADMAP

**Files:**
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `ROADMAP.md`

**Step 1: Wire the tile**

In `profile_screen.dart`, find the Nutrition Goals `SettingsTile`:
```dart
              SettingsTile(
                icon: Icons.calculate,
                title: 'Nutrition Goals',
                subtitle: 'Daily calorie targets',
                onTap: () {},
              ),
```
Change `onTap: () {}` to `onTap: () => context.push('/nutrition-goals')`.

**Step 2: Update ROADMAP.md**

Mark 2.3 and 2.5 as done:
- `### 2.3 Meal Planning Calendar` → add ` ✅ Done` to the heading, tick the checkboxes
- `### 2.5 Nutrition Goal Tracking` → add ` ✅ Done` to the heading, tick the checkboxes

**Step 3: Final verify + commit**
```bash
flutter analyze
```
Expected: No issues found.

```bash
git add lib/features/profile/profile_screen.dart ROADMAP.md
git commit -m "feat: wire Nutrition Goals profile tile + mark 2.3/2.5 done in ROADMAP"
```

---

## Done ✓

After all tasks are committed, the app has:
- **Meal Plan screen** reachable from the bottom nav (calendar icon, slot 4)
- **Recipe Picker** as a full push screen, showing all loaded recipes with search
- **7-day card list** with assign / remove per day
- **Generate Grocery List** button with replace-or-add dialog
- **Nutrition Goals screen** reachable from profile → Nutrition Goals tile
- Both backed by Firestore with proper security rules
