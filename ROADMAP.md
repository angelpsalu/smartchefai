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
- [x] **BUG-006** - Profile stats now show `0` instead of hardcoded values (real tracking in Phase 1)
- [x] **BUG-007** - Added official Google 'G' logo PNG to `assets/icons/google_logo.png`
- [x] **BUG-004** - Changed `Recipe.prepTime`/`cookTime` from String to int (minutes)

### 0.2 Dead Code / Cleanup

- [x] Deleted `lib/widgets/custom_widgets.dart`
- [x] Deleted `lib/services/api_service.dart`
- [x] Deleted `lib/providers/grocery_provider.dart`
- [x] Removed unused packages from `pubspec.yaml`
- [x] Moved `AppUser` to `lib/models/models.dart`
- [x] Delete `signInAnonymously()` from `FirebaseService` (+ removed mock `detectIngredients`)
- [x] Remove `User` class from `lib/models/models.dart` — `UserProvider.currentUser` now returns `AppUser`
- [x] Audit `firestore.rules` — production-grade (owner-only access, default deny)
- [x] Audit `storage.rules` — added 5 MB size limit + image-only content type validation

### 0.3 Feature Data

- [x] Replace placeholder recipe images with real TheMealDB URLs (`d7ff8d0`)
- [x] Wire recent searches to Firebase (`9f19e00`)
- [x] Add "Save to Cloud" button to grocery screen (`98f9e9a`)

**Success criteria**: App builds clean, all navigation works, sign-out works, no stale dead code.

---

## Phase 1: Feature Completion

> Goal: Finish features that are half-built. Connect UI to existing Firebase backend.

### 1.1 Profile Screen — Real Stats

- [x] Add `recipesCooked` (int) field to Firestore `users/{uid}` document
- [x] Add `currentStreak` (int) and `lastCookedDate` (timestamp) to user document
- [x] Display live stats from `UserProvider` in profile stat cards
- [x] Notifications toggle — wired to `SharedPreferences`
- [x] Language selector — saves to `SharedPreferences`, shows dialog with 6 languages
- [x] Help & FAQ — opens GitHub URL via `url_launcher`
- [x] Send Feedback — opens `mailto:` intent via `url_launcher`
- [x] Rate the App — opens Play Store URL via `url_launcher`

### 1.2 Grocery List Auto-Sync

- [x] Auto-load grocery list from Firestore on app start / login (`syncOnLogin()` from HomeScreen)
- [x] Auto-save changes to Firestore on every add/remove/toggle/clear
- [x] Merge local `SharedPreferences` items with Firebase items (cloud checked state wins)
- [x] Conflict resolution: union of item names, cloud wins for checked state
- [x] Cloud status indicator in AppBar (cloud_done / cloud_off icon)

### 1.3 Improve Recipe Detail

- [x] "Start Cooking" button increments `recipesCooked` + streak in Firestore, switches to Instructions tab
- [x] "Add to Grocery List" button already existed — kept and working
- [x] Total time info card (`prepTime + cookTime`) added to quick-info row

**Success criteria**: Profile shows real user data, grocery list syncs automatically.

---

## Phase 2: New Features

> Goal: Add features that make SmartChef AI genuinely useful. Android + Web targeted.

### 2.1 Real AI Ingredient Detection ✅ Done

- [x] Google Cloud Vision REST API — called directly from Flutter via Dio (no Cloud Function needed)
- [x] `LABEL_DETECTION` — score ≥ 0.65 threshold + food keyword allowlist filter (~80 keywords)
- [x] `FirebaseService.analyzeImage(XFile)` — base64 encode, POST with `?key=VISION_API_KEY`
- [x] `ScanScreen` — real detection replaces mock, image compressed to 512×512px
- [x] `ScanScreen` — inline horizontal scroll row of `RecipeCard`s (no navigation to `/search`)
- [x] Users can edit/remove detected ingredient chips before searching
- [x] API key secured via `String.fromEnvironment` + gitignored `dart_defines/dev.json`
- [ ] `functions/` Cloud Function kept for optional Blaze plan upgrade in future
- [ ] Confidence scores displayed in chip UI (out of scope this phase)


### 2.3 Meal Planning Calendar

- [ ] New screen: `/meal-plan` (7-day calendar view)
- [ ] Tap a day to assign a recipe
- [ ] Auto-generate grocery list from weekly meal plan
- [ ] Persist plan to Firestore `meal_plans/{uid}`

### 2.4 Recipe Sharing (Android + Web) ✅ Done

- [x] `share_plus` is already integrated — extend with recipe URL sharing
- [x] Generate a shareable deep link per recipe (`/recipe/{id}`)
- [ ] Web: the recipe detail route already works at `/recipe/{id}` — make it load without auth for shared links
- [x] Android: share via system share sheet with recipe name + link

### 2.5 Nutrition Goal Tracking

- [ ] Add nutrition goals to user profile (daily calorie, protein, carbs, fat targets)
- [ ] Track daily intake from "meals cooked" history
- [ ] Display progress chart — add `fl_chart` package if implementing this feature
- [ ] Weekly nutrition summary view

### 2.6 Firebase Storage Integration ✅ Done

- [x] Allow users to upload a profile photo (declared in `pubspec.yaml` but not yet used)
- [x] Store photos in `Firebase Storage` under `users/{uid}/profile.jpg`
- [x] Display in `ProfileAvatar` widget

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
