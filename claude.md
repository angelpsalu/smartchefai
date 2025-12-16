# SmartChef AI - Project Documentation

> **AI-Powered Recipe Recommender with Smart Ingredient Detection**

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Theme System](#theme-system)
5. [Navigation](#navigation)
6. [State Management](#state-management)
7. [API Integration](#api-integration)
8. [Features](#features)
9. [Screens](#screens)
10. [Widgets](#widgets)
11. [Models](#models)
12. [Quick Start](#quick-start)
13. [Future Enhancements](#future-enhancements)

---

## 🎯 Project Overview

SmartChef AI is a personalized recipe recommendation application that uses AI-powered features to help users discover, plan, and cook meals. The app supports:

- **Text Search**: Traditional recipe search by name, ingredient, or cuisine
- **Voice Input**: Hands-free recipe search using speech recognition
- **Camera Scan**: AI-powered ingredient detection from photos
- **Smart Recommendations**: Personalized suggestions based on preferences
- **Grocery Management**: Auto-generate shopping lists from recipes
- **Nutrition Tracking**: Calorie and macro information for recipes

### Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.x (Dart) |
| State Management | Provider + ChangeNotifier |
| Navigation | GoRouter |
| API | TheMealDB (Free, Unlimited) |
| Local Storage | SharedPreferences + Hive |
| Voice Input | speech_to_text (On-device) |
| Image Handling | image_picker + cached_network_image |
| Animations | flutter_animate |

---

## 🏗 Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│          Presentation Layer         │
│  (Screens, Widgets, Providers)      │
├─────────────────────────────────────┤
│           Domain Layer              │
│     (Models, Business Logic)        │
├─────────────────────────────────────┤
│            Data Layer               │
│   (API Service, Local Storage)      │
└─────────────────────────────────────┘
```

### Design Principles

- **Feature-First Organization**: Each feature in its own folder
- **Separation of Concerns**: UI, Business Logic, and Data separated
- **Reusable Components**: Shared widgets used across screens
- **Theme Centralization**: All styling in one place

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── app/
│   ├── routes.dart              # GoRouter configuration
│   └── theme/
│       ├── theme.dart           # Barrel export
│       ├── app_colors.dart      # Color system
│       ├── app_typography.dart  # Text styles
│       ├── app_spacing.dart     # Spacing constants
│       └── app_theme.dart       # ThemeData config
├── features/
│   ├── home/
│   │   └── home_screen.dart
│   ├── search/
│   │   └── search_screen.dart
│   ├── recipe_detail/
│   │   └── recipe_detail_screen.dart
│   ├── favorites/
│   │   └── favorites_screen.dart
│   ├── grocery/
│   │   └── grocery_list_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── scan/
│   │   └── scan_screen.dart
│   └── onboarding/
│       └── onboarding_screen.dart
├── shared/
│   └── widgets/
│       ├── widgets.dart         # Barrel export
│       ├── recipe_card.dart     # Recipe cards
│       ├── common_widgets.dart  # Buttons, search bar, etc.
│       ├── ingredient_nutrition_widgets.dart
│       └── navigation_widgets.dart
├── models/
│   └── models.dart              # Data models
├── providers/
│   └── app_providers.dart       # State management
└── services/
    └── api_service.dart         # HTTP client
```

---

## 🎨 Theme System

### Color Palette

```dart
// Primary Colors
primaryOrange: Color(0xFFFF6B35)    // Main accent
primaryOrangeDark: Color(0xFFE55B2B) // Dark variant

// Accent Colors
accentGreen: Color(0xFF4CAF50)      // Success, nutrition
accentYellow: Color(0xFFFFB800)     // Ratings, warnings

// Gradients
primaryGradient: LinearGradient(
  colors: [primaryOrange, primaryOrangeDark]
)
```

### Typography Scale

| Style | Size | Weight | Use Case |
|-------|------|--------|----------|
| displayLarge | 57px | Bold | Hero text |
| headlineLarge | 32px | SemiBold | Page titles |
| titleLarge | 22px | SemiBold | Section headers |
| bodyLarge | 16px | Regular | Main content |
| labelLarge | 14px | Medium | Buttons, chips |

### Spacing System

```dart
xxs: 4.0    // Micro spacing
xs: 8.0     // Small spacing
sm: 12.0    // Component padding
md: 16.0    // Section spacing
lg: 24.0    // Large gaps
xl: 32.0    // Section dividers
xxl: 48.0   // Page padding
xxxl: 64.0  // Hero spacing
```

### Usage

```dart
import 'app/theme/theme.dart';

// Colors
AppColors.primaryOrange
AppColors.primaryGradient

// Spacing
AppSpacing.paddingMd        // EdgeInsets.all(16)
AppSpacing.borderRadiusLg   // BorderRadius(16)
Gap.md()                    // SizedBox(height: 16)
HGap.sm()                   // SizedBox(width: 12)
```

---

## 🧭 Navigation

### GoRouter Setup

```dart
// Routes defined in lib/app/routes.dart
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => HomeScreen()),
    GoRoute(path: '/search', builder: (_, __) => SearchScreen()),
    GoRoute(path: '/recipe/:id', builder: (_, state) => RecipeDetailScreen()),
    GoRoute(path: '/favorites', builder: (_, __) => FavoritesScreen()),
    GoRoute(path: '/grocery', builder: (_, __) => GroceryListScreen()),
    GoRoute(path: '/profile', builder: (_, __) => ProfileScreen()),
    GoRoute(path: '/scan', builder: (_, __) => ScanScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => OnboardingScreen()),
  ],
);
```

### Navigation Examples

```dart
// Using GoRouter
context.go('/search');
context.go('/recipe/123', extra: recipe);
context.push('/scan');

// Using extension
context.goToRecipe(recipe);
context.goToSearch(query: 'chicken');
```

---

## 📊 State Management

### Providers

#### RecipeProvider

```dart
class RecipeProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = false;

  Future<void> loadRecipes() async { ... }
  Future<void> searchRecipes(String query) async { ... }
  void toggleFavorite(String id) { ... }
  bool isFavorite(String id) => _favoriteIds.contains(id);
}
```

#### UserProvider

```dart
class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isDarkMode = false;
  
  void toggleDarkMode() { ... }
  Future<void> loadUserPreferences() async { ... }
}
```

#### GroceryListProvider

```dart
class GroceryListProvider extends ChangeNotifier {
  List<GroceryItem> _items = [];
  
  void addItem(GroceryItem item) { ... }
  void removeItem(String id) { ... }
  void toggleItem(String id) { ... }
  void clearCheckedItems() { ... }
}
```

### Usage in Widgets

```dart
// Reading state
final recipes = context.watch<RecipeProvider>().recipes;

// Calling actions
context.read<RecipeProvider>().searchRecipes('pasta');
```

---

## 🌐 API Integration

### TheMealDB API

**Base URL**: `https://www.themealdb.com/api/json/v1/1`

| Endpoint | Description |
|----------|-------------|
| `/search.php?s={name}` | Search by name |
| `/filter.php?c={category}` | Filter by category |
| `/filter.php?a={area}` | Filter by cuisine |
| `/random.php` | Get random recipe |
| `/lookup.php?i={id}` | Get recipe by ID |

### ApiService Implementation

```dart
class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://www.themealdb.com/api/json/v1/1',
  ));

  Future<List<Recipe>> searchRecipes(String query) async {
    final response = await _dio.get('/search.php', 
      queryParameters: {'s': query}
    );
    return _parseRecipes(response.data);
  }
}
```

---

## ✨ Features

### 1. Home Screen
- Personalized greeting
- Quick category access
- Featured recipes carousel
- Popular recipes grid

### 2. Smart Search
- Text input with instant results
- Voice search with speech_to_text
- Category filter chips
- Recent searches

### 3. Ingredient Scanner
- Camera capture
- Gallery selection
- AI ingredient detection (mock)
- Recipe suggestions from ingredients

### 4. Recipe Detail
- Hero image with parallax
- Ingredient list with servings adjuster
- Step-by-step instructions
- Nutrition information
- Add to grocery list

### 5. Favorites
- Save/unsave recipes
- Grid view of saved recipes
- Quick access from any screen

### 6. Grocery List
- Manual item entry
- Auto-add from recipes
- Check/uncheck items
- Clear completed

### 7. Profile
- User info display
- Dietary preferences
- App settings (dark mode, notifications)
- Stats (favorites, recipes made)

---

## 📱 Screens

| Screen | File | Route |
|--------|------|-------|
| Home | `features/home/home_screen.dart` | `/` |
| Search | `features/search/search_screen.dart` | `/search` |
| Recipe Detail | `features/recipe_detail/recipe_detail_screen.dart` | `/recipe/:id` |
| Favorites | `features/favorites/favorites_screen.dart` | `/favorites` |
| Grocery List | `features/grocery/grocery_list_screen.dart` | `/grocery` |
| Profile | `features/profile/profile_screen.dart` | `/profile` |
| Scan | `features/scan/scan_screen.dart` | `/scan` |
| Onboarding | `features/onboarding/onboarding_screen.dart` | `/onboarding` |

---

## 🧩 Widgets

### Recipe Cards

```dart
RecipeCard(
  id: recipe.id,
  title: recipe.name,
  imageUrl: recipe.imageUrl,
  cookTime: '30 min',
  difficulty: 'Medium',
  rating: 4.5,
  isFavorite: true,
  onTap: () => ...,
  onFavoriteTap: () => ...,
)
```

### Smart Search Bar

```dart
SmartSearchBar(
  hintText: 'Search recipes...',
  onSubmitted: (query) => ...,
  onVoiceTap: () => ...,
  onCameraTap: () => ...,
)
```

### Category Chips

```dart
CategoryChips(
  categories: ['Beef', 'Chicken', 'Vegetarian'],
  selectedCategory: selected,
  onSelected: (category) => ...,
)
```

### Other Widgets

- `GradientButton` - Primary CTA button
- `EmptyState` - Empty list placeholder
- `ShimmerPlaceholder` - Loading skeleton
- `IngredientChip` - Ingredient tag
- `NutritionCard` - Nutrition display
- `GroceryItemTile` - Checklist item
- `ProfileAvatar` - User avatar
- `SettingsTile` - Settings list item
- `SmartChefBottomNav` - Bottom navigation
- `SmartChefAppBar` - Custom app bar

---

## 📦 Models

### Recipe

```dart
class Recipe {
  final String id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String imageUrl;
  final int prepTime;
  final int cookTime;
  final String difficulty;
  final String cuisine;
  final String mealType;
  final NutritionInfo? nutrition;
  final double? rating;
}
```

### User

```dart
class User {
  final String id;
  final String name;
  final String email;
  final List<String> dietaryPreferences;
  final List<String> allergies;
}
```

### GroceryItem

```dart
class GroceryItem {
  final String id;
  final String name;
  final String? quantity;
  final bool checked;
}
```

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK >= 3.8.1
- Dart >= 3.0
- Android Studio / VS Code
- Device or emulator

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/smartchefai.git
cd smartchefai

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build Commands

```bash
# Development
flutter run -d chrome        # Web
flutter run -d android       # Android
flutter run -d ios           # iOS

# Release
flutter build apk --release  # Android APK
flutter build appbundle      # Android App Bundle
flutter build ios --release  # iOS
flutter build web --release  # Web
```

---

## 🔮 Future Enhancements

### Phase 2 Features

- [ ] Real AI ingredient detection with Google ML Kit
- [ ] User authentication (Firebase Auth)
- [ ] Cloud sync for favorites and preferences
- [ ] Meal planning calendar
- [ ] Recipe sharing

### Phase 3 Features

- [ ] Community recipes
- [ ] In-app cooking timer
- [ ] Shopping list sharing
- [ ] Restaurant recommendations
- [ ] Barcode scanning for packaged ingredients

---

## 📄 License

This project is licensed under the MIT License.

---

## 👥 Contributors

- **SmartChef AI Team**

---

*Last updated: 2025*
