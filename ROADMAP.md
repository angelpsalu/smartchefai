# SmartChef AI - Development Roadmap

> Platform targets: **Android + Web**
> Methodology: Fix bugs and build new features concurrently across phases.
> Always reference `BUGS.md` before starting any phase.

---

## Phase 0: Stabilization `[Current Priority]`

> Goal: Make the existing app actually work correctly. No new features - only fix, clean, and solidify.

### 0.1 Critical Bug Fixes

- [ ] **BUG-001** - Fix sign-out: call `UserProvider.logout()` in profile screen confirmation dialog
- [ ] **BUG-002** - Replace all `Navigator.pushNamed()` calls with GoRouter (`context.go` / `context.push`)
- [ ] **BUG-003** - Fix recipe detail navigation to use `extra:` instead of `arguments:`
- [ ] **BUG-004** - Fix cook time display (string concat → numeric or display separately)
- [ ] **BUG-005** - Move grocery screen into `ShellRoute` or remove redundant bottom nav

### 0.2 Dead Code Removal

- [ ] Delete `lib/widgets/custom_widgets.dart`
- [ ] Delete `lib/services/api_service.dart`
- [ ] Delete `lib/providers/grocery_provider.dart`
- [ ] Remove 11 unused packages from `pubspec.yaml` (see BUGS.md cleanup table)
- [ ] Run `flutter pub get` after cleanup to verify no broken imports

### 0.3 Foundation Fixes

- [ ] **BUG-008** - Configure Poppins font: add via `google_fonts` package or local font files
- [ ] **BUG-007** - Add `google_logo.png` to `assets/icons/`
- [ ] Move `AppUser` class from `firebase_service.dart` to `lib/models/models.dart`
- [ ] Add `firestore.rules` with proper security rules (authenticated read/write per user)
- [ ] Add `storage.rules` (allow authenticated users to read/write their own files)

**Success criteria**: App builds clean, all navigation works, sign-out works, no dead imports.

---

## Phase 1: Feature Completion

> Goal: Finish features that are half-built. Connect UI to existing Firebase backend.

### 1.1 Profile Screen

- [ ] Real "Recipes Made" stat - track in Firestore `users/{uid}` document
- [ ] Real "Streak" stat - calculate from `lastCookedDate` field
- [ ] Notifications toggle - wire to SharedPreferences (local) or Firestore user doc
- [ ] Language selector - save to SharedPreferences
- [ ] Help & FAQ - open a web URL or show an in-app sheet
- [ ] Send Feedback - open email intent or in-app form
- [ ] Rate the App - open Play Store / App Store URL

### 1.2 Grocery List Firebase Sync

> The `FirebaseService` already has `createGroceryList()` and `getGroceryLists()` fully implemented. The UI just isn't using them.

- [ ] Load grocery lists from Firestore when user is authenticated
- [ ] Save grocery list changes to Firestore
- [ ] Merge local items with Firebase items on login
- [ ] Show "not synced" badge for guest users

### 1.3 Guest Mode → Firebase Anonymous Auth

- [ ] Replace `signInAsGuest()` local stub with `FirebaseService().signInAnonymously()`
- [ ] Update Firestore security rules to allow anonymous users
- [ ] Migrate anonymous user data to permanent account on sign-up (if desired)

### 1.4 Recent Searches

- [ ] Replace hardcoded recent searches with real history stored in Firestore `users/{uid}/search_history`
- [ ] `FirebaseService` already has `addToSearchHistory()` - just connect it to the UI

### 1.5 Recipe Card Fix

- [ ] Replace placeholder image URLs in `data/recipes.json` with real TheMealDB images
- [ ] Handle missing/broken image URLs gracefully with a local fallback asset

**Success criteria**: Profile shows real data, grocery list syncs to Firebase, recent searches persist.

---

## Phase 2: New Features

> Goal: Add the features that make SmartChef AI actually "smart". Prioritized for Android + Web.

### 2.1 Real AI Ingredient Detection

> Current scan screen always returns the same 6 mock ingredients.

- [ ] Integrate a real ML solution:
  - **Option A**: Firebase ML Custom Model (recommended for Firebase-first architecture)
  - **Option B**: Google Cloud Vision API (label detection endpoint)
  - **Option C**: On-device with TensorFlow Lite (offline, no cost)
- [ ] Replace `_analyzeImage()` mock in `scan_screen.dart` with real API call
- [ ] Display confidence scores alongside detected ingredients
- [ ] Allow users to add/remove detected ingredients before searching

### 2.2 Nutrition Goal Tracking

> `fl_chart` is already in `pubspec.yaml` (currently unused).

- [ ] Add nutrition goals to user profile (daily calorie target, macros)
- [ ] Track meals cooked against goals
- [ ] Display progress chart on profile screen using `fl_chart`
- [ ] Weekly summary view

### 2.3 Meal Planning Calendar

- [ ] 7-day meal plan screen (new route `/meal-plan`)
- [ ] Tap a day to assign a recipe
- [ ] Auto-generate grocery list from weekly meal plan
- [ ] Persist plan to Firestore `meal_plans/{uid}`

### 2.4 Recipe Sharing (Android + Web)

- [ ] Generate shareable deep links using Firebase Dynamic Links or custom URL scheme
- [ ] `share_plus` is already integrated - extend it with recipe URL sharing
- [ ] Web: share as `/recipe/{id}` URL that loads without auth
- [ ] Android: share via system share sheet with recipe name + link

### 2.5 Email Verification

- [ ] After sign-up, send verification email via Firebase Auth
- [ ] Show "verify your email" banner on home screen if unverified
- [ ] Resend verification email option in profile settings

### 2.6 Improved Recipe Data

- [ ] Seed Firestore with more recipes (TheMealDB has 300+ categories)
- [ ] Add recipe images to Firebase Storage (optional, if needed)
- [ ] Add rating/review system per recipe

**Success criteria**: Scan works with real ingredients, meal plan exists, sharing works on Android and Web.

---

## Phase 3: Quality & Release Readiness

> Goal: Production-grade quality. Tests, performance, accessibility, deployment.

### 3.1 Testing

- [ ] Unit tests for all models (`Recipe`, `AppUser`, `GroceryList`, etc.)
- [ ] Unit tests for `FirebaseService` methods (mock Firestore)
- [ ] Unit tests for `RecipeProvider`, `UserProvider`, `GroceryListProvider`
- [ ] Widget tests for auth flow (login, signup, forgot password)
- [ ] Widget tests for home screen and recipe detail
- [ ] Integration test for full auth → home → recipe detail → add to grocery flow

### 3.2 Performance

- [ ] Implement image lazy loading and progressive display
- [ ] Paginate recipe lists (currently loads all at once)
- [ ] Optimize Firestore reads with proper query limits and cursors
- [ ] Add skeleton loading states using the `shimmer` package (currently declared but unused)
- [ ] Profile app with Flutter DevTools, fix any jank

### 3.3 Accessibility

- [ ] Add `Semantics` labels to icon-only buttons
- [ ] Verify minimum touch target sizes (48x48dp)
- [ ] Test with TalkBack (Android) and screen reader (Web)
- [ ] Ensure sufficient color contrast ratios in both light and dark themes

### 3.4 Android Release

- [ ] Update package name from `com.example.smartchefai` to production name
- [ ] Configure signing keystore
- [ ] Set up `proguard-rules.pro` for release builds
- [ ] Add Play Store assets (icon, screenshots, feature graphic)
- [ ] Build and test release APK / App Bundle
- [ ] Firestore security rules audit before release

### 3.5 Web Release

- [ ] Configure `web/index.html` with proper meta tags and favicon
- [ ] Set up Firebase Hosting (`firebase.json` already present)
- [ ] Configure CORS for Firebase Storage if using image uploads
- [ ] Test responsive layout on desktop and mobile browsers
- [ ] Add PWA manifest for installable web app

### 3.6 CI/CD (Optional)

- [ ] GitHub Actions workflow for `flutter test` on PR
- [ ] Automated `flutter build apk` on merge to main
- [ ] Automated Firebase Hosting deploy on merge to main

**Success criteria**: All critical paths tested, app store submission ready, web deployed.

---

## Feature Backlog (Phase 4+)

Ideas for future phases, not yet scoped:

- Community recipe uploads
- In-app cooking timer with notifications
- Shopping list sharing via cloud link
- Barcode scanning for packaged ingredients
- Restaurant recommendations by location
- Social login (Apple Sign-In, Facebook)
- Recipe video integration
- Multilingual support (using `intl` package already in pubspec)
- Offline-first full recipe content (download for offline use)
- Wearable integration (cooking timer on smartwatch)

---

## Dependency Map

```
Phase 0 (Stabilization)
    └── must complete before Phase 1

Phase 1 (Feature Completion)
    ├── 1.3 (Guest → Firebase Auth) should precede 1.2 (Grocery Sync)
    └── can otherwise run concurrently

Phase 2 (New Features)
    ├── 2.2 (Nutrition) can start independently
    ├── 2.3 (Meal Plan) depends on Phase 1 grocery sync
    └── 2.4 (Sharing) depends on Phase 0 navigation fix

Phase 3 (Quality)
    └── should start alongside Phase 2, not after
```

---

*Last updated: 2026-02-19 | Project: SmartChef AI v0.1.0 | Targets: Android + Web*
