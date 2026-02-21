# SmartChef AI - Coding Guide

> **AI-Powered Recipe Recommender**
> Architecture: Firebase + Flutter | Targets: Android + Web
> Last updated: 2026-02-20

For deep technical details see [`ARCHITECTURE.md`](ARCHITECTURE.md).
For bugs and cleanup items see [`BUGS.md`](BUGS.md).
For feature planning see [`ROADMAP.md`](ROADMAP.md).

---

## Running the App

```bash
# Scan feature requires VISION_API_KEY — always run with:
flutter run --dart-define-from-file=dart_defines/dev.json

# VS Code: press F5 — .vscode/launch.json passes the flag automatically
```

Setup: copy `dart_defines/dev.json.example` → `dart_defines/dev.json`, paste your Vision API key.
Requires Cloud Vision API enabled + billing linked on GCP project `smartchefai-344c5` (1,000 calls/month free).

---

## Project Structure

```
dart_defines/
├── dev.json              # gitignored — add VISION_API_KEY here (copy from .example)
└── dev.json.example      # committed template for new devs
functions/                # Cloud Function TypeScript — NOT deployed (Spark plan); kept for Blaze upgrade
lib/
├── main.dart                     # App entry, Firebase init, MultiProvider
├── firebase_options.dart         # Firebase config (Android + Web real, iOS placeholder)
├── app/
│   ├── routes.dart               # GoRouter with ShellRoute + auth redirect
│   └── theme/
│       ├── app_colors.dart       # Color constants (AppColors)
│       ├── app_typography.dart   # Text styles (AppTypography) — Poppins via google_fonts
│       ├── app_spacing.dart      # Spacing constants (AppSpacing)
│       └── app_theme.dart        # ThemeData (light + dark)
├── features/                     # Feature-first screen structure
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
├── shared/widgets/               # Reusable widgets (widgets.dart barrel export)
├── models/models.dart            # All data models (barrel export)
├── providers/
│   ├── firebase_providers.dart   # RecipeProvider, UserProvider, GroceryListProvider
│   └── app_providers.dart        # Re-exports firebase_providers.dart
└── services/
    └── firebase_service.dart     # Singleton: Firestore + Auth + TheMealDB fallback
```

---

## Coding Rules

### 1. Navigation — Always use GoRouter

```dart
// ✅ Navigate (replaces stack)
context.go('/search');

// ✅ Push detail screen (back button works)
context.push('/recipe/${recipe.id}', extra: recipe);

// ❌ Never — bypasses ShellRoute and auth guard
Navigator.pushNamed(context, '/search');
Navigator.push(context, MaterialPageRoute(...));
```

### 2. Passing Data to Routes

GoRouter uses `extra:`, not `arguments:`:

```dart
// ✅ Correct
context.push('/recipe/${recipe.id}', extra: recipe);

// In the receiving screen:
final recipe = state.extra as Recipe?;

// ❌ Wrong — extra will be null
Navigator.pushNamed(context, '/recipe/${id}', arguments: recipe);
```

### 3. Opacity

```dart
// ✅ Use withValues() — withOpacity() is deprecated in Flutter 3.x
Colors.black.withValues(alpha: 0.1)

// ❌ Deprecated
Colors.black.withOpacity(0.1)
```

### 4. Widget Constructor

```dart
// ✅ Modern
const MyWidget({super.key});

// ❌ Old style
const MyWidget({Key? key}) : super(key: key);
```

### 5. BuildContext After Async

```dart
Future<void> _doSomething() async {
  await someAsyncOperation();
  if (!mounted) return;  // ✅ Always check before using context
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### 6. Immutable State Updates

```dart
// ✅ Use copyWith — creates new object, triggers Provider rebuild
_items[index] = _items[index].copyWith(checked: true);
notifyListeners();

// ❌ Direct mutation — Provider will NOT detect this
_items[index].checked = true;
```

### 7. Spacing & Colors

```dart
// ✅ Use constants
SizedBox(height: AppSpacing.md)    // 16.0
color: AppColors.primaryOrange     // Color(0xFFFF6B35)

// ❌ Raw values create inconsistency
SizedBox(height: 16)
color: Color(0xFFFF6B35)
```

---

## State Management

Three providers. All extend `ChangeNotifier`. Registered in `main.dart`.

| Provider | What it owns |
|----------|-------------|
| `RecipeProvider` | `_recipes`, `_favoriteIds`, loading/error state, search results |
| `UserProvider` | Auth state, `AppUser` profile, theme mode, recent searches |
| `GroceryListProvider` | Grocery items, local + Firebase sync |

```dart
// Reading without subscribing
context.read<RecipeProvider>().loadRecipes();

// Reading + subscribing to changes
final recipes = context.watch<RecipeProvider>().recipes;

// Fine-grained subscription
final isLoading = context.select<RecipeProvider, bool>((p) => p.isLoading);
```

---

## Firebase

### Service singleton

```dart
final service = FirebaseService();  // Always the same instance
```

Key capabilities (see `firebase_service.dart`):
- `analyzeImage(XFile)` — Vision REST API, food-only allowlist filter, returns `List<DetectedIngredient>`
- `getAllRecipes()` - cached, falls back to TheMealDB if Firestore empty
- `searchRecipes(query)`, `searchByIngredients(ingredients)`
- Email/password auth, Google Sign-In, password reset
- `getUserProfile()`, `createUserProfile()`
- `addFavorite()`, `removeFavorite()`, `getFavoriteIds()`
- `createGroceryList()`, `getGroceryLists()`
- `addSearchHistory()`, `getSearchHistory()`

### Auth check

```dart
// Synchronous - safe to call immediately after Firebase.initializeApp()
FirebaseService().isSignedIn  // bool
FirebaseService().currentUser  // firebase_auth.User?
```

### Firebase project

- Project ID: `smartchefai-344c5`
- Android: configured (`google-services.json` present)
- Web: configured (`firebase_options.dart`)
- iOS/macOS/Windows: **NOT configured** (placeholder values only)
- Firebase plan: **Spark (free)** — `firebase deploy --only functions` will fail; upgrade to Blaze to deploy Cloud Functions

---

## Models

Location: `lib/models/models.dart`

| Model | Purpose |
|-------|---------|
| `Recipe` | Recipe with ingredients, steps, nutrition, imageUrl. `prepTime`/`cookTime` are `int` (minutes) |
| `Nutrition` | Calories (int), protein, carbs, fat, fiber (Strings like "25g") |
| `AppUser` | Firebase user with Firestore profile data |
| `GroceryList` | List of GroceryItems with Firestore sync |
| `GroceryItem` | Immutable grocery item with `copyWith` |
| `DetectedIngredient` | Scan result with confidence score |

All models: `const` constructor, named params, `copyWith()`, `fromJson()`, `toJson()`.

---

## Adding New Features

1. Create screen in `lib/features/{name}/{name}_screen.dart`
2. Add route to `lib/app/routes.dart`
3. If needs state: add methods to existing provider or create new `ChangeNotifier` in `firebase_providers.dart` and register in `main.dart`
4. If needs new Firestore collection: add CRUD methods to `FirebaseService`, update `firestore.rules`
5. Add reusable widgets to `lib/shared/widgets/` and export via `widgets.dart`

---

## Open Bugs

See [`BUGS.md`](BUGS.md) for the full list. No open bugs currently.

---

## Dependencies In Use

| Package | Used For |
|---------|---------|
| `firebase_core` | Firebase init |
| `cloud_firestore` | Database |
| `firebase_auth` | Authentication |
| `firebase_storage` | Profile photo upload/delete (`users/{uid}/profile.jpg`) |
| `google_sign_in` | Google OAuth |
| `provider` | State management |
| `go_router` | Navigation |
| `dio` | HTTP client (TheMealDB API + Cloud Vision REST API + retry interceptor) |
| `http` | HTTP client (secondary) |
| `shared_preferences` | Onboarding flag, theme setting, offline favorites/grocery cache |
| `cached_network_image` | Image loading with cache |
| `image_picker` | Camera + gallery access |
| `speech_to_text` | Voice search |
| `share_plus` | Share recipe via system sheet |
| `google_fonts` | Poppins font (loaded at runtime) |
| `permission_handler` | Runtime permissions |
