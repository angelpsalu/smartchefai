import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/theme.dart';
import '../../constants/firestore_constants.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/app_providers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPress;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().loadRecipes();
      context.read<GroceryListProvider>().syncOnLogin();
      context.read<MealPlanProvider>().loadMealPlan();
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final maxDuration = const Duration(seconds: 2);
    final isWarning = _lastBackPress == null ||
        now.difference(_lastBackPress!) > maxDuration;

    if (isWarning) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<RecipeProvider>().loadRecipes();
            },
            child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.paddingHorizontalMd,
                  child: SmartSearchBar(
                    readOnly: true,
                    onTap: () => context.push('/search'),
                    onVoiceTap: () => context.push('/search'),
                    onCameraTap: () => context.push('/scan'),
                    hintText: 'What would you like to cook today?',
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap.lg()),

              // Nutrition Goals (only for signed-in users)
              if (FirebaseService().isSignedIn)
                const SliverToBoxAdapter(
                  child: NutritionGoalsCard(),
                ),

              const SliverToBoxAdapter(child: Gap.lg()),

              // Categories
              SliverToBoxAdapter(
                child: _buildCategoriesSection(context),
              ),

              const SliverToBoxAdapter(child: Gap.lg()),

              // Meal Plan Banner
              SliverToBoxAdapter(
                child: _buildMealPlanCard(context),
              ),

              const SliverToBoxAdapter(child: Gap.lg()),

              // Featured Recipes
              SliverToBoxAdapter(
                child: _buildFeaturedSection(context),
              ),

              const SliverToBoxAdapter(child: Gap.lg()),

              // Popular Recipes Header
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Popular Recipes',
                  icon: Icons.local_fire_department,
                  actionText: 'See All',
                ),
              ),

              const SliverToBoxAdapter(child: Gap.md()),

              // Popular Recipes Grid
              _buildRecipeGrid(context),

              // Bottom padding
              const SliverToBoxAdapter(child: Gap.xxxl()),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final userName = context.watch<UserProvider>().currentUser?.name ?? 'Chef';

    return Padding(
      padding: AppSpacing.paddingMd,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  userName,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Notification Bell
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
            icon: Icon(
              Icons.notifications_outlined,
              color: colorScheme.onSurface,
            ),
          ),
          // Profile Avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: ProfileAvatar(
              size: 44,
              initials: _getInitials(context.watch<UserProvider>().currentUser?.name),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    final p = parts[0];
    return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = [
      _CategoryItem('🍳', 'Breakfast'),
      _CategoryItem('🥗', 'Lunch'),
      _CategoryItem('🍝', 'Dinner'),
      _CategoryItem('🍰', 'Dessert'),
      _CategoryItem('🥤', 'Drinks'),
      _CategoryItem('🥬', 'Vegan'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _selectedCategory != null
              ? 'Showing: $_selectedCategory'
              : 'Categories',
          icon: Icons.grid_view_rounded,
          actionText: _selectedCategory != null ? 'Clear' : null,
          onActionTap: _selectedCategory != null
              ? () {
                  setState(() => _selectedCategory = null);
                  context.read<RecipeProvider>().loadRecipes();
                }
              : null,
        ),
        const Gap.md(),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.paddingHorizontalMd,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const HGap.md(),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat.name;
              return _CategoryCard(
                category: cat,
                isSelected: isSelected,
                onTap: () {
                  if (isSelected) {
                    setState(() => _selectedCategory = null);
                    context.read<RecipeProvider>().loadRecipes();
                  } else {
                    setState(() => _selectedCategory = cat.name);
                    context.read<RecipeProvider>().searchRecipes(cat.name);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection(BuildContext context) {
    final recipes = context.watch<RecipeProvider>().recipes;
    final featuredRecipes = recipes.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Featured',
          icon: Icons.star_rounded,
          actionText: 'See All',
        ),
        const Gap.md(),
        SizedBox(
          height: 200,
          child: featuredRecipes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: AppSpacing.paddingHorizontalMd,
                  itemCount: featuredRecipes.length,
                  separatorBuilder: (_, __) => const HGap.md(),
                  itemBuilder: (context, index) {
                    final recipe = featuredRecipes[index];
                    return SizedBox(
                      width: 280,
                      child: RecipeCard(
                        id: recipe.id,
                        title: recipe.name,
                        imageUrl: recipe.imageUrl,
                        cookTime: '${recipe.prepTime + recipe.cookTime} min',
                        difficulty: recipe.difficulty,
                        rating: recipe.rating,
                        isFavorite: context.watch<RecipeProvider>().isFavorite(recipe.id),
                        onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
                        onFavoriteTap: () {
                          context.read<RecipeProvider>().toggleFavorite(recipe.id);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecipeGrid(BuildContext context) {
    final recipes = context.watch<RecipeProvider>().recipes;
    final isLoading = context.watch<RecipeProvider>().isLoading;

    if (isLoading && recipes.isEmpty) {
      return SliverPadding(
        padding: AppSpacing.paddingHorizontalMd,
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: AppLayout.recipeCardAspectRatio,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => ShimmerPlaceholder(
              height: 200,
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            childCount: 4,
          ),
        ),
      );
    }

    if (recipes.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          icon: Icons.restaurant_menu,
          title: 'No recipes found',
          subtitle: 'Try searching for something delicious',
          actionText: 'Browse Recipes',
          onAction: () => context.read<RecipeProvider>().loadRecipes(),
        ),
      );
    }

    return SliverPadding(
      padding: AppSpacing.paddingHorizontalMd,
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: AppLayout.recipeCardAspectRatio,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final recipe = recipes[index];
            return RecipeCard(
              id: recipe.id,
              title: recipe.name,
              imageUrl: recipe.imageUrl,
              cookTime: '${recipe.prepTime + recipe.cookTime} min',
              difficulty: recipe.difficulty,
              rating: recipe.rating,
              isFavorite: context.watch<RecipeProvider>().isFavorite(recipe.id),
              onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
              onFavoriteTap: () {
                context.read<RecipeProvider>().toggleFavorite(recipe.id);
              },
            );
          },
          childCount: recipes.length,
        ),
      ),
    );
  }
  Widget _buildMealPlanCard(BuildContext context) {
    final provider = context.watch<MealPlanProvider>();
    final assignedCount = provider.mealPlan?.days.values
        .whereType<String>()
        .length ?? 0;

    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: GestureDetector(
        onTap: () => context.go('/planner'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: AppColors.warmGradient,
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          child: Row(
            children: [
              const Text('🗓️', style: TextStyle(fontSize: 36)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Meal Plan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      assignedCount == 0
                          ? 'Plan your meals for the week'
                          : '$assignedCount of 7 days planned',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String emoji;
  final String name;

  _CategoryItem(this.emoji, this.name);
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem category;
  final VoidCallback onTap;
  final bool isSelected;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const Gap.xs(),
            Text(
              category.name,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryOrange : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
