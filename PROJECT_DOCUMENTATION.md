# SmartChef AI — Complete Project Documentation

> **AI-Powered Recipe Recommender with Smart Ingredient Detection**
> Version: 1.0.0 | Architecture: Firebase + Flutter | Targets: Android + Web
> Last Updated: 2026-02-23

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Implementation Status](#implementation-status)
3. [Technology Stack](#technology-stack)
4. [Architecture](#architecture)
5. [Project Structure](#project-structure)
6. [Installation & Setup](#installation--setup)
7. [APIs & External Services](#apis--external-services)
8. [Firebase Backend](#firebase-backend)
9. [Data Models](#data-models)
10. [State Management (Providers)](#state-management-providers)
11. [Navigation & Routing](#navigation--routing)
12. [Screens & Features](#screens--features)
13. [Theme System](#theme-system)
14. [Constants & Configuration](#constants--configuration)
15. [Offline Support & Caching](#offline-support--caching)
16. [Build & Deployment](#build--deployment)
17. [Known Limitations](#known-limitations)

---

## Project Overview

**SmartChef AI** is a cross-platform recipe discovery and meal planning app. Users can search 100+ recipes, scan ingredients with AI, plan weekly meals across 4 slots (breakfast/lunch/dinner/snack), track nutrition goals, and auto-generate categorized grocery lists.

### Core Capabilities

| Feature | Status | Description |
|---------|--------|-------------|
| Recipe Discovery | ✅ Complete | 100 local recipes + Firestore + TheMealDB fallback |
| AI Ingredient Scan | ✅ Complete | Google Cloud Vision API, food-only keyword filter |
| Meal Planner | ✅ Complete | 7-day, 4 slots/day, keyword-based recipe suggestions |
| Grocery Lists | ✅ Complete | Auto-categorized, recipe source tracking, Firebase sync |
| Nutrition Tracking | ✅ Complete | Daily intake from cooking, goals with progress rings |
| User Auth | ✅ Complete | Email/password + Google Sign-In + password reset |
| Favorites | ✅ Complete | Local + Firebase sync, persists across sessions |
| Profile & Settings | ✅ Complete | Photo upload, stats, dark mode, language selector |
| Dietary Preferences | ✅ Complete | 12 diet types, 10 allergies, saved to Firestore |
| Onboarding | ✅ Complete | 4-page carousel, shown once |
| Voice Search | ✅ Complete | On-device speech recognition via speech_to_text |
| Recipe Sharing | ✅ Complete | System share sheet with deep link URL |
| Dark Mode | ✅ Complete | Full theme support, persisted via SharedPreferences |
| Offline Support | ✅ Complete | Local JSON + SharedPreferences cache |

### Target Platforms

- ✅ **Android** — fully configured (`google-services.json` present)
- ✅ **Web** — fully configured (`firebase_options.dart`)
- ⚠️ **iOS/macOS/Windows/Linux** — placeholder Firebase config only (not production-ready)

---

## Implementation Status

### Phase 0: Stabilization — ✅ Complete

All bugs fixed, dead code removed, navigation migrated to GoRouter, Firestore rules hardened.

### Phase 1: Feature Completion — ✅ Complete

- Profile shows real cooking stats (recipes cooked, streak)
- Grocery list auto-syncs with Firestore on every change
- Recipe detail "Start Cooking" increments stats + logs nutrition

### Phase 2: New Features — ✅ Mostly Complete

| Feature | Status | Notes |
|---------|--------|-------|
| 2.1 AI Ingredient Detection | ✅ Done | Cloud Vision REST API, client-side |
| 2.3 Meal Planning | ✅ Done | Multi-slot (breakfast/lunch/dinner/snack), keyword classification |
| 2.4 Recipe Sharing | ✅ Done | share_plus + deep link URLs |
| 2.5 Nutrition Goals | ✅ Done | Daily calorie/macro tracking with progress UI |
| 2.6 Firebase Storage | ✅ Done | Profile photo upload/delete |
| Cloud Functions | 🔧 Built, not deployed | Kept for optional Blaze plan upgrade |

### Phase 3: Quality & Release — ⏳ Not Started

Tests, performance optimization, accessibility, app store prep, CI/CD.

---

## Technology Stack

### Frontend

| Package | Version | Purpose |
|---------|---------|---------|
| Flutter | 3.8.1+ | Cross-platform UI framework |
| Dart | 3.0+ | Programming language |
| provider | ^6.0.0 | State management (5 ChangeNotifiers) |
| go_router | ^10.0.0 | Declarative routing with ShellRoute |
| dio | ^5.3.0 | HTTP client with retry interceptor |
| shared_preferences | ^2.2.0 | Key-value local storage |
| cached_network_image | ^3.3.0 | Image loading & disk cache |
| speech_to_text | ^7.3.0 | On-device voice recognition |
| image_picker | ^1.0.0 | Camera & gallery access |
| google_fonts | ^6.2.1 | Poppins font (runtime loading) |
| share_plus | ^7.2.0 | System share sheet |
| url_launcher | ^6.3.0 | Open URLs / mailto / Play Store |
| permission_handler | ^11.4.0 | Runtime permission requests |

### Backend (Firebase)

| Service | Purpose |
|---------|---------|
| Cloud Firestore | NoSQL database — recipes, users, grocery lists, meal plans, nutrition goals |
| Firebase Auth | Email/password + Google Sign-In |
| Firebase Storage | Profile photo uploads (`users/{uid}/avatar.jpg`, 5MB limit) |
| Firebase Hosting | Web deployment (configured, not actively used) |

### External APIs

| API | Purpose | Auth | Rate Limit |
|-----|---------|------|------------|
| Google Cloud Vision | Ingredient detection from photos | API key via `dart_defines/dev.json` | 1,000 calls/month free |
| TheMealDB | Recipe data fallback source | None (free API) | Unlimited |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                          │
│  ┌─────────────┐  ┌───────────────┐  ┌──────────────────┐   │
│  │  Screens     │  │  Providers    │  │  Shared Widgets  │   │
│  │  (13 feat.)  │←→│  (5 notif.)   │  │  (barrel export) │   │
│  └──────┬───────┘  └───────┬───────┘  └──────────────────┘   │
│         │                  │                                 │
│         └────────┬─────────┘                                 │
│                  ▼                                            │
│         ┌────────────────┐     ┌──────────────────┐          │
│         │ FirebaseService │     │  MealClassifier  │          │
│         │   (Singleton)   │     │  (Utility)       │          │
│         └───────┬─────────┘     └──────────────────┘          │
└─────────────────┼────────────────────────────────────────────┘
                  │
        ┌─────────┼──────────┬──────────────┐
        ▼         ▼          ▼              ▼
 ┌──────────┐ ┌────────┐ ┌──────────┐ ┌──────────────┐
 │ Firestore│ │  Auth  │ │ Storage  │ │ Cloud Vision │
 │(Database)│ │(Users) │ │(Photos)  │ │  (Scan API)  │
 └──────────┘ └────────┘ └──────────┘ └──────────────┘
                                            │
                                      ┌─────┴─────┐
                                      │ TheMealDB  │
                                      │ (Fallback) │
                                      └────────────┘
```

### Design Principles

1. **Offline-First** — Local JSON loads instantly, Firestore syncs in background
2. **Singleton Service** — Single `FirebaseService` instance manages all backend calls
3. **Immutable Models** — All models use `copyWith()` for safe state updates
4. **Graceful Degradation** — 3-layer fallback: Firestore → TheMealDB → local JSON
5. **Centralized Constants** — All strings, keys, and URLs in `lib/app/constants.dart`

---

## Project Structure

```
smartchefai/
├── lib/
│   ├── main.dart                         # App entry, Firebase init, MultiProvider (5 providers)
│   ├── firebase_options.dart             # Generated Firebase config
│   │
│   ├── app/
│   │   ├── constants.dart                # PrefKeys, AppUrls, AppMeta
│   │   ├── routes.dart                   # GoRouter: ShellRoute + auth redirect
│   │   └── theme/
│   │       ├── theme.dart                # Barrel export
│   │       ├── app_colors.dart           # AppColors constants
│   │       ├── app_typography.dart        # AppTypography (Poppins via google_fonts)
│   │       ├── app_spacing.dart          # AppSpacing constants + Gap widget
│   │       └── app_theme.dart            # ThemeData (light + dark)
│   │
│   ├── features/                          # Feature-first screen organization
│   │   ├── auth/
│   │   │   ├── get_started_screen.dart   # Welcome/landing page
│   │   │   ├── login_screen.dart         # Email + Google sign-in
│   │   │   ├── signup_screen.dart        # Registration with name/email/password
│   │   │   └── forgot_password_screen.dart # Password reset
│   │   ├── home/home_screen.dart          # Main feed, categories, nutrition card
│   │   ├── search/search_screen.dart      # Text + voice search, recent searches
│   │   ├── recipe_detail/recipe_detail_screen.dart  # Full recipe view (3 tabs)
│   │   ├── favorites/favorites_screen.dart # Bookmarked recipes grid
│   │   ├── planner/planner_screen.dart    # Meal plan + grocery tabs
│   │   ├── meal_plan/meal_plan_screen.dart # Redirects to /planner
│   │   ├── grocery/grocery_list_screen.dart # Standalone grocery screen
│   │   ├── profile/profile_screen.dart    # Settings, stats, photo, dietary prefs
│   │   ├── scan/scan_screen.dart          # AI ingredient detection
│   │   ├── onboarding/onboarding_screen.dart # 4-page first-run tour
│   │   └── dietary_preferences/dietary_preferences_screen.dart
│   │
│   ├── shared/widgets/                    # Reusable components
│   │   ├── widgets.dart                   # Barrel export
│   │   ├── recipe_card.dart              # RecipeCard with image, meta chips
│   │   ├── common_widgets.dart           # Gap, SettingsCard, SettingsTile, etc.
│   │   ├── ingredient_nutrition_widgets.dart # IngredientTile, GroceryItemTile
│   │   ├── navigation_widgets.dart       # AppBottomNavBar, MainShell
│   │   └── nutrition_goals_card.dart     # NutritionGoalsCard with progress rings
│   │
│   ├── utils/
│   │   └── meal_classifier.dart          # Keyword-based recipe → meal slot sorting
│   │
│   ├── models/models.dart                 # All data models (barrel file)
│   │
│   ├── providers/
│   │   ├── app_providers.dart            # Re-exports all providers
│   │   ├── firebase_providers.dart       # RecipeProvider, UserProvider, GroceryListProvider
│   │   ├── meal_plan_provider.dart       # MealPlanProvider
│   │   └── nutrition_provider.dart       # NutritionProvider
│   │
│   └── services/
│       └── firebase_service.dart         # Singleton: Firestore, Auth, Storage, Vision, TheMealDB
│
├── data/
│   └── recipes.json                      # 100 local recipes (instant loading)
│
├── assets/
│   └── icons/google_logo.png             # Google Sign-In button logo
│
├── dart_defines/
│   ├── dev.json                          # gitignored — contains VISION_API_KEY
│   └── dev.json.example                  # Template for new developers
│
├── functions/                             # Cloud Functions (TypeScript, NOT deployed)
│   └── src/
│       ├── index.ts                      # analyzeIngredients HTTP function
│       └── ingredientFilter.ts           # Food keyword allowlist
│
├── firestore.rules                       # Security rules (owner-only access)
├── firestore.indexes.json                # Custom indexes (currently empty)
├── storage.rules                         # Storage rules (5MB limit, images only)
├── firebase.json                         # Firebase project config
├── pubspec.yaml                          # Flutter dependencies
└── analysis_options.yaml                 # Dart lint rules
```

---

## Installation & Setup

### Prerequisites

- Flutter SDK ≥ 3.8.1
- Dart SDK ≥ 3.0
- Firebase CLI (`npm install -g firebase-tools`)
- Android Studio or VS Code

### Quick Start

```bash
# 1. Clone and install
git clone <repo-url>
cd smartchefai
flutter pub get

# 2. Configure Vision API key
cp dart_defines/dev.json.example dart_defines/dev.json
# Edit dev.json — add your VISION_API_KEY

# 3. Run the app
flutter run --dart-define-from-file=dart_defines/dev.json

# VS Code: press F5 (launch.json is pre-configured)
```

### Vision API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select project `smartchefai-344c5`
3. Enable **Cloud Vision API**
4. Create an API key (restrict to Vision API)
5. Paste key into `dart_defines/dev.json` as `VISION_API_KEY`
6. Free tier: 1,000 calls/month

---

## APIs & External Services

### 1. Google Cloud Vision API

**Purpose**: Detect food ingredients from camera/gallery photos.

**How it works**:
1. User captures or selects a photo in `ScanScreen`
2. Image is compressed to 512×512px, quality 85
3. Base64-encoded and sent to Vision REST API via Dio
4. `LABEL_DETECTION` returns labels with confidence scores
5. Labels filtered through food keyword allowlist (~80+ keywords: vegetables, fruits, proteins, dairy, grains, herbs, spices)
6. Only labels with confidence ≥ 0.65 are kept
7. Results shown as editable chips; user searches recipes by detected ingredients

**Endpoint**: `https://vision.googleapis.com/v1/images:annotate?key={VISION_API_KEY}`

**Auth**: API key passed via `--dart-define-from-file` (never committed to git)

**Code**: `FirebaseService.analyzeImage(XFile)` → returns `List<DetectedIngredient>`

### 2. TheMealDB API

**Purpose**: Fallback recipe data source when Firestore is empty or unavailable.

**How it works**:
1. If Firestore `recipes` collection is empty, fetches from TheMealDB
2. Converts TheMealDB JSON format → internal `Recipe` model
3. Parses up to 20 ingredients per recipe (TheMealDB format: `strIngredient1`..`strIngredient20`)
4. Also used for recipe search by name/ingredient

**Base URL**: `https://www.themealdb.com/api/json/v1/1`

**Endpoints used**:
- `/search.php?s={query}` — search by name
- `/filter.php?i={ingredient}` — filter by ingredient
- `/lookup.php?i={id}` — get recipe by ID

**Auth**: None (free public API)

**Code**: Internal to `FirebaseService` — `_fetchFromTheMealDB()`, `_convertMealDbRecipe()`

### 3. Firebase Auth

**Purpose**: User authentication.

**Methods implemented**:
- `signInWithEmail(email, password)` — email/password login
- `registerWithEmail(email, password, name)` — creates account + Firestore profile
- `signInWithGoogle()` — OAuth flow via `google_sign_in` package
- `sendPasswordResetEmail(email)` — password reset
- `signOut()` — signs out of Firebase + Google

**Code**: `FirebaseService` methods, consumed by `UserProvider`

### 4. Firebase Cloud Firestore

**Purpose**: Primary database for all persistent data.

**Collections**:

| Collection | Document ID | Fields | Access |
|-----------|-------------|--------|--------|
| `recipes` | auto-generated | name, ingredients[], steps[], nutrition{}, cuisine, difficulty, prepTime, cookTime, servings, imageUrl, dietaryTags[], rating | Read: all; Write: admin only |
| `users` | `{uid}` | name, email, dietaryPreferences[], allergies[], favoriteRecipes[], searchHistory[], recipesCooked, currentStreak, lastCookedDate, photoUrl, createdAt | Read/Write: owner only |
| `grocery_lists` | auto-generated | userId, name, items[], recipes[], createdAt, status | Read/Write: owner only |
| `meal_plans` | `{uid}` | userId, days{mon-sun → {breakfast, lunch, dinner, snack → recipeId}}, weekStart, updatedAt | Read/Write: owner only |
| `nutrition_goals` | `{uid}` | userId, dailyCalories, dailyProtein, dailyCarbs, dailyFat | Read/Write: owner only |

**Offline persistence**: Enabled via `firebaseFirestore.settings = Settings(persistenceEnabled: true)`

### 5. Firebase Storage

**Purpose**: Profile photo storage.

**Path pattern**: `users/{uid}/avatar.jpg`

**Constraints** (enforced by storage.rules):
- Max file size: 5 MB
- Content type: `image/*` only
- Access: owner only (read + write)

**Code**: `FirebaseService.uploadProfilePhoto(XFile)`, `removeProfilePhoto()`

---

## Firebase Backend

### Project Details

- **Project ID**: `smartchefai-344c5`
- **Plan**: Spark (free tier)
- **Configured platforms**: Android + Web
- **Cloud Functions**: Built but NOT deployed (requires Blaze plan)

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /recipes/{recipeId} {
      allow read: if true;
      allow write: if false;  // admin-only via console
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /grocery_lists/{listId} {
      allow read, update, delete: if request.auth != null
        && resource.data.user_id == request.auth.uid;
      allow create: if request.auth != null;
    }
    match /meal_plans/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /nutrition_goals/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

---

## Data Models

All models are in `lib/models/models.dart`. Every model has: `const` constructor, named parameters, `copyWith()`, `fromJson()`/`toJson()`.

### Recipe

```dart
class Recipe {
  final String id;                    // 'local-001' or Firestore ID
  final String name;                  // 'Spaghetti Carbonara'
  final List<String> ingredients;     // ['spaghetti 400g', 'eggs 4', ...]
  final List<String> steps;           // ['Boil pasta...', ...]
  final int prepTime;                 // minutes
  final int cookTime;                 // minutes
  final String difficulty;            // 'easy', 'medium', 'hard'
  final String cuisine;               // 'Italian', 'Thai', etc.
  final List<String> dietaryTags;     // ['vegetarian', 'gluten-free']
  final Nutrition nutrition;
  final int servings;                 // default 4
  final String imageUrl;              // TheMealDB CDN URL
  final double? rating;               // 0.0 - 5.0
  final double? similarityScore;      // used in ingredient search ranking
}
```

### Nutrition

```dart
class Nutrition {
  final int calories;        // 450
  final String protein;      // '18g'
  final String carbs;        // '55g'
  final String fat;          // '16g'
  final String fiber;        // '2g'
}
```

### AppUser

```dart
class AppUser {
  final String id;                          // Firebase UID
  final String name;
  final String email;
  final List<String> dietaryPreferences;    // ['vegetarian', 'gluten-free']
  final List<String> allergies;             // ['peanuts', 'shellfish']
  final List<String> favoriteRecipes;       // recipe IDs
  final List<String> searchHistory;         // recent queries
  final int recipesCooked;                  // lifetime count
  final int currentStreak;                  // consecutive days
  final DateTime? lastCookedDate;
  final String? photoUrl;                   // Firebase Storage URL
  final DateTime createdAt;
}
```

### MealPlan

```dart
class MealPlan {
  final String userId;
  final Map<String, Map<String, String?>> days;
  // Structure: { 'monday': { 'breakfast': 'recipe-id', 'lunch': null, ... }, ... }
  final DateTime weekStart;
  final DateTime updatedAt;

  static const List<String> dayNames = ['monday', 'tuesday', ...];
  static const List<String> mealSlots = ['breakfast', 'lunch', 'dinner', 'snack'];
}
```

**Backward compatibility**: `fromFirestore()` handles 3 formats:
1. New multi-slot: `Map<String, Map<String, String?>>` ✅
2. Legacy single-recipe: `String` per day → migrated to dinner slot
3. Null → empty slots

### NutritionGoals

```dart
class NutritionGoals {
  final String userId;
  final int dailyCalories;    // default 2000
  final int dailyProtein;     // default 50
  final int dailyCarbs;       // default 250
  final int dailyFat;         // default 65
}
```

### GroceryItem

```dart
class GroceryItem {
  final String name;
  final double quantity;       // default 1.0
  final String unit;           // 'g', 'ml', 'cups', etc.
  final String category;       // 'produce', 'dairy', 'meat', etc.
  final bool checked;
  final List<String> recipes;  // which recipes this item came from
}
```

### DetectedIngredient

```dart
class DetectedIngredient {
  final String name;           // 'tomato'
  final double confidence;     // 0.0 - 1.0
  final BoundingBox? bbox;     // optional detection coordinates
}
```

---

## State Management (Providers)

Five `ChangeNotifier` providers, registered in `main.dart` via `MultiProvider`.

### RecipeProvider (`firebase_providers.dart`)

**State**: `_recipes[]`, `_favorites[]`, `_favoriteIds{}`, `_currentRecipe`, `_isLoading`, `_error`

| Method | Description |
|--------|-------------|
| `loadRecipes()` | Two-phase: local JSON instant → Firestore background (5s timeout) |
| `searchRecipes(query)` | Full-text search by name, cuisine, ingredients (limit: 50) |
| `searchByIngredients(list)` | Filters by detected ingredients with similarity scoring |
| `toggleFavorite(id)` | Optimistic local update + Firebase sync |
| `isFavorite(id)` | Check if recipe is bookmarked |

**Persistence**: Favorite IDs saved to SharedPreferences (`PrefKeys.favoriteIds`) for offline access.

### UserProvider (`firebase_providers.dart`)

**State**: `_appUser`, `_isDarkMode`, `_notificationsEnabled`, `_selectedLanguage`, `_isLoading`, `_error`, `_isUploadingPhoto`

| Method | Description |
|--------|-------------|
| `createUser(name, email)` | Register new Firestore profile |
| `login(email, password)` | Email/password sign-in |
| `loginWithGoogle()` | Google OAuth sign-in |
| `logout()` | Sign out, clear state |
| `resetPassword(email)` | Send password reset email |
| `toggleDarkMode()` | Toggle + persist to SharedPreferences |
| `setNotifications(bool)` | Toggle + persist |
| `setLanguage(string)` | Change language + persist |
| `setPreferences(diets, allergies)` | Update dietary prefs in Firestore |
| `incrementRecipesCooked()` | Update cooking stats |
| `uploadPhoto(XFile)` | Upload to Firebase Storage |
| `removePhoto()` | Delete from Firebase Storage |
| `loadThemePreference()` | Read dark mode from SharedPreferences on startup |

### GroceryListProvider (`firebase_providers.dart`)

**State**: `_items[]`, `_cloudListId`, `_isLoading`, `_error`

| Method | Description |
|--------|-------------|
| `addItem(GroceryItem)` | Add (deduplicate by name) |
| `removeItem(index)` | Remove by index |
| `toggleItem(index)` | Toggle checked via `copyWith` |
| `clearChecked()` | Remove all checked items |
| `clearAll()` | Remove all items |
| `addRecipeIngredients(recipe)` | Parse recipe ingredients → grocery items |
| `syncOnLogin()` | Merge local + cloud items |
| `importFromCloud(listId)` | Import a saved cloud list |
| `saveToCloud()` | Create/update cloud list |
| `deleteCloudList(id)` | Delete from Firestore |

**Persistence**: Items stored as JSON in SharedPreferences (`PrefKeys.groceryItems`). Cloud sync via Firestore `grocery_lists` collection.

### MealPlanProvider (`meal_plan_provider.dart`)

**State**: `_mealPlan`, `_assignedRecipes{}`, `_isLoading`

| Method | Description |
|--------|-------------|
| `loadMealPlan()` | Fetch from Firestore `meal_plans/{uid}` |
| `assignRecipe(day, slot, recipe)` | Set recipe in day/slot (e.g., 'monday'/'breakfast') |
| `removeRecipe(day, slot)` | Clear a slot |
| `clearDay(day)` | Clear all slots for a day |
| `clearAll()` | Reset entire week |
| `generateGroceryItems()` | Iterate all slots → return categorized `GroceryItem` list |

**Ingredient categorization**: `_categorizeIngredient(name)` uses keyword lists to assign categories (Produce, Dairy, Meat & Seafood, Bakery, Spices & Herbs, Pantry).

### NutritionProvider (`nutrition_provider.dart`)

**State**: `_goals`, `_todayMeals[]`

| Method | Description |
|--------|-------------|
| `loadGoals()` | Fetch from Firestore `nutrition_goals/{uid}` |
| `setGoals(goals)` | Save daily targets to Firestore |
| `loadTodayIntake()` | Read today's meal log from SharedPreferences |
| `logRecipe(recipe)` | Add recipe's nutrition to today's intake |

**Computed getters**: `todayCalories`, `todayProtein`, `todayCarbs`, `todayFat` — sum of all logged meals today.

**Persistence**: Daily meal log stored in SharedPreferences with key `nutrition_log_YYYY-MM-DD`.

---

## Navigation & Routing

### GoRouter with ShellRoute

```dart
GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Sync auth check — unauthenticated → /get-started
    // Exception: /recipe/:id is publicly accessible (shared links)
  },
  routes: [
    // Auth routes (no bottom nav)
    GoRoute(path: '/get-started', ...),
    GoRoute(path: '/login', ...),
    GoRoute(path: '/signup', ...),
    GoRoute(path: '/forgot-password', ...),
    GoRoute(path: '/onboarding', ...),

    // Main shell (persistent bottom nav)
    ShellRoute(
      builder: → MainShell (5-tab bottom nav),
      routes: [
        '/'         → HomeScreen,
        '/search'   → SearchScreen,
        '/planner'  → PlannerScreen,
        '/profile'  → ProfileScreen,
      ],
    ),

    // Full-screen routes (no bottom nav)
    GoRoute(path: '/scan', ...),
    GoRoute(path: '/grocery', ...),
    GoRoute(path: '/meal-plan', ...),         // Redirects to /planner
    GoRoute(path: '/favorites', ...),
    GoRoute(path: '/dietary-preferences', ...),
    GoRoute(path: '/recipe/:id', ...),        // Public (no auth required)
  ],
);
```

### Bottom Navigation Bar

5 tabs: **Home** | **Search** | **Scan** (center camera button) | **Planner** | **Profile**

---

## Screens & Features

### Authentication Flow

1. **GetStartedScreen** — Welcome page with hero image, app overview, "Get Started" CTA
2. **LoginScreen** — Email + password fields, "Forgot Password?" link, Google Sign-In button
3. **SignupScreen** — Name + email + password + confirm password, creates Firestore profile
4. **ForgotPasswordScreen** — Email input, sends Firebase password reset email

### HomeScreen

- Personalized greeting (Good Morning/Afternoon/Evening + user name)
- **NutritionGoalsCard** — 4 circular progress rings (Calories, Protein, Carbs, Fat), tap settings to edit goals
- Category chips (10 cuisine categories) — tap to filter recipes
- All 100 recipes displayed in 2-column grid
- Tap recipe → pushes `/recipe/:id`

### SearchScreen

- Text search field (does NOT auto-focus keyboard)
- Voice search button (speech_to_text)
- Recent searches from Firestore (themed for light/dark mode)
- Search results grid (up to 50 results)
- Searches by name, cuisine, and ingredients

### RecipeDetailScreen

- Hero image with gradient overlay
- Quick info row: prep time, cook time, difficulty, servings
- Favorite toggle button, share button
- **3 tabs** (NestedScrollView + pinned TabBar):
  1. **Ingredients** — Servings adjuster, ingredient list with "Add to Grocery" button
  2. **Instructions** — Numbered step-by-step list, "Start Cooking" button (logs nutrition + increments stats)
  3. **Nutrition** — Calorie/protein/carbs/fat/fiber cards in scrollable ListView
- "Add to Meal Plan" bottom sheet: two-step day → slot picker

### PlannerScreen (2 tabs)

**Meal Plan Tab**:
- 7 expandable day cards (Monday–Sunday)
- Each day has 4 meal slots: Breakfast, Lunch, Dinner, Snack
- Tap empty slot → recipe picker bottom sheet with "Suggested" section headers
- Recipe suggestions use keyword-based classification (`MealClassifier`)

**Grocery Tab**:
- Items grouped by category (Produce, Dairy & Eggs, Meat & Seafood, Bakery, Spices & Herbs, Pantry)
- Each category has icon + item count header
- Items show name, quantity, and recipe source (italic subtitle)
- "Generate from Meal Plan" button creates items from assigned recipes

### ScanScreen

1. Camera capture or gallery selection
2. Image sent to Cloud Vision API
3. Detected ingredients shown as removable chips
4. "Find Recipes" button searches by detected ingredients
5. Results shown inline as horizontal recipe card scroll

### ProfileScreen

- Avatar (Firestore photo or initials circle), user name, email
- Cooking stats: Recipes Cooked, Current Streak, Member Since
- **Settings sections**: Account (dietary prefs), Appearance (dark mode), Notifications, Language
- **Support section**: Help & FAQ, Send Feedback, Rate the App, About (version from AppMeta)
- Logout button

### OnboardingScreen

- 4-page `PageView`: Discover Recipes, Smart Detection, Voice Search, Personalized Experience
- Skip button + page indicators
- Completes: sets `PrefKeys.onboardingComplete` in SharedPreferences, navigates to `/`

### DietaryPreferencesScreen

- 12 diet types: Vegetarian, Vegan, Gluten-Free, Dairy-Free, Low-Carb, Keto, Paleo, Pescatarian, Halal, Kosher, Low-Sodium, High-Protein
- 10 common allergies: Peanuts, Tree Nuts, Milk, Eggs, Wheat, Soy, Fish, Shellfish, Sesame, Mustard
- Toggle chips, saves to Firestore via `UserProvider.setPreferences()`

---

## Theme System

### Colors (`AppColors`)

| Constant | Value | Usage |
|----------|-------|-------|
| `primaryOrange` | `#FF6B35` | Primary actions, buttons, highlights |
| `primaryOrangeDark` | `#E55B2B` | Pressed states, gradients |
| `accentGreen` | `#4CAF50` | Success states, checked items |
| `accentYellow` | `#FFB800` | Warnings, ratings |
| `backgroundLight` | `#FAFAFA` | Light theme background |
| `backgroundDark` | `#121212` | Dark theme background |

### Spacing (`AppSpacing`)

| Constant | Value | Usage |
|----------|-------|-------|
| `xxs` | 4.0 | Tiny gaps |
| `xs` | 8.0 | Small gaps |
| `sm` | 12.0 | Component internal padding |
| `md` | 16.0 | Standard spacing |
| `lg` | 24.0 | Section gaps |
| `xl` | 32.0 | Large section gaps |
| `xxl` | 48.0 | Page-level spacing |

Also provides: `paddingXs`, `paddingSm`, `paddingMd`, etc. and `Gap` widget (`Gap.sm()`, `Gap.md()`, etc.)

### Typography (`AppTypography`)

Uses **Poppins** font (loaded at runtime via `google_fonts`). Styles follow Material 3 type scale.

---

## Constants & Configuration

### `lib/app/constants.dart`

```dart
// SharedPreferences keys — never use raw strings
abstract final class PrefKeys {
  static const String favoriteIds = 'favorite_ids';
  static const String onboardingComplete = 'onboarding_complete';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String selectedLanguage = 'selected_language';
  static const String darkMode = 'dark_mode';
  static const String activeGroceryListId = 'active_grocery_list_id';
  static const String groceryItems = 'grocery_items';
}

// External URLs
abstract final class AppUrls {
  static const String helpAndFaq = 'https://smartchefai.web.app/help';
  static const String feedbackEmail = 'mailto:feedback@smartchef.ai?...';
  static const String playStore = 'https://play.google.com/store/apps/...';
  static String recipeShareUrl(String id) => '$webBase/recipe/$id';
}

// App-level metadata
abstract final class AppMeta {
  static const String appName = 'SmartChef AI';
  static const String version = '1.0.0';
  static const String defaultLanguage = 'English';
  static const List<String> supportedLanguages = [...];
}
```

---

## Offline Support & Caching

### Three-Layer Caching Strategy

| Layer | Data | TTL | Storage |
|-------|------|-----|---------|
| **Local JSON** | 100 recipes | Permanent | `data/recipes.json` (bundled with app) |
| **In-Memory Cache** | All recipes | 30 minutes | `FirebaseService._cachedRecipes` |
| **Firestore Offline** | All collections | Until sync | Firestore SDK persistence |

### Recipe Loading (Two-Phase)

1. **Phase 1 (instant)**: Load 100 recipes from local `data/recipes.json` → UI renders immediately
2. **Phase 2 (background)**: Fetch from Firestore with 5-second timeout → merge with local recipes
3. **Fallback**: If both fail, UI still shows local recipes

### SharedPreferences Cache

| Key | Data Cached |
|-----|-------------|
| `favorite_ids` | Set of favorite recipe IDs |
| `grocery_items` | Full grocery list as JSON array |
| `active_grocery_list_id` | Current cloud grocery list ID |
| `dark_mode` | Theme preference |
| `onboarding_complete` | First-run flag |
| `notifications_enabled` | Notification toggle |
| `selected_language` | UI language |
| `nutrition_log_YYYY-MM-DD` | Daily nutrition intake log |

---

## Build & Deployment

### Development

```bash
# Always include Vision API key
flutter run --dart-define-from-file=dart_defines/dev.json

# Web
flutter run -d chrome --dart-define-from-file=dart_defines/dev.json

# Code quality
dart analyze lib/     # Must pass with 0 issues
dart format lib/      # Auto-format
```

### Release Builds

```bash
# Android APK
flutter build apk --release --dart-define-from-file=dart_defines/dev.json

# Android App Bundle (Play Store)
flutter build appbundle --release --dart-define-from-file=dart_defines/dev.json

# Web
flutter build web --release --dart-define-from-file=dart_defines/dev.json
firebase deploy --only hosting
```

### Firebase Deployment

```bash
# Deploy Firestore rules + indexes
firebase deploy --only firestore

# Deploy Storage rules
firebase deploy --only storage

# Deploy web app
firebase deploy --only hosting

# Cloud Functions (requires Blaze plan)
# firebase deploy --only functions
```

---

## Known Limitations

| Area | Limitation | Workaround |
|------|-----------|------------|
| Cloud Functions | Not deployed (Spark plan) | Vision API called client-side |
| iOS/macOS/Windows | Placeholder Firebase config | Only Android + Web are production-ready |
| Firestore Indexes | None configured | Simple queries only; may need indexes for complex filters |
| App ID | `com.example.smartchefai` | Must change before Play Store submission |
| Tests | None (stale tests removed) | Phase 3 roadmap item |
| Recipe Count | 100 local recipes | Expandable via Firestore or larger JSON |
| Vision API | 1,000 free calls/month | Upgrade billing for higher volume |
| Multilingual | Language selector exists but UI is English-only | Internationalization is a backlog item |
| Profile Photo | Works only with Firebase Storage | Requires Spark → Blaze for production scale |

---

*Last updated: 2026-02-23 | SmartChef AI v1.0.0 | Targets: Android + Web*
