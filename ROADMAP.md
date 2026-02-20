# SmartChef AI — Development Roadmap

> Platform targets: **Android + Web**
> Last updated: 2026-02-20
> Always reference [BUGS.md](BUGS.md) before starting any phase.

---

## Phase 0: Stabilization ✅ Mostly Done

> Goal: Make the existing app work correctly. Fix bugs, remove dead code, solidify the foundation.

### 0.1 Bug Fixes

- [x] Fix sign-out: `UserProvider.logout()` called correctly in profile screen (`0bac85e`)
- [x] Replace all `Navigator.pushNamed()` calls with GoRouter (`context.go` / `context.push`)
- [x] Fix recipe detail navigation to use `extra:` instead of `arguments:`
- [x] Remove grocery screen redundant bottom nav (now a full-screen route outside ShellRoute)
- [x] Remove guest mode that bypassed Firebase Auth (`09a360a`)
- [ ] **BUG-006** - Profile "Recipes Made" and "Streak" stats still hardcoded (`profile_screen.dart:107,116`)
- [ ] **BUG-007** - Add `google_logo.png` to `assets/icons/`
- [ ] **BUG-004** - Change `Recipe.prepTime`/`cookTime` from String to int

### 0.2 Dead Code / Cleanup

- [x] Deleted `lib/widgets/custom_widgets.dart`
- [x] Deleted `lib/services/api_service.dart`
- [x] Deleted `lib/providers/grocery_provider.dart`
- [x] Removed unused packages from `pubspec.yaml`
- [x] Moved `AppUser` to `lib/models/models.dart`
- [ ] Delete `signInAnonymously()` from `FirebaseService` (leftover from guest mode)
- [ ] Remove `User` class from `lib/models/models.dart` — use `AppUser` directly
- [ ] Add `firestore.rules` with production-grade security rules
- [ ] Add `storage.rules`

### 0.3 Feature Data

- [x] Replace placeholder recipe images with real TheMealDB URLs (`d7ff8d0`)
- [x] Wire recent searches to Firebase (`9f19e00`)
- [x] Add "Save to Cloud" button to grocery screen (`98f9e9a`)

**Success criteria**: App builds clean, all navigation works, sign-out works, no stale dead code.

---

## Phase 1: Feature Completion

> Goal: Finish features that are half-built. Connect UI to existing Firebase backend.

### 1.1 Profile Screen — Real Stats

- [ ] Add `recipesCooked` (int) field to Firestore `users/{uid}` document
- [ ] Add `currentStreak` (int) and `lastCookedDate` (timestamp) to user document
- [ ] Display live stats from `UserProvider` in profile stat cards
- [ ] Notifications toggle — wire to `SharedPreferences` or Firestore user doc
- [ ] Language selector — save to `SharedPreferences`
- [ ] Help & FAQ — open a web URL or in-app sheet
- [ ] Send Feedback — open email intent or in-app form
- [ ] Rate the App — open Play Store URL (Android) / App Store URL (iOS if added)

### 1.2 Grocery List Auto-Sync

> `FirebaseService` already has `createGroceryList()`, `getGroceryLists()`, and `toggleGroceryItem()` fully implemented. The UI currently only syncs manually via the cloud upload button.

- [ ] Auto-load grocery lists from Firestore when user authenticates
- [ ] Auto-save grocery list changes to Firestore in real time
- [ ] Merge local `SharedPreferences` items with Firebase items on login
- [ ] Handle conflict resolution (local vs cloud)

### 1.3 Improve Recipe Detail

- [ ] Increment `recipesCooked` counter when user taps "Start Cooking"
- [ ] Add "Add all to grocery list" button that populates grocery list from recipe ingredients
- [ ] Display estimated total time from `prepTimeInt + cookTimeInt` (use existing getters)

**Success criteria**: Profile shows real user data, grocery list syncs automatically.

---

## Phase 2: New Features

> Goal: Add features that make SmartChef AI genuinely useful. Android + Web targeted.

### 2.1 Real AI Ingredient Detection ✅ Done

- [x] Firebase Cloud Function `analyzeIngredients` (HTTP trigger, gen 2, Node 20, TypeScript)
- [x] Google Cloud Vision `LABEL_DETECTION` — score ≥ 0.65, non-food blocklist applied
- [x] `FirebaseService.analyzeImage(XFile)` — base64 encode, ID token auth, Dio POST
- [x] `ScanScreen` — real detection replaces mock, image compressed to 512×512px
- [x] `ScanScreen` — inline horizontal scroll row of `RecipeCard`s (no navigation to `/search`)
- [x] Users can edit/remove detected ingredient chips before searching
- [ ] **Pending**: Deploy Cloud Function (requires Firebase Blaze plan upgrade)
- [ ] Confidence scores displayed in chip UI (out of scope this phase)

### 2.2 Email Verification Flow

- [ ] After sign-up, send verification email via Firebase Auth
- [ ] Show "verify your email" banner on home screen if `user.emailVerified == false`
- [ ] Resend verification email option in profile screen

### 2.3 Meal Planning Calendar

- [ ] New screen: `/meal-plan` (7-day calendar view)
- [ ] Tap a day to assign a recipe
- [ ] Auto-generate grocery list from weekly meal plan
- [ ] Persist plan to Firestore `meal_plans/{uid}`

### 2.4 Recipe Sharing (Android + Web)

- [ ] `share_plus` is already integrated — extend with recipe URL sharing
- [ ] Generate a shareable deep link per recipe (`/recipe/{id}`)
- [ ] Web: the recipe detail route already works at `/recipe/{id}` — make it load without auth for shared links
- [ ] Android: share via system share sheet with recipe name + link

### 2.5 Nutrition Goal Tracking

- [ ] Add nutrition goals to user profile (daily calorie, protein, carbs, fat targets)
- [ ] Track daily intake from "meals cooked" history
- [ ] Display progress chart — add `fl_chart` package if implementing this feature
- [ ] Weekly nutrition summary view

### 2.6 Firebase Storage Integration

- [ ] Allow users to upload a profile photo (declared in `pubspec.yaml` but not yet used)
- [ ] Store photos in `Firebase Storage` under `users/{uid}/profile.jpg`
- [ ] Display in `ProfileAvatar` widget

**Success criteria**: Scan uses real ML, meal plan exists, sharing works, nutrition tracking exists.

---

## Phase 3: Quality & Release Readiness

> Goal: Production-grade quality. Tests, performance, accessibility, store submissions.

### 3.1 Testing

- [ ] Unit tests: all models (`Recipe`, `AppUser`, `GroceryList`, `GroceryItem`)
- [ ] Unit tests: `FirebaseService` methods (use mock Firestore via `fake_cloud_firestore`)
- [ ] Unit tests: `RecipeProvider`, `UserProvider`, `GroceryListProvider`
- [ ] Widget tests: auth flow (login → signup → forgot password)
- [ ] Widget tests: home screen, recipe card, recipe detail
- [ ] Integration test: full flow — auth → home → recipe detail → add to grocery

### 3.2 Performance

- [ ] Paginate recipe lists (currently loads all at once)
- [ ] Add skeleton loading states for recipe grid (add `shimmer` package)
- [ ] Optimize Firestore reads with proper query limits and cursors
- [ ] Profile with Flutter DevTools; fix any frame drops

### 3.3 Accessibility

- [ ] Add `Semantics` labels to icon-only buttons (mic, camera, cloud upload)
- [ ] Verify minimum touch target sizes (48×48dp for all interactive elements)
- [ ] Test with TalkBack (Android) and VoiceOver/screen reader (Web)
- [ ] Check color contrast ratios in both light and dark themes

### 3.4 Android Release

- [ ] Update application ID from `com.example.smartchefai` to production name
- [ ] Configure signing keystore (`key.jks`)
- [ ] Configure `proguard-rules.pro` for release builds
- [ ] Add Play Store listing assets: icon (512px), feature graphic, screenshots
- [ ] Build and test release APK / App Bundle
- [ ] Final Firestore security rules audit

### 3.5 Web Release

- [ ] Configure `web/index.html` with proper title, meta tags, and favicon
- [ ] Set up Firebase Hosting (`firebase.json` → `firebase deploy --only hosting`)
- [ ] Configure CORS for Firebase Storage (for profile photo uploads)
- [ ] Test responsive layout at 320px, 768px, 1024px, 1440px breakpoints
- [ ] Add PWA `manifest.json` for installable web experience

### 3.6 CI/CD

- [ ] GitHub Actions: run `flutter test` on every PR
- [ ] GitHub Actions: run `flutter analyze` and fail on warnings
- [ ] Automated `flutter build apk` on merge to `main`
- [ ] Automated Firebase Hosting deploy on merge to `main`

**Success criteria**: All critical paths have tests, app passes store review, web is live.

---

## Feature Backlog (Phase 4+)

Ideas for future phases — not yet scoped:

- Community recipe uploads and ratings
- In-app cooking timer with step-by-step voice guidance
- Grocery list sharing via shareable cloud link
- Barcode scanning for packaged food ingredients
- Social login (Apple Sign-In, Facebook)
- Recipe video integration (YouTube embed or Firebase-hosted)
- Multilingual support
- Offline-first full recipe content (download for offline use)

---

## Task Dependency Map

```
Phase 0 (Stabilization)
    └── must complete before Phase 1

Phase 1 (Feature Completion)
    ├── 1.2 (Grocery Sync) can start once Phase 0 cleanup is done
    └── 1.1 (Profile Stats) is independent — can start anytime

Phase 2 (New Features)
    ├── 2.1 (AI Scan) is independent
    ├── 2.2 (Email Verification) is independent
    ├── 2.3 (Meal Plan) benefits from 1.2 (Grocery Sync) being done first
    └── 2.4 (Sharing) is independent

Phase 3 (Quality)
    └── should START alongside Phase 2, not wait until Phase 2 is done
        (write tests for features as they land, not at the end)
```

---

*Last updated: 2026-02-20 | Project: SmartChef AI v0.1.0 | Targets: Android + Web*
