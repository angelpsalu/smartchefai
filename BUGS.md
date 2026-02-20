# SmartChef AI — Bug Tracker

> Last updated: 2026-02-20
> See [ROADMAP.md](ROADMAP.md) for fix priority order.

---

## Severity Legend

| Level | Meaning |
|-------|---------|
| **HIGH** | Feature completely broken or causes data loss |
| **MEDIUM** | Feature partially broken, wrong behavior |
| **LOW** | Minor UX issue, cosmetic, or non-critical |

---

## Open Bugs

### BUG-006: Profile stats "Recipes Made" and "Streak" are hardcoded — LOW

- **File**: `lib/features/profile/profile_screen.dart:107,116`
- **Description**: The "Recipes Made" stat card displays the hardcoded string `'12'` and the "Streak" card displays `'5 days'`. The Favorites count is already live (`provider.favoriteRecipes.length`), but the other two stat cards never read from Firebase or local state.
- **Impact**: Profile screen shows false data for all users.
- **Fix**: Track `recipesCooked` and `currentStreak` in the Firestore user profile document. Expose via `AppUser` model and `UserProvider`. Read from provider in the stat cards.
- **Status**: Open

---

### BUG-007: google_logo.png asset missing — LOW

- **Files**: `lib/features/auth/login_screen.dart:316`, `lib/features/auth/signup_screen.dart:364`
- **Description**: Both auth screens reference `assets/icons/google_logo.png` in `Image.asset()`. The file does not exist — only `assets/icons/.gitkeep` is present. The `errorBuilder` gracefully falls back to `Icons.g_mobiledata`.
- **Impact**: Google Sign-In button shows a generic icon instead of the official Google logo. Visually degraded, not broken.
- **Fix**: Add the official Google logo PNG to `assets/icons/google_logo.png`. Official assets: https://developers.google.com/identity/branding-guidelines
- **Status**: Open

---

### BUG-004: Recipe.prepTime and cookTime are String types — LOW

- **File**: `lib/models/models.dart:15-16,27-28`
- **Description**: `Recipe.prepTime` and `Recipe.cookTime` are `String` fields (e.g., `"15 min"`). Computed `prepTimeInt` / `cookTimeInt` getters (lines 27-28) strip non-numeric characters and parse the int. All current callers use the getters correctly (`recipe.prepTimeInt + recipe.cookTimeInt`), but the underlying type is fragile — future callers who access `.prepTime` directly will get a string, not a number.
- **Impact**: No current breakage. Maintainer trap for future developers.
- **Fix**: Change `prepTime` and `cookTime` to `int` (store minutes). Update `fromJson` to handle both `int` and `String` input for backwards compatibility. Remove the getter shims.
- **Status**: Open

---

## Design Notes (Not Bugs)

### NOTE-001: GoRouter redirect is synchronous, not stream-based

- **File**: `lib/app/routes.dart:30-49`
- **Description**: The auth redirect reads `firebaseService.isSignedIn` (sync bool property). It does not subscribe to `authStateChanges`. After logout, navigation to `/get-started` is triggered explicitly in `_handleSignOut` (`profile_screen.dart:33`). This works for normal usage but won't auto-redirect on token expiry mid-session.
- **Suggestion**: Pass a `refreshListenable` to GoRouter that listens to `authStateChanges` for automatic redirect on token expiry.

### NOTE-002: Grocery list is local-only by default

- **Files**: `lib/features/grocery/grocery_list_screen.dart`, `lib/providers/firebase_providers.dart:543-579`
- **Description**: Grocery items are persisted to `SharedPreferences` only. The cloud upload icon button manually triggers a Firebase save. The list does not auto-load from Firebase on app launch.
- **Impact**: Items are lost if the user switches devices or reinstalls.
- **Suggestion**: Phase 1 task — auto-load from Firebase on auth and sync on change.

### NOTE-003: signInAnonymously() leftover in FirebaseService

- **File**: `lib/services/firebase_service.dart:109`
- **Description**: `signInAnonymously()` remains in `FirebaseService` from the removed guest mode feature. It is no longer called from the UI.
- **Suggestion**: Delete the method to prevent accidental use.

### NOTE-004: Duplicate User model

- **File**: `lib/models/models.dart:206`
- **Description**: A `User` class exists alongside `AppUser`. `UserProvider.currentUser` wraps `AppUser` into a `User` for legacy compatibility. `User` is otherwise unused.
- **Suggestion**: Remove the `User` class and update `UserProvider` to expose `AppUser` directly.

---

## Resolved / Archived

The following bugs from the original backlog have been fixed in recent commits.

| ID | Title | Fixed In |
|----|-------|----------|
| BUG-001 | Sign-out button didn't call `UserProvider.logout()` | commit `0bac85e` |
| BUG-002 | `Navigator.pushNamed` used instead of GoRouter in 6+ locations | Cleaned up across codebase |
| BUG-003 | Recipe navigation passed `arguments:` instead of `extra:` | Fixed in search + favorites screens |
| BUG-005 | Grocery screen had redundant `BottomNavigationBar` | Removed; grocery is now a full-screen route outside ShellRoute |
| BUG-008 | Poppins font "not configured" | Non-issue; `app_typography.dart` uses `google_fonts` package (`GoogleFonts.poppinsTextTheme()`) which is in `pubspec.yaml` |
| BUG-009 | Guest mode bypassed Firebase Auth with local `AppUser(id:'guest')` | Removed entirely in commit `09a360a` |

---

## Cleanup Items

These are not bugs but should be addressed before the first release.

| Item | File | Action |
|------|------|--------|
| Dead `User` model | `lib/models/models.dart:206` | Remove `User` class; use `AppUser` directly in `UserProvider` |
| `signInAnonymously()` leftover | `lib/services/firebase_service.dart:109` | Delete method (unused since guest mode removed) |
| `flutter_animate` in old docs | `CLAUDE.md`, `README.md` | Remove references — never added to `pubspec.yaml`, never imported |

---

*Last updated: 2026-02-20 | Project: SmartChef AI v0.1.0*
