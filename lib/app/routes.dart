import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';

// Feature Screens
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/recipe_detail/recipe_detail_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/grocery/grocery_list_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

/// App Router Configuration using GoRouter
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    // Onboarding
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Main Navigation Routes
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

    // Recipe Detail
    GoRoute(
      path: '/recipe/:id',
      name: 'recipe-detail',
      builder: (context, state) {
        final recipe = state.extra as Recipe?;
        if (recipe == null) {
          // Handle invalid navigation
          return const Scaffold(
            body: Center(
              child: Text('Recipe not found'),
            ),
          );
        }
        return RecipeDetailScreen(recipe: recipe);
      },
    ),

    // Scan/Camera Screen
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) => const ScanScreen(),
    ),

    // Voice Search - can redirect to search with voice mode
    GoRoute(
      path: '/voice-search',
      name: 'voice-search',
      builder: (context, state) => const SearchScreen(),
    ),
  ],
  
  // Error handling
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);

/// Route names for type-safe navigation
class AppRoutes {
  static const String onboarding = 'onboarding';
  static const String home = 'home';
  static const String search = 'search';
  static const String favorites = 'favorites';
  static const String grocery = 'grocery';
  static const String profile = 'profile';
  static const String recipeDetail = 'recipe-detail';
  static const String scan = 'scan';
  static const String voiceSearch = 'voice-search';
}

/// Extension for easy navigation
extension NavigationExtension on BuildContext {
  void goToRecipe(Recipe recipe) {
    GoRouter.of(this).go('/recipe/${recipe.id}', extra: recipe);
  }

  void goToSearch({String? query}) {
    if (query != null) {
      GoRouter.of(this).go('/search?q=$query');
    } else {
      GoRouter.of(this).go('/search');
    }
  }
}
