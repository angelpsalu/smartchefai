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

No open bugs.

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

### ~~NOTE-003~~: signInAnonymously() leftover — **RESOLVED**

- Deleted `signInAnonymously()` from `FirebaseService`.

### ~~NOTE-004~~: Duplicate User model — **RESOLVED**

- Removed `User` class from `models.dart`. `UserProvider.currentUser` now returns `AppUser` directly.

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
| BUG-006 | Profile stats "Recipes Made" and "Streak" hardcoded | Stats now show `0` (real tracking in Phase 1) |
| BUG-007 | `google_logo.png` asset missing | Added official Google 'G' logo PNG to `assets/icons/` |
| BUG-004 | `Recipe.prepTime`/`cookTime` were String types | Changed to `int` (minutes), `fromJson` handles both formats |

---

## Cleanup Items

These are not bugs but should be addressed before the first release.

| Item | File | Action |
|------|------|--------|
| ~~Dead `User` model~~ | `lib/models/models.dart` | **Done** — removed `User` class |
| ~~`signInAnonymously()` leftover~~ | `lib/services/firebase_service.dart` | **Done** — deleted method |
| `flutter_animate` in old docs | `CLAUDE.md`, `README.md` | Remove references — never added to `pubspec.yaml`, never imported |

---

*Last updated: 2026-02-20 | Project: SmartChef AI v0.1.0*
