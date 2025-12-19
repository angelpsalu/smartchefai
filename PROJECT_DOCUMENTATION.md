# SmartChef AI - Complete Project Documentation

> **AI-Powered Recipe Recommender with Smart Ingredient Detection**  
> Version: 0.1.0 | Last Updated: December 17, 2025

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Architecture](#architecture)
4. [Project Structure](#project-structure)
5. [Installation & Setup](#installation--setup)
6. [Features](#features)
7. [Frontend (Flutter)](#frontend-flutter)
   - [Theme System](#theme-system)
   - [Navigation](#navigation)
   - [State Management](#state-management)
   - [Screens](#screens)
   - [Widgets](#widgets)
   - [Models](#models)
8. [Backend (Flask)](#backend-flask)
   - [API Endpoints](#api-endpoints)
   - [Services](#services)
9. [API Integration](#api-integration)
10. [Development Guide](#development-guide)
11. [Build & Deployment](#build--deployment)
12. [Testing](#testing)
13. [Future Enhancements](#future-enhancements)
14. [Troubleshooting](#troubleshooting)
15. [License](#license)

---

## 🎯 Project Overview

**SmartChef AI** is a comprehensive mobile and web application that revolutionizes the cooking experience by providing personalized recipe recommendations, AI-powered ingredient detection, and smart meal planning capabilities.

### Key Features

- 🔍 **Smart Recipe Search**: Text and voice-powered search with instant results
- 📸 **Ingredient Detection**: AI-powered camera scan to identify ingredients
- 💝 **Favorites Management**: Save and organize favorite recipes
- 🛒 **Smart Grocery Lists**: Auto-generate shopping lists from recipes
- 📊 **Nutrition Tracking**: Detailed nutritional information for every recipe
- 👤 **User Profiles**: Personalized experience with dietary preferences
- 🌙 **Dark Mode**: Full theme customization support
- 🎨 **Modern UI**: Material 3 design with smooth animations

### Target Platforms

- ✅ Android (Mobile & Tablet)
- ✅ iOS (iPhone & iPad)
- ✅ Web (Chrome, Firefox, Safari, Edge)
- ⏳ Desktop (Windows, macOS, Linux) - Future

---

## 🛠 Technology Stack

### Frontend

| Category | Technology | Version | Purpose |
|----------|------------|---------|---------|
| Framework | Flutter | 3.8.1+ | Cross-platform UI framework |
| Language | Dart | 3.0+ | Programming language |
| State Management | Provider | 6.0.0 | Reactive state management |
| Navigation | GoRouter | 10.0.0 | Declarative routing |
| HTTP Client | Dio | 5.3.0 | Network requests |
| Local Storage | SharedPreferences | 2.2.0 | Simple key-value storage |
| Database | Hive | 2.2.3 | NoSQL local database |
| Image Caching | cached_network_image | 3.3.0 | Image loading & caching |
| Voice Input | speech_to_text | 7.3.0 | On-device speech recognition |
| Image Picker | image_picker | 1.0.0 | Camera & gallery access |
| Animations | flutter_animate | 4.1.0 | Declarative animations |
| Charts | fl_chart | 0.63.0 | Data visualization |
| Sharing | share_plus | 7.2.0 | Cross-platform sharing |

### Backend

| Category | Technology | Version | Purpose |
|----------|------------|---------|---------|
| Framework | Flask | 2.3.3 | Web framework |
| Language | Python | 3.9+ | Backend language |
| CORS | Flask-CORS | 4.0.0 | Cross-origin requests |
| Database | Firebase | - | Cloud database |
| Storage | Google Cloud Storage | 2.10.0 | File storage |
| AI/ML | TensorFlow | 2.13.0 | Machine learning |
| Computer Vision | OpenCV | 4.8.0 | Image processing |
| Object Detection | YOLOv5 | 7.0.13 | Ingredient detection |
| Deep Learning | PyTorch | 2.0.1 | Neural networks |

### External APIs

- **TheMealDB**: Free recipe database (primary data source)
- **Firebase Admin**: User authentication & cloud storage
- **Google Cloud Speech**: Voice recognition (optional)

---

## 🏗 Architecture

### System Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐        │
│  │  Android   │  │    iOS     │  │    Web     │        │
│  └────────────┘  └────────────┘  └────────────┘        │
└──────────────────────────────────────────────────────────┘
                          │
                    Flutter App
                          │
┌──────────────────────────────────────────────────────────┐
│               PRESENTATION LAYER                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │ Screens │  │ Widgets │  │  Theme  │  │  Router │   │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
└──────────────────────────────────────────────────────────┘
                          │
┌──────────────────────────────────────────────────────────┐
│                 BUSINESS LAYER                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Providers   │  │   Services   │  │    Models    │  │
│  │ (State Mgmt) │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└──────────────────────────────────────────────────────────┘
                          │
┌──────────────────────────────────────────────────────────┐
│                   DATA LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  API Client  │  │    Local     │  │   Firebase   │  │
│  │    (Dio)     │  │   Storage    │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└──────────────────────────────────────────────────────────┘
                          │
┌──────────────────────────────────────────────────────────┐
│                  BACKEND LAYER                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Flask API   │  │   AI/ML      │  │   Firebase   │  │
│  │              │  │   Services   │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└──────────────────────────────────────────────────────────┘
                          │
┌──────────────────────────────────────────────────────────┐
│              EXTERNAL SERVICES                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  TheMealDB   │  │    Google    │  │   Firebase   │  │
│  │     API      │  │    Cloud     │  │   Firestore  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└──────────────────────────────────────────────────────────┘
```

### Design Patterns

- **Provider Pattern**: State management with ChangeNotifier
- **Repository Pattern**: Data abstraction layer
- **Factory Pattern**: Model creation from JSON
- **Singleton Pattern**: API service instances
- **Observer Pattern**: Reactive UI updates
- **MVC Pattern**: Model-View-Controller separation

### Clean Architecture Principles

1. **Separation of Concerns**: Each layer has distinct responsibility
2. **Dependency Inversion**: High-level modules don't depend on low-level
3. **Single Responsibility**: Each class has one reason to change
4. **Feature-First Structure**: Code organized by feature, not type
5. **Testability**: Easy to mock and test each layer

---

## 📁 Project Structure

### Frontend Structure

```
lib/
├── main.dart                           # App entry point
│
├── app/                                # App-level configuration
│   ├── routes.dart                     # GoRouter navigation config
│   └── theme/                          # Theme system
│       ├── theme.dart                  # Barrel export
│       ├── app_colors.dart             # Color palette
│       ├── app_typography.dart         # Text styles
│       ├── app_spacing.dart            # Spacing constants
│       └── app_theme.dart              # ThemeData configuration
│
├── features/                           # Feature modules
│   ├── home/
│   │   └── home_screen.dart            # Home page
│   ├── search/
│   │   └── search_screen.dart          # Search page
│   ├── recipe_detail/
│   │   └── recipe_detail_screen.dart   # Recipe detail page
│   ├── favorites/
│   │   └── favorites_screen.dart       # Favorites page
│   ├── grocery/
│   │   └── grocery_list_screen.dart    # Grocery list page
│   ├── profile/
│   │   └── profile_screen.dart         # Profile page
│   ├── scan/
│   │   └── scan_screen.dart            # Ingredient scanner
│   └── onboarding/
│       └── onboarding_screen.dart      # First-time onboarding
│
├── shared/                             # Shared components
│   └── widgets/
│       ├── widgets.dart                # Barrel export
│       ├── recipe_card.dart            # Recipe cards
│       ├── common_widgets.dart         # Buttons, inputs, etc.
│       ├── ingredient_nutrition_widgets.dart  # Food-related widgets
│       └── navigation_widgets.dart     # Navigation components
│
├── models/                             # Data models
│   └── models.dart                     # All data models
│
├── providers/                          # State management
│   └── app_providers.dart              # All providers
│
└── services/                           # Business logic
    └── api_service.dart                # HTTP client service
```

### Backend Structure

```
backend/
├── app.py                              # Flask app entry point
├── requirements.txt                    # Python dependencies
├── populate_firestore.py               # Data migration script
│
├── models/                             # Data models
│   ├── __init__.py
│   └── database.py                     # Database schemas
│
├── routes/                             # API endpoints
│   ├── __init__.py
│   ├── recipes.py                      # Recipe endpoints
│   ├── detection.py                    # Ingredient detection
│   ├── users.py                        # User management
│   └── grocery.py                      # Grocery list endpoints
│
└── services/                           # Business logic
    ├── __init__.py
    ├── ingredient_detector.py          # AI ingredient detection
    ├── recommendation_engine.py        # Recipe recommendations
    ├── nutrition_calculator.py         # Nutrition calculation
    └── grocery_list_generator.py       # Grocery list generation
```

### Data Structure

```
data/
└── recipes.json                        # Sample recipe data
```

---

## ⚙️ Installation & Setup

### Prerequisites

```bash
# Flutter SDK
flutter --version  # Should be >= 3.8.1

# Dart SDK
dart --version     # Should be >= 3.0

# Python (for backend)
python --version   # Should be >= 3.9

# Node.js (optional, for web deployment)
node --version     # Should be >= 16.0
```

### Frontend Setup

```bash
# 1. Clone the repository
git clone https://github.com/angelpsalu/smartchefai.git
cd smartchefai

# 2. Install Flutter dependencies
flutter pub get

# 3. Check for issues
flutter doctor

# 4. Run the app
flutter run -d chrome           # For web
flutter run -d android          # For Android
flutter run -d ios              # For iOS
```

### Backend Setup

```bash
# 1. Navigate to backend directory
cd backend

# 2. Create virtual environment
python -m venv venv

# 3. Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# 4. Install dependencies
pip install -r requirements.txt

# 5. Set up environment variables
# Create .env file with:
FLASK_APP=app.py
FLASK_ENV=development
FIREBASE_CREDENTIALS_PATH=path/to/credentials.json
GOOGLE_CLOUD_PROJECT_ID=your-project-id

# 6. Run the Flask app
python app.py
```

### Configuration Files

#### pubspec.yaml
Main Flutter configuration with all dependencies

#### requirements.txt
Python dependencies for backend services

#### .env (create this)
```env
# Flask
FLASK_APP=app.py
FLASK_ENV=development
FLASK_DEBUG=1

# Firebase
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
FIREBASE_PROJECT_ID=smartchef-ai

# Google Cloud
GOOGLE_CLOUD_PROJECT_ID=smartchef-ai
GOOGLE_APPLICATION_CREDENTIALS=./gcloud-credentials.json

# API Keys (if needed)
THEMEALDB_API_KEY=1  # Free tier = 1
```

---

## ✨ Features

### 1. Home Screen

**Purpose**: Main landing page with personalized content

**Features**:
- Personalized greeting based on time of day
- Quick category access (Breakfast, Lunch, Dinner, Dessert)
- Featured recipes carousel
- Popular recipes grid
- Search bar with voice and camera options

**Navigation**:
- Route: `/`
- Bottom nav index: 0

**Key Components**:
- `CategoryChips`: Horizontal scrollable categories
- `RecipeCard`: Grid of recipe cards
- `SmartSearchBar`: Search with voice/camera
- `ShimmerPlaceholder`: Loading skeleton

---

### 2. Smart Search

**Purpose**: Find recipes by text, voice, or categories

**Features**:
- Real-time text search
- Voice search with speech-to-text
- Category filter chips
- Recent search history
- Search suggestions
- Empty state handling

**Navigation**:
- Route: `/search`
- Bottom nav index: 1

**Key Components**:
- `SmartSearchBar`: Multi-input search
- `CategoryChips`: Filter by category
- `RecipeCard`: Search results
- Voice recording indicator

**Voice Search Flow**:
```dart
1. User taps microphone icon
2. Request microphone permission
3. Start listening
4. Display "Listening..." indicator
5. Convert speech to text
6. Auto-submit search
7. Display results
```

---

### 3. Ingredient Scanner

**Purpose**: AI-powered ingredient detection from images

**Features**:
- Camera capture
- Gallery image selection
- Mock AI ingredient detection
- Recipe suggestions based on detected ingredients
- Confidence scores for detections
- Multiple ingredient support

**Navigation**:
- Route: `/scan`
- Accessed via search bar camera icon

**Detection Flow**:
```
1. User selects camera/gallery
2. Image captured/selected
3. Image uploaded to backend
4. AI model detects ingredients
5. Return ingredients with confidence
6. Show recipe suggestions
7. Navigate to recipe detail
```

**Key Components**:
- Image picker integration
- Detection result cards
- Ingredient confidence bars
- Recipe match scores

---

### 4. Recipe Detail

**Purpose**: Complete recipe information with actions

**Features**:
- Hero image with parallax effect
- Servings adjuster
- Ingredient list
- Step-by-step instructions
- Nutrition information tabs
- Add to favorites
- Add ingredients to grocery list
- Share recipe
- Similar recipes

**Navigation**:
- Route: `/recipe/:id`
- Extra: Recipe object

**Tabs**:
1. **Ingredients**: Full ingredient list with servings multiplier
2. **Instructions**: Step-by-step cooking guide
3. **Nutrition**: Calories, protein, carbs, fat, fiber

**Key Components**:
- `RecipeHeroImage`: Parallax header
- `IngredientChip`: Ingredient tags
- `StepIndicator`: Numbered steps
- `NutritionCard`: Nutrition display
- Floating action buttons (FAB)

---

### 5. Favorites

**Purpose**: Manage saved recipes

**Features**:
- Grid view of favorite recipes
- Quick unfavorite action
- Empty state for no favorites
- Persistent storage (SharedPreferences)
- Search within favorites
- Sort by date added, name, rating

**Navigation**:
- Route: `/favorites`
- Bottom nav index: 2

**Storage**:
```dart
SharedPreferences prefs = await SharedPreferences.getInstance();
Set<String> favoriteIds = prefs.getStringList('favorites')?.toSet() ?? {};
```

**Key Components**:
- `RecipeCard` with favorite indicator
- `EmptyState` for no favorites
- Grid layout with animations

---

### 6. Grocery List

**Purpose**: Manage shopping list for recipes

**Features**:
- Manual item entry
- Auto-add from recipes
- Check/uncheck items
- Delete items
- Clear completed items
- Voice input for items (coming soon)
- Categorization (produce, dairy, meat, etc.)
- Persistent storage

**Navigation**:
- Route: `/grocery`
- Bottom nav index: 3

**Item Management**:
```dart
void addItem(String name, double quantity, String unit) {
  items.add(GroceryItem(
    name: name,
    quantity: quantity,
    unit: unit,
    category: 'other',
    checked: false,
    recipes: [],
  ));
}
```

**Key Components**:
- `GroceryItemTile`: Checklist item
- Add item dialog
- Category sections
- Swipe to delete

---

### 7. Profile & Settings

**Purpose**: User account and app settings

**Features**:
- User information display
- Dietary preferences
- Allergen management
- Dark mode toggle
- Notification settings
- Language selection
- About app
- Privacy policy
- Sign out

**Navigation**:
- Route: `/profile`
- Bottom nav index: 4

**Settings**:
- Dark mode (stored locally)
- Notifications (push, email)
- Language (i18n support)
- Units (metric/imperial)
- Auto-play videos
- Download over WiFi only

**Key Components**:
- `ProfileAvatar`: User avatar
- `SettingsTile`: Settings list item
- Toggle switches
- Section headers

---

### 8. Onboarding

**Purpose**: First-time user experience

**Features**:
- Welcome screens
- Feature highlights
- Permission requests (camera, microphone)
- Skip option
- Get started CTA

**Navigation**:
- Route: `/onboarding`
- Auto-shown on first launch

**Screens**:
1. Welcome to SmartChef AI
2. Smart Search Feature
3. Ingredient Scanner
4. Personalized Recipes
5. Get Started

---

## 🎨 Frontend (Flutter)

### Theme System

#### Color Palette

```dart
// lib/app/theme/app_colors.dart

class AppColors {
  // Primary Colors
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryOrangeDark = Color(0xFFE55B2B);
  static const Color primaryOrangeLight = Color(0xFFFF8C61);
  
  // Accent Colors
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentYellow = Color(0xFFFFB800);
  static const Color accentBlue = Color(0xFF3498DB);
  
  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Semantic Colors
  static const Color success = accentGreen;
  static const Color warning = accentYellow;
  static const Color error = Color(0xFFE74C3C);
  static const Color info = accentBlue;
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF56CCF2), accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

#### Typography Scale

```dart
// lib/app/theme/app_typography.dart

class AppTypography {
  static const String fontFamily = 'Poppins';
  
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
  );
}
```

#### Spacing System

```dart
// lib/app/theme/app_spacing.dart

class AppSpacing {
  // Spacing values
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
  
  // Padding presets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  
  // Border radius
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(999));
}

// Gap widgets for spacing
class Gap extends StatelessWidget {
  final double size;
  const Gap.xs() : size = AppSpacing.xs;
  const Gap.sm() : size = AppSpacing.sm;
  const Gap.md() : size = AppSpacing.md;
  const Gap.lg() : size = AppSpacing.lg;
  const Gap.xl() : size = AppSpacing.xl;
  const Gap.xxl() : size = AppSpacing.xxl;
  const Gap.xxxl() : size = AppSpacing.xxxl;
  
  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

class HGap extends StatelessWidget {
  final double size;
  const HGap.xs() : size = AppSpacing.xs;
  const HGap.sm() : size = AppSpacing.sm;
  const HGap.md() : size = AppSpacing.md;
  
  @override
  Widget build(BuildContext context) => SizedBox(width: size);
}
```

#### Theme Configuration

```dart
// lib/app/theme/app_theme.dart

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryOrange,
        brightness: Brightness.light,
      ),
      fontFamily: AppTypography.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryOrange,
        brightness: Brightness.dark,
      ),
      fontFamily: AppTypography.fontFamily,
    );
  }
}
```

---

### Navigation

#### GoRouter Configuration

```dart
// lib/app/routes.dart

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/recipe/:id',
      name: 'recipe',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final recipe = state.extra as Recipe?;
        return RecipeDetailScreen(recipeId: id, recipe: recipe);
      },
    ),
    GoRoute(
      path: '/favorites',
      name: 'favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/grocery',
      name: 'grocery',
      builder: (context, state) => const GroceryListScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Page not found')),
  ),
);
```

#### Navigation Usage

```dart
// Push navigation
context.push('/search');
context.push('/recipe/123', extra: recipe);

// Replace current route
context.go('/home');

// Pop back
context.pop();

// Named routes
context.pushNamed('recipe', pathParameters: {'id': '123'}, extra: recipe);
```

---

### State Management

#### Provider Architecture

```dart
// lib/providers/app_providers.dart

// Recipe Provider
class RecipeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Recipe> _recipes = [];
  List<Recipe> _favorites = [];
  Set<String> _favoriteIds = {};
  Recipe? _currentRecipe;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Recipe> get recipes => _recipes;
  List<Recipe> get favoriteRecipes => _favorites;
  Recipe? get currentRecipe => _currentRecipe;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load recipes from API
  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _recipes = await _apiService.searchRecipes('');
      await _loadFavoriteIds();
      _favorites = _recipes.where((r) => _favoriteIds.contains(r.id)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Search recipes
  Future<List<Recipe>> searchRecipes(String query) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _recipes = await _apiService.searchRecipes(query);
      _isLoading = false;
      notifyListeners();
      return _recipes;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }
  
  // Toggle favorite
  void toggleFavorite(String recipeId) {
    if (_favoriteIds.contains(recipeId)) {
      _favoriteIds.remove(recipeId);
      _favorites.removeWhere((r) => r.id == recipeId);
    } else {
      _favoriteIds.add(recipeId);
      final recipe = _recipes.firstWhere((r) => r.id == recipeId);
      _favorites.add(recipe);
    }
    _saveFavoriteIds();
    notifyListeners();
  }
  
  // Check if recipe is favorite
  bool isFavorite(String recipeId) {
    return _favoriteIds.contains(recipeId);
  }
  
  // Local storage methods
  Future<void> _loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorite_ids') ?? [];
    _favoriteIds = ids.toSet();
  }
  
  Future<void> _saveFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_ids', _favoriteIds.toList());
  }
}

// User Provider
class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isDarkMode = false;
  
  User? get currentUser => _currentUser;
  bool get isDarkMode => _isDarkMode;
  
  // Toggle dark mode
  void toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }
  
  // Load theme preference
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }
}

// Grocery List Provider
class GroceryListProvider extends ChangeNotifier {
  List<GroceryItem> _items = [];
  
  List<GroceryItem> get items => _items;
  
  // Add item
  void addItem(GroceryItem item) {
    _items.add(item);
    _saveLocalItems();
    notifyListeners();
  }
  
  // Remove item
  void removeItem(String name) {
    _items.removeWhere((item) => item.name == name);
    _saveLocalItems();
    notifyListeners();
  }
  
  // Toggle item checked state
  void toggleItem(String name) {
    final index = _items.indexWhere((item) => item.name == name);
    if (index != -1) {
      _items[index].checked = !_items[index].checked;
      _saveLocalItems();
      notifyListeners();
    }
  }
  
  // Clear checked items
  void clearCheckedItems() {
    _items.removeWhere((item) => item.checked);
    _saveLocalItems();
    notifyListeners();
  }
  
  // Local storage
  Future<void> _saveLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = _items.map((e) => '${e.name}|${e.checked}').toList();
    await prefs.setStringList('grocery_items', itemsJson);
  }
}
```

#### Provider Setup in main.dart

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GroceryListProvider()),
      ],
      child: const SmartChefApp(),
    ),
  );
}
```

---

### Screens

All screens follow a consistent structure:

```dart
class ScreenName extends StatefulWidget/StatelessWidget {
  const ScreenName({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Access theme
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Access providers
    final provider = context.watch<ProviderName>();
    
    return Scaffold(
      appBar: SmartChefAppBar(title: 'Screen Title'),
      body: _buildBody(),
      bottomNavigationBar: SmartChefBottomNav(currentIndex: 0),
    );
  }
}
```

---

### Widgets

#### Recipe Card

```dart
RecipeCard(
  id: recipe.id,
  title: recipe.name,
  imageUrl: recipe.imageUrl,
  cookTime: recipe.cookTime,
  difficulty: recipe.difficulty,
  rating: recipe.rating,
  isFavorite: provider.isFavorite(recipe.id),
  onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
  onFavoriteTap: () => provider.toggleFavorite(recipe.id),
)
```

#### Smart Search Bar

```dart
SmartSearchBar(
  hintText: 'Search recipes...',
  onSubmitted: (query) {
    context.read<RecipeProvider>().searchRecipes(query);
  },
  onVoiceTap: () async {
    // Voice search implementation
  },
  onCameraTap: () {
    context.push('/scan');
  },
)
```

#### Gradient Button

```dart
GradientButton(
  text: 'Get Started',
  gradient: AppColors.primaryGradient,
  onPressed: () {
    // Action
  },
)
```

---

### Models

#### Recipe Model

```dart
class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
  final List<String> steps;
  final String prepTime;
  final String cookTime;
  final String difficulty;
  final String cuisine;
  final List<String> dietaryTags;
  final Nutrition nutrition;
  final int servings;
  final String imageUrl;
  final double? rating;
  
  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.steps,
    required this.prepTime,
    required this.cookTime,
    required this.difficulty,
    required this.cuisine,
    required this.dietaryTags,
    required this.nutrition,
    required this.servings,
    required this.imageUrl,
    this.rating,
  });
  
  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Parse from TheMealDB or custom API
  }
  
  Map<String, dynamic> toJson() {
    // Serialize to JSON
  }
}
```

#### Nutrition Model

```dart
class Nutrition {
  final int calories;
  final String protein;
  final String carbs;
  final String fat;
  final String fiber;
  
  Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });
  
  factory Nutrition.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### GroceryItem Model

```dart
class GroceryItem {
  final String name;
  final double quantity;
  final String unit;
  final String category;
  bool checked;
  final List<String> recipes;
  
  GroceryItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.checked = false,
    required this.recipes,
  });
  
  factory GroceryItem.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

---

## 🔧 Backend (Flask)

### API Endpoints

#### Recipe Endpoints

```python
# Get all recipes
GET /api/recipes
Response: {
  "recipes": [Recipe],
  "count": int
}

# Search recipes
GET /api/recipes/search?query={query}&category={category}
Response: {
  "recipes": [Recipe],
  "count": int
}

# Get recipe by ID
GET /api/recipes/<id>
Response: {
  "recipe": Recipe
}

# Get random recipes
GET /api/recipes/random?count={count}
Response: {
  "recipes": [Recipe]
}
```

#### Detection Endpoints

```python
# Detect ingredients from image
POST /api/detect/ingredients
Body: multipart/form-data with 'image' file
Response: {
  "ingredients": [
    {
      "name": str,
      "confidence": float,
      "bounding_box": [x, y, w, h]
    }
  ],
  "suggested_recipes": [Recipe]
}
```

#### User Endpoints

```python
# Create user
POST /api/users
Body: {
  "name": str,
  "email": str
}

# Get user
GET /api/users/<user_id>

# Update preferences
PUT /api/users/<user_id>/preferences
Body: {
  "dietary_preferences": [str],
  "allergies": [str]
}
```

#### Grocery List Endpoints

```python
# Create grocery list
POST /api/grocery-lists
Body: {
  "user_id": str,
  "recipe_ids": [str],
  "servings_multipliers": {recipe_id: float}
}

# Get grocery list
GET /api/grocery-lists/<list_id>

# Toggle item
PUT /api/grocery-lists/<list_id>/items/<item_name>/toggle

# Delete grocery list
DELETE /api/grocery-lists/<list_id>
```

---

### Services

#### Ingredient Detector

```python
# backend/services/ingredient_detector.py

class IngredientDetector:
    def __init__(self):
        self.model = self._load_yolo_model()
    
    def detect_ingredients(self, image_path):
        """
        Detect ingredients from image using YOLOv5
        Returns list of detected ingredients with confidence scores
        """
        results = self.model(image_path)
        ingredients = []
        
        for detection in results.xyxy[0]:
            x1, y1, x2, y2, conf, cls = detection
            ingredient_name = self._get_ingredient_name(cls)
            ingredients.append({
                'name': ingredient_name,
                'confidence': float(conf),
                'bounding_box': [float(x1), float(y1), float(x2), float(y2)]
            })
        
        return ingredients
```

#### Recommendation Engine

```python
# backend/services/recommendation_engine.py

class RecommendationEngine:
    def get_recommendations(self, user_id, detected_ingredients):
        """
        Get recipe recommendations based on detected ingredients
        and user preferences
        """
        user = self._get_user(user_id)
        recipes = self._search_recipes_by_ingredients(detected_ingredients)
        
        # Filter by dietary preferences
        filtered = self._filter_by_preferences(recipes, user.preferences)
        
        # Calculate similarity scores
        scored = self._calculate_similarity(filtered, detected_ingredients)
        
        # Sort by score
        return sorted(scored, key=lambda x: x.similarity_score, reverse=True)
```

---

## 🌐 API Integration

### TheMealDB API

**Base URL**: `https://www.themealdb.com/api/json/v1/1`

#### Available Endpoints

| Endpoint | Description | Example |
|----------|-------------|---------|
| `/search.php?s={name}` | Search by recipe name | `/search.php?s=Arrabiata` |
| `/lookup.php?i={id}` | Get recipe by ID | `/lookup.php?i=52772` |
| `/random.php` | Get random recipe | `/random.php` |
| `/filter.php?c={category}` | Filter by category | `/filter.php?c=Seafood` |
| `/filter.php?a={area}` | Filter by area/cuisine | `/filter.php?a=Canadian` |
| `/filter.php?i={ingredient}` | Filter by ingredient | `/filter.php?i=chicken` |
| `/categories.php` | List all categories | `/categories.php` |
| `/list.php?c=list` | List categories | `/list.php?c=list` |
| `/list.php?a=list` | List areas | `/list.php?a=list` |
| `/list.php?i=list` | List ingredients | `/list.php?i=list` |

#### Response Format

```json
{
  "meals": [
    {
      "idMeal": "52772",
      "strMeal": "Teriyaki Chicken Casserole",
      "strDrinkAlternate": null,
      "strCategory": "Chicken",
      "strArea": "Japanese",
      "strInstructions": "Preheat oven...",
      "strMealThumb": "https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg",
      "strTags": "Meat,Casserole",
      "strYoutube": "https://www.youtube.com/watch?v=4aZr5hZXP_s",
      "strIngredient1": "soy sauce",
      "strIngredient2": "water",
      "strMeasure1": "3/4 cup",
      "strMeasure2": "1/2 cup",
      ...
    }
  ]
}
```

### ApiService Implementation

```dart
// lib/services/api_service.dart

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://www.themealdb.com/api/json/v1/1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await _dio.get(
        '/search.php',
        queryParameters: {'s': query},
      );
      
      if (response.data['meals'] == null) return [];
      
      return (response.data['meals'] as List)
          .map((json) => Recipe.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search recipes: $e');
    }
  }
  
  Future<Recipe?> getRecipe(String id) async {
    try {
      final response = await _dio.get(
        '/lookup.php',
        queryParameters: {'i': id},
      );
      
      if (response.data['meals'] == null) return null;
      
      return Recipe.fromJson(response.data['meals'][0]);
    } catch (e) {
      throw Exception('Failed to get recipe: $e');
    }
  }
  
  Future<List<Recipe>> getRandomRecipes(int count) async {
    final recipes = <Recipe>[];
    for (int i = 0; i < count; i++) {
      try {
        final response = await _dio.get('/random.php');
        if (response.data['meals'] != null) {
          recipes.add(Recipe.fromJson(response.data['meals'][0]));
        }
      } catch (e) {
        // Skip failed requests
      }
    }
    return recipes;
  }
}
```

---

## 💻 Development Guide

### Code Style

#### Dart/Flutter Conventions

```dart
// File names: snake_case
recipe_detail_screen.dart

// Class names: PascalCase
class RecipeDetailScreen extends StatelessWidget {}

// Variables/functions: camelCase
final recipeProvider = context.watch<RecipeProvider>();

// Constants: camelCase with const
const double defaultPadding = 16.0;

// Private members: _leadingUnderscore
String _privateVariable;
void _privateMethod() {}
```

#### Python Conventions

```python
# File names: snake_case
ingredient_detector.py

# Class names: PascalCase
class IngredientDetector:
    pass

# Functions/variables: snake_case
def detect_ingredients():
    pass

# Constants: UPPER_SNAKE_CASE
MAX_IMAGE_SIZE = 10 * 1024 * 1024
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/ingredient-scanner

# Make changes and commit
git add .
git commit -m "feat: add ingredient scanner UI"

# Push to remote
git push origin feature/ingredient-scanner

# Create pull request on GitHub
```

### Commit Message Convention

```
type(scope): subject

body (optional)

footer (optional)
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples**:
```
feat(search): add voice search functionality
fix(grocery): resolve item duplication bug
docs(readme): update installation instructions
```

---

## 🚀 Build & Deployment

### Flutter Build Commands

```bash
# Development builds
flutter run -d chrome               # Web (debug)
flutter run -d android              # Android (debug)
flutter run -d ios                  # iOS (debug)

# Release builds
flutter build web --release         # Web
flutter build apk --release         # Android APK
flutter build appbundle --release   # Android App Bundle
flutter build ios --release         # iOS
flutter build windows --release     # Windows
flutter build macos --release       # macOS
flutter build linux --release       # Linux
```

### Web Deployment

#### Netlify
```bash
# Build
flutter build web --release

# Deploy
netlify deploy --prod --dir=build/web
```

#### Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init hosting

# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

#### GitHub Pages
```bash
# Build
flutter build web --release --base-href "/smartchefai/"

# Deploy (push to gh-pages branch)
cd build/web
git init
git add .
git commit -m "Deploy to GitHub Pages"
git push -f git@github.com:angelpsalu/smartchefai.git master:gh-pages
```

### Android Deployment

#### Generate Keystore

```bash
keytool -genkey -v -keystore ~/smartchef-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias smartchef
```

#### Configure Signing

Edit `android/key.properties`:
```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=smartchef
storeFile=../smartchef-release-key.jks
```

#### Build APK/App Bundle

```bash
# APK (for direct installation)
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS Deployment

```bash
# Open Xcode
open ios/Runner.xcworkspace

# Configure signing in Xcode:
# 1. Select Runner project
# 2. Select Runner target
# 3. Signing & Capabilities tab
# 4. Select your development team
# 5. Choose provisioning profile

# Build
flutter build ios --release

# Archive and upload via Xcode
```

### Backend Deployment

#### Heroku

```bash
# Install Heroku CLI
# Login
heroku login

# Create app
heroku create smartchef-backend

# Add Python buildpack
heroku buildpacks:set heroku/python

# Deploy
git push heroku main

# Set environment variables
heroku config:set FIREBASE_CREDENTIALS_PATH=...
```

#### Google Cloud Run

```bash
# Build container
gcloud builds submit --tag gcr.io/PROJECT_ID/smartchef-backend

# Deploy
gcloud run deploy smartchef-backend \
  --image gcr.io/PROJECT_ID/smartchef-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

---

## 🧪 Testing

### Unit Tests

```dart
// test/models/recipe_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:smartchefai/models/models.dart';

void main() {
  group('Recipe Model', () {
    test('should parse from JSON correctly', () {
      final json = {
        'idMeal': '123',
        'strMeal': 'Test Recipe',
        'strArea': 'Italian',
        // ... more fields
      };
      
      final recipe = Recipe.fromJson(json);
      
      expect(recipe.id, '123');
      expect(recipe.name, 'Test Recipe');
      expect(recipe.cuisine, 'Italian');
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/recipe_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartchefai/shared/widgets/recipe_card.dart';

void main() {
  testWidgets('RecipeCard displays recipe information', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecipeCard(
            id: '1',
            title: 'Pasta',
            imageUrl: 'https://example.com/image.jpg',
            cookTime: '30 min',
            difficulty: 'Easy',
            rating: 4.5,
          ),
        ),
      ),
    );
    
    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// test/integration/search_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartchefai/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Search flow works correctly', (tester) async {
    await tester.pumpWidget(const SmartChefApp());
    
    // Navigate to search
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    
    // Enter search query
    await tester.enterText(find.byType(TextField), 'pasta');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    
    // Verify results
    expect(find.byType(RecipeCard), findsWidgets);
  });
}
```

### Run Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 🔮 Future Enhancements

### Phase 2 (Next 3 months)

- [ ] **Real AI Ingredient Detection**
  - Integrate Google ML Kit
  - Train custom model on food images
  - Improve detection accuracy

- [ ] **User Authentication**
  - Firebase Authentication
  - Social login (Google, Apple, Facebook)
  - Email/password authentication

- [ ] **Cloud Sync**
  - Sync favorites across devices
  - Cloud backup for preferences
  - Real-time updates

- [ ] **Meal Planning**
  - Weekly meal planner
  - Calendar integration
  - Meal prep scheduling

### Phase 3 (6-12 months)

- [ ] **Community Features**
  - User-generated recipes
  - Recipe ratings & reviews
  - Social sharing

- [ ] **Advanced Features**
  - In-app cooking timer
  - Step-by-step video tutorials
  - Cooking mode (hands-free)

- [ ] **Smart Features**
  - Barcode scanning for packaged foods
  - Nutrition goal tracking
  - Recipe substitutions

- [ ] **Integrations**
  - Smart home integration (Alexa, Google Home)
  - Fitness app integration
  - Online grocery ordering

---

## 🐛 Troubleshooting

### Common Issues

#### Flutter Issues

**Issue**: "Failed to build for iOS"
```bash
# Solution
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

**Issue**: "Gradle build failed"
```bash
# Solution
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Issue**: "Hot reload not working"
```bash
# Solution
flutter clean
flutter pub get
# Restart the app
```

#### Backend Issues

**Issue**: "ModuleNotFoundError"
```bash
# Solution
pip install -r requirements.txt
```

**Issue**: "Firebase credentials not found"
```bash
# Solution
# Ensure .env file has correct path
FIREBASE_CREDENTIALS_PATH=./path/to/credentials.json
```

### Debug Mode

```dart
// Enable debug prints
debugPrint('Debug message');

// Use Flutter DevTools
flutter run --observatory-port=9200
```

---

## 📄 License

MIT License

Copyright (c) 2025 SmartChef AI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## 👥 Contributors

- **Angel Psalu** - Project Lead & Developer
- **GitHub**: [@angelpsalu](https://github.com/angelpsalu)

---

## 📞 Contact & Support

- **GitHub Issues**: [github.com/angelpsalu/smartchefai/issues](https://github.com/angelpsalu/smartchefai/issues)
- **Email**: support@smartchefai.com
- **Documentation**: [docs.smartchefai.com](https://docs.smartchefai.com)

---

**Last Updated**: December 17, 2025  
**Version**: 0.1.0  
**Status**: ✅ Active Development
