# SmartChef AI - Architecture

> Technical reference for the Firebase + Flutter architecture.
> Covers data flow, state management, navigation, caching, and platform specifics.

---

## System Overview

```
┌──────────────────────────────────────────────────┐
│                  Flutter App                     │
│                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  │
│  │  Screens   │  │ Providers  │  │  Widgets   │  │
│  │ (features/)│  │(ChangeNoti-│  │ (shared/   │  │
│  │            │◄─┤ fier)      │  │ widgets/)  │  │
│  └─────┬──────┘  └─────┬──────┘  └────────────┘  │
│        │               │                          │
│        └───────┬────────┘                         │
│                ▼                                  │
│        ┌──────────────┐                           │
│        │FirebaseService│ (Singleton)              │
│        │  + local cache│                          │
│        └──────┬───────┘                           │
└───────────────┼──────────────────────────────────┘
                │
     ┌──────────┴──────────┐
     ▼                     ▼
┌─────────────┐    ┌───────────────┐
│  Firebase   │    │  TheMealDB    │
│  ─ Firestore│    │  REST API     │
│  ─ Auth     │    │  (fallback)   │
│  ─ Storage  │    └───────────────┘
└─────────────┘
```

---

## Data Flow

### Recipe Loading

```
UI (HomeScreen)
  → context.read<RecipeProvider>().loadRecipes()
    → FirebaseService().getAllRecipes()
      → Check in-memory cache (30-min expiry)
        → [Cache valid] Return _cachedRecipes
        → [Cache stale] Query Firestore recipes/ collection
          → [Firestore empty] Seed from TheMealDB API + data/recipes.json
          → Store results in _cachedRecipes + update _cacheTimestamp
    → RecipeProvider._recipes = result
    → notifyListeners()
  → Consumer<RecipeProvider> rebuilds with new recipes
```

### Favorites Toggle

```
UI (RecipeCard heart button)
  → context.read<RecipeProvider>().toggleFavorite(recipeId)
    → [Optimistic update] _favoriteIds.add/remove locally
    → notifyListeners()  ← UI updates immediately
    → FirebaseService().addFavorite(recipeId) or removeFavorite(recipeId)
      → Firestore: users/{uid}/favorite_recipes array update
```

### Authentication Flow

```
App Launch
  → main.dart: Firebase.initializeApp()
  → GoRouter redirect checks FirebaseService().isSignedIn
    → [Not signed in] Redirect to /get-started
    → [Signed in] Allow navigation to /

GetStartedScreen
  → [Sign Up] → /signup → SignupScreen
  → [Sign In] → /login → LoginScreen
  → [Guest]  → UserProvider.signInAsGuest() → / (local only, no Firebase)

LoginScreen / SignupScreen
  → FirebaseService().signInWithEmailAndPassword() or createUserWithEmailAndPassword()
  → On success: GoRouter redirect re-evaluates → navigates to /onboarding or /
```

---

## Navigation Architecture

### Route Structure

```
GoRouter
├── /get-started          (GetStartedScreen - no shell)
├── /login                (LoginScreen - no shell)
├── /signup               (SignupScreen - no shell)
├── /forgot-password      (ForgotPasswordScreen - no shell)
├── /onboarding           (OnboardingScreen - no shell)
├── /scan                 (ScanScreen - no shell, full-screen camera)
├── /recipe/:id           (RecipeDetailScreen - no shell, extra: Recipe)
├── /dietary-preferences  (DietaryPreferencesScreen - no shell)
└── ShellRoute (MainShell with BottomNav)
    ├── /          (HomeScreen)
    ├── /search    (SearchScreen)
    ├── /favorites (FavoritesScreen)
    ├── /grocery   (GroceryListScreen)  ← Phase 0: move here from standalone
    └── /profile   (ProfileScreen)
```

### Navigation Rules

**Always use GoRouter. Never use Navigator directly.**

```dart
// ✅ Navigate to a tab (replaces current stack)
context.go('/search');

// ✅ Push a detail screen (keeps back button)
context.push('/recipe/${recipe.id}', extra: recipe);

// ✅ Replace (e.g., after login)
context.go('/');

// ❌ Never use these - bypasses GoRouter shell and auth guard
Navigator.pushNamed(context, '/path');
Navigator.push(context, MaterialPageRoute(...));
```

### Auth Guard

Defined in `lib/app/routes.dart` via GoRouter `redirect`:

```dart
redirect: (context, state) {
  final isSignedIn = FirebaseService().isSignedIn;
  final isAuthRoute = ['/login', '/signup', '/get-started', ...].contains(state.fullPath);

  if (!isSignedIn && !isAuthRoute) return '/get-started';
  if (isSignedIn && isAuthRoute) return '/';
  return null; // no redirect
}
```

---

## State Management

### Three Providers

Registered in `main.dart` via `MultiProvider`:

| Provider | Responsibility |
|----------|---------------|
| `RecipeProvider` | Recipe list, search results, favorites, loading state |
| `UserProvider` | Auth state, user profile, theme preference |
| `GroceryListProvider` | Grocery items, local + Firebase sync |

### Provider Pattern

All providers extend `ChangeNotifier`. Pattern:

```dart
class RecipeProvider extends ChangeNotifier {
  // Private state
  List<Recipe> _recipes = [];
  bool _isLoading = false;

  // Public getters (read-only)
  List<Recipe> get recipes => List.unmodifiable(_recipes);
  bool get isLoading => _isLoading;

  // Actions that mutate state
  Future<void> loadRecipes() async {
    _isLoading = true;
    notifyListeners();

    _recipes = await _firebaseService.getAllRecipes();
    _isLoading = false;
    notifyListeners();
  }
}
```

### Consuming State in UI

```dart
// Reading (no rebuild)
final recipes = context.read<RecipeProvider>().recipes;

// Watching (rebuilds on change)
final recipes = context.watch<RecipeProvider>().recipes;

// Selecting (rebuilds only when specific value changes)
final isLoading = context.select<RecipeProvider, bool>((p) => p.isLoading);

// In build method via Consumer (fine-grained rebuild)
Consumer<RecipeProvider>(
  builder: (context, provider, child) => Text('${provider.recipes.length} recipes'),
)
```

### Immutable State Updates

All state mutations use `copyWith` - never direct field mutation:

```dart
// ✅ Correct - creates new object
_items[index] = _items[index].copyWith(checked: !_items[index].checked);
notifyListeners();

// ❌ Wrong - Flutter won't detect this change
_items[index].checked = !_items[index].checked;
```

---

## Service Layer

### FirebaseService (Singleton)

Location: `lib/services/firebase_service.dart`

```
FirebaseService
├── Firebase instances
│   ├── FirebaseFirestore _firestore
│   └── FirebaseAuth _auth
├── In-memory cache
│   ├── List<Recipe> _cachedRecipes
│   └── DateTime? _cacheTimestamp (30-min expiry)
├── Recipe operations
│   ├── getAllRecipes({bool forceRefresh})
│   ├── getRecipe(String id)
│   ├── searchRecipes(String query)
│   └── searchByIngredients(List<String> ingredients)
├── User operations
│   ├── signInWithEmailAndPassword(email, password)
│   ├── createUserWithEmailAndPassword(email, password)
│   ├── signInWithGoogle()
│   ├── signInAnonymously()
│   ├── signOut()
│   ├── sendPasswordResetEmail(email)
│   ├── getUserProfile()
│   └── createUserProfile(...)
├── Favorites
│   ├── getFavoriteIds()
│   ├── addFavorite(recipeId)
│   └── removeFavorite(recipeId)
└── Grocery lists
    ├── createGroceryList(...)
    └── getGroceryLists()
```

### Retry Strategy

`FirebaseService` includes exponential backoff for Firestore reads:

```dart
Future<T> _withRetry<T>(Future<T> Function() operation) async {
  int attempts = 0;
  while (attempts < 3) {
    try {
      return await operation();
    } catch (e) {
      attempts++;
      await Future.delayed(Duration(seconds: 2 * attempts));
    }
  }
  throw Exception('Max retries exceeded');
}
```

### TheMealDB Fallback

When Firestore `recipes/` collection is empty, `FirebaseService` seeds it:
1. Fetches categories from `https://www.themealdb.com/api/json/v1/1/categories.php`
2. Fetches meals per category
3. Writes results to Firestore as `Recipe` documents
4. Also seeds from `data/recipes.json` (19 local recipes)

---

## Caching Strategy

Three layers:

| Layer | Mechanism | Scope | Duration |
|-------|-----------|-------|----------|
| In-memory | `_cachedRecipes` list in FirebaseService | Current session | 30 minutes |
| Firestore offline | `FirebaseFirestore.instance.settings.persistenceEnabled = true` | Between sessions | Indefinite |
| App preferences | `SharedPreferences` | Between sessions | Indefinite |

SharedPreferences keys:
- `onboarding_completed` → `bool` - whether to show onboarding on launch
- `theme_mode` → `string` - `'light'` / `'dark'` / `'system'`

---

## Models

Location: `lib/models/models.dart`

All models use:
- `const` constructors for compile-time safety
- Named required parameters
- `copyWith()` method for immutable updates
- `fromMap()` / `toMap()` for Firestore serialization

| Model | Key Fields | Firestore Collection |
|-------|-----------|---------------------|
| `Recipe` | id, name, ingredients, steps, cuisine, nutrition, imageUrl | `recipes/` |
| `Nutrition` | calories, protein, carbs, fat, fiber | Nested in Recipe |
| `AppUser` | uid, name, email, dietaryPreferences, allergies, favoriteRecipes | `users/` |
| `GroceryList` | id, userId, name, items, status | `grocery_lists/` |
| `GroceryItem` | id, name, quantity, unit, checked, category | Nested in GroceryList |
| `DetectedIngredient` | name, confidence, boundingBox | In-memory only |

> **Note**: `AppUser` is currently defined inside `firebase_service.dart`. It should be moved to `models/models.dart` (tracked in BUGS.md cleanup items).

---

## Theme System

### Files

```
lib/app/theme/
├── theme.dart           # Barrel export
├── app_colors.dart      # Color constants
├── app_typography.dart  # TextStyle definitions (uses Poppins - see BUG-008)
├── app_spacing.dart     # Spacing constants (xxs=4 through xxxl=64)
└── app_theme.dart       # ThemeData (light + dark)
```

### Key Rules

```dart
// ✅ Use withValues() for opacity - withOpacity() is deprecated in Flutter 3.x
Colors.black.withValues(alpha: 0.1)

// ✅ Use AppSpacing constants instead of raw numbers
SizedBox(height: AppSpacing.md)  // 16.0

// ✅ Use AppColors constants
color: AppColors.primaryOrange  // Color(0xFFFF6B35)
```

### Spacing Constants

| Name | Value | Use |
|------|-------|-----|
| `xxs` | 4 | Micro gaps |
| `xs` | 8 | Small padding |
| `sm` | 12 | Component padding |
| `md` | 16 | Standard section spacing |
| `lg` | 24 | Large gaps |
| `xl` | 32 | Section dividers |
| `xxl` | 48 | Page padding |
| `xxxl` | 64 | Hero spacing |

---

## Firebase Configuration

### Project

- **Project ID**: `smartchefai-344c5`
- **Configured for**: Android, Web
- **Not configured**: iOS, macOS, Windows (placeholder values in `firebase_options.dart`)

### Platform Files

| Platform | Config File | Status |
|----------|------------|--------|
| Android | `android/app/google-services.json` | Real credentials |
| Web | `lib/firebase_options.dart` (web section) | Real credentials |
| iOS | `lib/firebase_options.dart` (ios section) | Placeholder - not configured |
| macOS | `lib/firebase_options.dart` (macos section) | Placeholder - not configured |

### Firestore Security Rules

> No `firestore.rules` file exists locally. Must be created before any production use.

Recommended rules pattern:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Recipes - readable by all authenticated users
    match /recipes/{recipeId} {
      allow read: if request.auth != null;
      allow write: if false; // only via admin/seeding
    }

    // Users - only accessible by the user themselves
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Grocery lists - only accessible by the owning user
    match /grocery_lists/{listId} {
      allow read, write: if request.auth != null && resource.data.user_id == request.auth.uid;
    }
  }
}
```

---

## File Organization Rules

### Feature-First Structure

New screens go in `lib/features/{feature_name}/{feature_name}_screen.dart`.

Do NOT create top-level screen files - always under `features/`.

### Shared Widgets

Reusable widgets go in `lib/shared/widgets/`. Add to `widgets.dart` barrel export.

Do NOT add to `lib/widgets/custom_widgets.dart` - that file is dead code scheduled for deletion.

### Barrel Exports

Each major directory has a barrel:
- `lib/shared/widgets/widgets.dart` - all shared widgets
- `lib/models/models.dart` - all model classes
- `lib/providers/app_providers.dart` - re-exports `firebase_providers.dart`

---

## Platform-Specific Notes

### Android

- Min SDK: 21 (set in `android/app/build.gradle`)
- Package: `com.example.smartchefai` (needs rename before release - see ROADMAP Phase 3)
- Permissions needed: `CAMERA`, `READ_EXTERNAL_STORAGE`, `RECORD_AUDIO` (for voice search)
- Google Sign-In: OAuth client configured in `google-services.json`

### Web

- Firebase configured for web in `firebase_options.dart`
- `image_picker` has limited web support (gallery only, no camera on all browsers)
- `speech_to_text` works on Chrome/Edge on web
- Deep links work via standard URL routing through GoRouter

---

*Last updated: 2026-02-19 | Project: SmartChef AI v0.1.0*
