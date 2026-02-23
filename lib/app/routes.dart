import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

// Feature Screens
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/recipe_detail/recipe_detail_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/grocery/grocery_list_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dietary_preferences/dietary_preferences_screen.dart';
import '../features/meal_plan/meal_plan_screen.dart';
import '../features/auth/get_started_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/forgot_password_screen.dart';

// Navigation Key for nested navigation
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// App Router Configuration using GoRouter with ShellRoute
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/get-started',
  debugLogDiagnostics: true,
  redirect: (context, state) {
    final firebaseService = FirebaseService();
    final isSignedIn = firebaseService.isSignedIn;
    final isGoingToAuth = state.uri.path.startsWith('/get-started') ||
        state.uri.path.startsWith('/login') ||
        state.uri.path.startsWith('/signup') ||
        state.uri.path.startsWith('/forgot-password');

    // Redirect to get-started if not signed in and not already going to auth screens
    if (!isSignedIn && !isGoingToAuth) {
      return '/get-started';
    }

    // Redirect to home if signed in and trying to access auth screens
    if (isSignedIn && isGoingToAuth) {
      return '/';
    }

    return null;
  },
  routes: [
    // Auth Routes (outside shell)
    GoRoute(
      path: '/get-started',
      name: 'get-started',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GetStartedScreen(),
    ),

    GoRoute(
      path: '/login',
      name: 'login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/signup',
      name: 'signup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SignupScreen(),
    ),

    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // Onboarding (outside shell)
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Main Shell with Bottom Navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        // Home
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const HomeScreen(),
          ),
        ),
        
        // Search
        GoRoute(
          path: '/search',
          name: 'search',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const SearchScreen(),
          ),
        ),
        
        // Favorites
        GoRoute(
          path: '/favorites',
          name: 'favorites',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const FavoritesScreen(),
          ),
        ),
        
        // Profile
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const ProfileScreen(),
          ),
        ),
      ],
    ),

    // Routes outside shell (full screen)
    GoRoute(
      path: '/scan',
      name: 'scan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScanScreen(),
    ),

    GoRoute(
      path: '/grocery',
      name: 'grocery',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GroceryListScreen(),
    ),

    GoRoute(
      path: '/meal-plan',
      name: 'meal-plan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MealPlanScreen(),
    ),

    // Dietary Preferences
    GoRoute(
      path: '/dietary-preferences',
      name: 'dietary-preferences',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DietaryPreferencesScreen(),
    ),

    // Recipe Detail
    GoRoute(
      path: '/recipe/:id',
      name: 'recipe-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final recipe = state.extra as Recipe?;
        if (recipe == null) {
          return const Scaffold(
            body: Center(
              child: Text('Recipe not found'),
            ),
          );
        }
        return RecipeDetailScreen(recipe: recipe);
      },
    ),

    // Voice Search
    GoRoute(
      path: '/voice-search',
      name: 'voice-search',
      parentNavigatorKey: _rootNavigatorKey,
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

/// Scaffold with persistent bottom navigation bar
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    
    int currentIndex = 0;
    if (location.startsWith('/search')) {
      currentIndex = 1;
    } else if (location.startsWith('/favorites')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      currentIndex = 4;
    }

    return _BottomNavBar(currentIndex: currentIndex);
  }
}

/// Bottom navigation bar widget
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const _BottomNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.search_outlined,
                activeIcon: Icons.search_rounded,
                label: 'Search',
                isSelected: currentIndex == 1,
                onTap: () => context.go('/search'),
              ),
              _CenterButton(
                onTap: () => context.push('/scan'),
              ),
              _NavItem(
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite_rounded,
                label: 'Favorites',
                isSelected: currentIndex == 3,
                onTap: () => context.go('/favorites'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentIndex == 4,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6B35),
              Color(0xFFE55B2B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF6B35).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

/// Route names for type-safe navigation
class AppRoutes {
  static const String onboarding = 'onboarding';
  static const String home = 'home';
  static const String search = 'search';
  static const String favorites = 'favorites';
  static const String grocery = 'grocery';
  static const String profile = 'profile';
  static const String dietaryPreferences = 'dietary-preferences';
  static const String recipeDetail = 'recipe-detail';
  static const String scan = 'scan';
  static const String voiceSearch = 'voice-search';
  static const String mealPlan = 'meal-plan';
}

/// Extension for easy navigation
extension NavigationExtension on BuildContext {
  void goToRecipe(Recipe recipe) {
    GoRouter.of(this).push('/recipe/${recipe.id}', extra: recipe);
  }

  void goToSearch({String? query}) {
    if (query != null) {
      GoRouter.of(this).go('/search?q=$query');
    } else {
      GoRouter.of(this).go('/search');
    }
  }
}
