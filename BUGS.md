# SmartChef AI - Bug Tracker

> Active bug log for SmartChef AI. All bugs found via codebase analysis.
> Reference this file before starting any feature work to avoid building on broken foundations.

---

## Severity Legend

| Level | Meaning |
|-------|---------|
| **HIGH** | Feature completely broken or causes data loss |
| **MEDIUM** | Feature partially broken, wrong behavior |
| **LOW** | Minor UX issue, cosmetic, or non-critical |
| **INFO** | Design decision to document, not a bug per se |

---

## Open Bugs

### BUG-001: Sign-Out Does Not Work `HIGH`

- **File**: `lib/features/profile/profile_screen.dart` ~line 185
- **Description**: The Sign Out confirmation dialog button only calls `Navigator.pop(context)`. The actual `UserProvider.logout()` method is never called.
- **Impact**: Users cannot sign out of the app. They are permanently stuck in their session.
- **Fix**: Call `context.read<UserProvider>().logout()` inside the confirmation button, then navigate to `/login` via GoRouter after successful logout.
- **Status**: Open

---

### BUG-002: Navigator.pushNamed Used Instead of GoRouter `MEDIUM`

- **Files & Lines**:
  - `lib/features/search/search_screen.dart` ~line 126 → pushes `/scan`
  - `lib/features/search/search_screen.dart` ~line 307 → pushes `/recipe/${recipe.id}` with `arguments:`
  - `lib/features/favorites/favorites_screen.dart` ~line 51 → pushes `/recipe/${recipe.id}` with `arguments:`
  - `lib/features/favorites/favorites_screen.dart` ~line 74 → same
  - `lib/features/scan/scan_screen.dart` ~line 63 → pushes `/search`
  - `lib/features/recipe_detail/recipe_detail_screen.dart` ~line 314 → pushes `/grocery`
  - `lib/features/onboarding/onboarding_screen.dart` ~line 63 → pushes `/`
- **Description**: The app uses GoRouter for all routing (ShellRoute + auth redirect). Using `Navigator.pushNamed()` bypasses GoRouter entirely - it either fails silently or navigates outside the shell (losing the bottom nav).
- **Impact**: Navigation from these screens is broken or produces incorrect UI state.
- **Fix**: Replace all `Navigator.pushNamed(context, '/path')` with `context.go('/path')` or `context.push('/path')`. For replacement-style nav, use `context.go()`.
- **Status**: Open

---

### BUG-003: Recipe Data Not Passed Correctly to Recipe Detail `MEDIUM`

- **Files**: `lib/features/search/search_screen.dart`, `lib/features/favorites/favorites_screen.dart`
- **Description**: Recipe navigation uses `Navigator.pushNamed(context, '/recipe/${recipe.id}', arguments: recipe)`. GoRouter uses `extra:` to pass route arguments, not `arguments:`. The `RecipeDetailScreen` reads the recipe via `state.extra as Recipe?` which will be `null` when navigated to this way.
- **Impact**: Recipe detail screen shows "Recipe not found" when opened from Search or Favorites.
- **Fix**: Use `context.push('/recipe/${recipe.id}', extra: recipe)` in both screens.
- **Status**: Open (blocked by BUG-002)

---

### BUG-004: Cook Time Shows Concatenated Strings `LOW`

- **Files**: `lib/features/home/home_screen.dart`, `lib/features/search/search_screen.dart`
- **Description**: `'${recipe.prepTime + recipe.cookTime} min'` concatenates two `String` values (e.g. `"15 min"` + `"30 min"`) resulting in `"15 min30 min min"`.
- **Impact**: Cook time display is garbled and unreadable on recipe cards.
- **Fix**: The `Recipe` model stores `prepTime` and `cookTime` as `String`. Either:
  1. Parse them to int before adding, or
  2. Display them separately as `"Prep: ${recipe.prepTime} | Cook: ${recipe.cookTime}"`
- **Status**: Open

---

### BUG-005: Grocery Screen Has Redundant Bottom Nav With Wrong Index `LOW`

- **File**: `lib/features/grocery/grocery_list_screen.dart` (bottom of file)
- **Description**: The grocery screen is outside the `ShellRoute` and renders its own `bottomNavigationBar: const SmartChefBottomNav(currentIndex: 0)`. Index 0 is "Home", so the grocery tab is never highlighted.
- **Impact**: Users see a bottom nav inside the grocery screen that always highlights "Home". Confusing and visually incorrect.
- **Fix**: Either move grocery into the `ShellRoute` (preferred, consistent with other tabs) or remove the redundant bottom nav from `grocery_list_screen.dart`.
- **Status**: Open

---

### BUG-006: Profile Stats Are Hardcoded `LOW`

- **File**: `lib/features/profile/profile_screen.dart` (stats card section)
- **Description**: "Recipes Made" displays literal `'12'` and "Streak" displays `'5 days'`. These are hardcoded placeholder values, not real user data.
- **Impact**: Every user sees the same fake stats. Makes the app feel unfinished.
- **Fix**: Track `recipesCooked` and `currentStreak` in the `AppUser` Firestore document and display them via `UserProvider`.
- **Status**: Open

---

### BUG-007: google_logo.png Asset Missing `LOW`

- **Files**: `lib/features/auth/login_screen.dart`, `lib/features/auth/signup_screen.dart`
- **Description**: Both files reference `assets/icons/google_logo.png` which doesn't exist (the `assets/icons/` directory only contains `.gitkeep`). The `errorBuilder` falls back to a Material `g_mobiledata` icon gracefully.
- **Impact**: Google Sign-In button shows a generic icon instead of the official Google logo. Not accessible for App Store review.
- **Fix**: Add the official Google logo PNG to `assets/icons/google_logo.png` and declare it in `pubspec.yaml` assets section.
- **Status**: Open

---

### BUG-008: Poppins Font Not Configured `LOW`

- **File**: `lib/app/theme/app_typography.dart`, `pubspec.yaml`
- **Description**: `app_typography.dart` sets `fontFamily: 'Poppins'` on text styles, but `pubspec.yaml` has no `fonts:` section declaring Poppins. Flutter will fall back to the system default font.
- **Impact**: App does not use the intended Poppins typeface. Typography looks different from design intent.
- **Fix**: Either add the Poppins font files to `assets/fonts/` and declare in `pubspec.yaml`, or add `google_fonts` package and use `GoogleFonts.poppins()`.
- **Status**: Open

---

### BUG-009: Guest Mode Bypasses Firebase Auth `INFO`

- **File**: `lib/providers/firebase_providers.dart` - `signInAsGuest()`
- **Description**: Guest mode creates a local `AppUser(id: 'guest', name: 'Guest User')` without calling Firebase Anonymous Auth. Favorites, grocery lists, and preferences are not persisted and not synced with Firestore.
- **Impact**: Guest users lose all data on app restart. Not a bug per se, but a design limitation to document.
- **Fix (if desired)**: Replace `signInAsGuest()` with `FirebaseService().signInAnonymously()` so Firestore rules can match guest users and data persists across sessions.
- **Status**: Open (design decision)

---

## Cleanup Items (Dead Code)

These are not bugs but must be removed to keep the codebase clean:

| Item | File | Reason | Action |
|------|------|--------|--------|
| Legacy widgets | `lib/widgets/custom_widgets.dart` | Never imported anywhere | Delete file |
| Legacy API service | `lib/services/api_service.dart` | Only imported by dead grocery_provider | Delete file |
| Duplicate GroceryListProvider | `lib/providers/grocery_provider.dart` | Superseded by firebase_providers.dart version | Delete file |
| AppUser class in wrong file | `lib/services/firebase_service.dart` | AppUser is a model, should be in models.dart | Move to `lib/models/models.dart` |

## Unused Dependencies (pubspec.yaml)

Remove these packages - they are declared but have zero imports across all 33 Dart files:

```yaml
# Remove these from pubspec.yaml:
shimmer: ^3.0.0
flutter_spinkit: ^5.2.0
hive: ^2.2.3
hive_flutter: ^1.1.0
flutter_tts: ^4.2.3
fl_chart: ^0.63.0
flutter_svg: ^2.0.9
intl: ^0.19.0
uuid: ^4.0.0
path_provider: ^2.1.0
url_launcher: ^6.2.0

# Also remove from dev_dependencies:
build_runner: ^2.4.0   # only needed for hive_generator
hive_generator: ^2.0.0
```

---

## Resolved Bugs

_None yet._

---

*Last updated: 2026-02-19 | Project: SmartChef AI v0.1.0*
