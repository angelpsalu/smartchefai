# SmartChef AI — Architecture

> Technical reference for the Firebase + Flutter architecture.
> Covers data flow, state management, navigation, caching, and platform specifics.
> Last updated: 2026-02-20

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
UI (HomeScreen.initState)
  → context.read<RecipeProvider>().loadRecipes()
    → FirebaseService().getAllRecipes()
      → Check in-memory cache (_cachedRecipes, 30-min expiry)
        → [Cache valid] Return _cachedRecipes immediately
        → [Cache stale] Query Firestore recipes/ collection
          → [Firestore has data] Return documents as List<Recipe>
          → [Firestore empty]   Seed from TheMealDB API + data/recipes.json
                                Write seeded recipes to Firestore for next time
          → Update _cachedRecipes + _cacheTimestamp
    → RecipeProvider._recipes = result
    → notifyListeners()
  → Consumer<RecipeProvider> rebuilds with new recipe list
```

### Favorites Toggle (Optimistic Update)

```
UI (RecipeCard heart button)
  → context.read<RecipeProvider>().toggleFavorite(recipeId)
    → [Optimistic] _favoriteIds.add/remove locally
    → notifyListeners()          ← UI updates immediately, no waiting
    → Persist to SharedPreferences (offline support)
    → FirebaseService().addFavorite / removeFavorite
        → Firestore: users/{uid}/favorite_recipes array update
```

### Authentication Flow

```
App Launch
  → main.dart: Firebase.initializeApp()
  → main.dart: SharedPreferences check onboarding_complete
  → GoRouter redirect: FirebaseService().isSignedIn (sync bool)
    → [Not signed in] Route to /get-started
    → [Signed in]     Allow route to /

GetStartedScreen
  → [Sign Up] → /signup → SignupScreen
  → [Sign In] → /login  → LoginScreen
  (Guest mode has been removed entirely)

LoginScreen / SignupScreen
  → UserProvider.signInWithEmail() or signUpWithEmail()
      → FirebaseService().signInWithEmail() or registerWithEmail()
      → On success: UserProvider._appUser set, notifyListeners()
  → profile_screen.dart _handleSignOut():
      → context.pop()               — dismiss dialog
      → await userProvider.logout() — Firebase signOut, clear _appUser
      → if (!mounted) return
      → context.go('/get-started')  — explicit navigation (GoRouter redirect
                                       is sync, won't auto-fire on state change)
```

---

## Navigation Architecture

### Route Structure

```
GoRouter (lib/app/routes.dart)
├── /get-started          (GetStartedScreen — no shell, auth only)
├── /login                (LoginScreen — no shell)
├── /signup               (SignupScreen — no shell)
├── /forgot-password      (ForgotPasswordScreen — no shell)
├── /onboarding           (OnboardingScreen — no shell, shown once)
├── /scan                 (ScanScreen — no shell, full-screen camera)
├── /grocery              (GroceryListScreen — no shell, full-screen)
├── /dietary-preferences  (DietaryPreferencesScreen — no shell)
├── /recipe/:id           (RecipeDetailScreen — no shell; Recipe via extra:)
├── /voice-search         (SearchScreen alias — no shell)
└── ShellRoute (ScaffoldWithNavBar)
    ├── /          (HomeScreen)
    ├── /search    (SearchScreen)
    ├── /favorites (FavoritesScreen)
    └── /profile   (ProfileScreen)
```

The bottom navigation bar has 5 positions: Home (0), Search (1), Camera button (2), Favorites (3), Profile (4). The camera button at index 2 is a special push-button (`context.push('/scan')`), not a nav destination, so positions 3 and 4 are used for Favorites and Profile indices.

### Auth Guard

```dart
// lib/app/routes.dart
redirect: (context, state) {
  final isSignedIn = FirebaseService().isSignedIn;  // sync bool
  final isAuthRoute = state.uri.path.startsWith('/get-started') || ...;

  if (!isSignedIn && !isAuthRoute) return '/get-started';
  if (isSignedIn && isAuthRoute) return '/';
  return null;
}
```

**Limitation**: The redirect is synchronous. It does not subscribe to `authStateChanges`. If a Firebase token expires mid-session, the user won't be redirected until the next navigation event. Post-logout navigation must be triggered explicitly (as in `_handleSignOut`).

### Navigation Rules

```dart
// ✅ Navigate to a tab (replaces current stack)
context.go('/search');

// ✅ Push a detail screen (back button works)
context.push('/recipe/${recipe.id}', extra: recipe);

// ✅ Pass data to routes — always use extra:, not arguments:
context.push('/recipe/${recipe.id}', extra: recipe);
// Receive in route: final recipe = state.extra as Recipe?;

// ❌ Never — bypasses ShellRoute and auth guard
Navigator.pushNamed(context, '/path');
Navigator.push(context, MaterialPageRoute(...));
```

---

## State Management

### Three Providers

Registered in `main.dart` via `MultiProvider`. All extend `ChangeNotifier`.

| Provider | File | Responsibility |
|----------|------|---------------|
| `RecipeProvider` | `firebase_providers.dart` | Recipe list, search results, favorites, loading/error state |
| `UserProvider` | `firebase_providers.dart` | Auth state, `AppUser` profile, dark mode preference, recent searches |
| `GroceryListProvider` | `firebase_providers.dart` | Grocery items (local + Firebase), cloud save/load |

### Consuming Providers

```dart
// Reading (no rebuild — use in callbacks/initState)
context.read<RecipeProvider>().loadRecipes();

// Watching (rebuilds when anything changes)
final recipes = context.watch<RecipeProvider>().recipes;

// Selecting (rebuilds only when specific field changes)
final isLoading = context.select<RecipeProvider, bool>((p) => p.isLoading);

// In build tree — fine-grained rebuild scope
Consumer<RecipeProvider>(
  builder: (context, provider, child) => Text('${provider.recipes.length}'),
)
```

### Immutable State Updates

```dart
// ✅ Use copyWith — creates a new object, triggers Provider rebuild
_items[index] = _items[index].copyWith(checked: true);
notifyListeners();

// ❌ Direct mutation — Provider will NOT detect this change
_items[index].checked = true;
```

---

## Service Layer

### FirebaseService (Singleton)

Location: `lib/services/firebase_service.dart`

Single instance created via factory constructor — `FirebaseService()` always returns the same object. Must call `initialize()` before use (called in `main.dart`).

```
FirebaseService
├── Auth
│   ├── signInWithEmail(email, password)
│   ├── registerWithEmail(email, password, name)
│   ├── signInWithGoogle()
│   ├── signOut()
│   ├── sendPasswordResetEmail(email)
│   ├── isSignedIn                      → bool (sync)
│   ├── currentUser                     → firebase_auth.User?
│   └── authStateChanges                → Stream<User?>
├── User Profile (Firestore users/)
│   ├── getUserProfile()                → AppUser?
│   ├── createUserProfile(name, email)
│   └── updatePreferences(...)
├── Recipes (Firestore recipes/ + TheMealDB fallback)
│   ├── getAllRecipes()                 → List<Recipe> (cached)
│   ├── getRecipe(id)                  → Recipe?
│   ├── searchRecipes(query)           → List<Recipe>
│   └── searchByIngredients(list)      → List<Recipe>
├── Favorites (Firestore users/{uid})
│   ├── getFavoriteIds()               → List<String>
│   ├── addFavorite(recipeId)
│   └── removeFavorite(recipeId)
├── Grocery Lists (Firestore grocery_lists/)
│   ├── createGroceryList(name, items) → String (listId)
│   ├── getGroceryList(listId)         → GroceryList?
│   ├── getGroceryLists()              → List<GroceryList>
│   ├── toggleGroceryItem(listId, name)
│   └── deleteGroceryList(listId)
└── Search History (Firestore users/{uid}/search_history)
    ├── getSearchHistory()             → List<Map>
    └── addSearchHistory(query)
```

### Network Resilience

HTTP calls via `Dio` with a retry interceptor (not a generic `_withRetry` wrapper). The `Dio` interceptor retries requests that fail with `connectionTimeout`, `receiveTimeout`, or `connectionError` — up to 3 times with 500ms/1s/1.5s delays.

### TheMealDB Fallback

When `getAllRecipes()` finds Firestore empty:
1. Loads `data/recipes.json` (19 bundled recipes)
2. Fetches categories from `https://www.themealdb.com/api/json/v1/1/categories.php`
3. Fetches meal lists per category
4. Writes all results to Firestore `recipes/` collection for future use

Images use TheMealDB's CDN URLs (`strMealThumb`).

---

## Caching Strategy

Three independent layers:

| Layer | Mechanism | Scope | Duration |
|-------|-----------|-------|----------|
| In-memory | `_cachedRecipes` + `_cacheTimestamp` in `FirebaseService` | Current process only | 30 minutes |
| Firestore offline | `persistenceEnabled: true` (set in `initialize()`) | Between sessions | Until cache evicted |
| SharedPreferences | Key-value via `shared_preferences` package | Between sessions | Persistent |

**SharedPreferences keys used:**

| Key | Type | Purpose |
|-----|------|---------|
| `onboarding_complete` | bool | Show onboarding on first launch only |
| `dark_mode` | bool | Dark mode user preference |
| `favorite_ids` | List\<String\> | Offline-first favorites cache |
| `grocery_items` | List\<String\> | Local grocery items (pipe-delimited: `name|qty|unit|category|checked`) |

---

## Models

Location: `lib/models/models.dart`

All models use immutable patterns:
- `const` constructors (where fields allow)
- All required parameters are named
- `copyWith()` for state updates
- `fromJson()` / `toJson()` for Firestore + TheMealDB serialization

| Model | Key Fields | Notes |
|-------|-----------|-------|
| `Recipe` | id, name, ingredients[], steps[], prepTime, cookTime, difficulty, cuisine, dietaryTags[], nutrition, imageUrl | `prepTime`/`cookTime` are `String` — use `prepTimeInt`/`cookTimeInt` getters for arithmetic (see BUG-004) |
| `Nutrition` | calories (int), protein, carbs, fat, fiber | Strings like `"25g"` for macro fields |
| `AppUser` | id, name, email, dietaryPreferences[], allergies[], favoriteRecipes[], searchHistory[] | Firebase UID as `id` |
| `User` | Same as AppUser | Legacy wrapper — `UserProvider.currentUser` returns this for compatibility; can be removed |
| `GroceryList` | id, userId, name, items[], byCategory{}, status | `byCategory` computed from items on deserialization |
| `GroceryItem` | name, quantity (double), unit, category, checked | Immutable via `copyWith(checked:)` |
| `DetectedIngredient` | name, confidence (double), bbox | In-memory only; not persisted |
| `BoundingBox` | x1, y1, x2, y2 | Nested in `DetectedIngredient` |
| `SearchHistory` | query, timestamp | Returned by `getSearchHistory()`; not a first-class model |

---

## Theme System

```
lib/app/theme/
├── theme.dart           # Barrel export (import this in screens)
├── app_colors.dart      # Color constants (AppColors)
├── app_typography.dart  # TextTheme via GoogleFonts.poppinsTextTheme()
├── app_spacing.dart     # Spacing constants (AppSpacing) + BorderRadius helpers
└── app_theme.dart       # ThemeData light + dark (uses Material 3)
```

**Font**: Poppins via `google_fonts` package (`GoogleFonts.poppinsTextTheme()`). Downloaded at runtime; no font files in `assets/fonts/`. No bundled font declaration needed in `pubspec.yaml`.

**Spacing scale** (`AppSpacing.*`):

| Constant | dp | Use |
|----------|----|-----|
| `xxs` | 4 | Micro gaps |
| `xs` | 8 | Tight padding |
| `sm` | 12 | Component padding |
| `md` | 16 | Standard padding (most common) |
| `lg` | 24 | Section spacing |
| `xl` | 32 | Large section dividers |
| `xxl` | 48 | Page-level padding |
| `xxxl` | 64 | Hero/splash spacing |

**Key rules:**
```dart
// ✅ withValues() — withOpacity() is deprecated in Flutter 3.x
Colors.black.withValues(alpha: 0.1)

// ✅ Spacing constants
SizedBox(height: AppSpacing.md)

// ✅ Color constants
AppColors.primaryOrange   // Color(0xFFFF6B35)
AppColors.accentGreen
AppColors.accentYellow
```

---

## Firebase Configuration

### Project Details

- **Project ID**: `smartchefai-344c5`
- **Configured for**: Android (real), Web (real)
- **Not configured**: iOS, macOS, Windows (placeholder values only)

### Platform Config Files

| Platform | File | Status |
|----------|------|--------|
| Android | `android/app/google-services.json` | Real credentials |
| Web | `lib/firebase_options.dart` (web section) | Real credentials |
| iOS | `lib/firebase_options.dart` (ios section) | Placeholder — DO NOT use |
| macOS | `lib/firebase_options.dart` (macos section) | Placeholder — DO NOT use |

### Firestore Security Rules

No `firestore.rules` file exists locally. Must be created before production. Recommended pattern:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /recipes/{recipeId} {
      allow read: if request.auth != null;
      allow write: if false;  // admin/seeding only
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /grocery_lists/{listId} {
      allow read, write: if request.auth != null
                         && resource.data.user_id == request.auth.uid;
    }
  }
}
```

---

## File Organization

### Project Structure

```
lib/
├── main.dart                     # App entry, Firebase init, MultiProvider setup
├── firebase_options.dart         # Firebase SDK config (Android + Web real; iOS placeholder)
├── app/
│   ├── routes.dart               # GoRouter: ShellRoute + auth redirect
│   └── theme/
│       ├── theme.dart            # Barrel export
│       ├── app_colors.dart       # AppColors constants
│       ├── app_typography.dart   # AppTypography (Poppins via google_fonts)
│       ├── app_spacing.dart      # AppSpacing constants
│       └── app_theme.dart        # ThemeData light + dark
├── features/                     # Feature-first screen organization
│   ├── auth/                     # get_started, login, signup, forgot_password
│   ├── home/home_screen.dart
│   ├── search/search_screen.dart
│   ├── recipe_detail/recipe_detail_screen.dart
│   ├── favorites/favorites_screen.dart
│   ├── grocery/grocery_list_screen.dart
│   ├── profile/profile_screen.dart
│   ├── scan/scan_screen.dart
│   ├── onboarding/onboarding_screen.dart
│   └── dietary_preferences/dietary_preferences_screen.dart
├── shared/widgets/               # Reusable widgets (barrel: widgets.dart)
├── models/models.dart            # All data models (barrel export)
├── providers/
│   ├── firebase_providers.dart   # RecipeProvider, UserProvider, GroceryListProvider
│   └── app_providers.dart        # Re-exports firebase_providers.dart
└── services/
    └── firebase_service.dart     # FirebaseService singleton
```

### Adding a New Feature

1. Create `lib/features/{name}/{name}_screen.dart`
2. Add route to `lib/app/routes.dart`
3. If needs state: add methods to an existing provider, or create a new `ChangeNotifier` in `firebase_providers.dart` and register in `main.dart`
4. If needs new Firestore collection: add CRUD methods to `FirebaseService`, update `firestore.rules`
5. Add reusable widgets to `lib/shared/widgets/` and export from `widgets.dart`

---

## Platform-Specific Notes

### Android

- Min SDK: 21 (`android/app/build.gradle`)
- Application ID: `com.example.smartchefai` (must rename before Play Store release)
- Permissions declared: `CAMERA`, `READ_EXTERNAL_STORAGE`, `RECORD_AUDIO`
- Google Sign-In: OAuth client in `google-services.json`
- `speech_to_text` uses Android SpeechRecognizer API (on-device)

### Web

- Firebase configured in `firebase_options.dart` (web section)
- `image_picker` on web: gallery only (no direct camera access on all browsers)
- `speech_to_text` on web: works on Chrome and Edge; not all browsers
- Navigation: standard GoRouter URL routing — deep links work as-is
- `permission_handler` has limited web support — camera/mic access via browser prompt

---

*Last updated: 2026-02-20 | Project: SmartChef AI v0.1.0 | Targets: Android + Web*
