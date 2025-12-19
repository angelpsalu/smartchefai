import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/app_providers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().loadRecipes();
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
                    onVoiceTap: () => context.push('/voice-search'),
                    onCameraTap: () => context.push('/scan'),
                    hintText: 'What would you like to cook today?',
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
              ),

              const SliverToBoxAdapter(child: Gap.lg()),

              // Categories
              SliverToBoxAdapter(
                child: _buildCategoriesSection(context),
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
            onPressed: () {},
            icon: Badge(
              smallSize: 8,
              child: Icon(
                Icons.notifications_outlined,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // Profile Avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: const ProfileAvatar(
              size: 44,
              initials: 'SC',
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
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
        const SectionHeader(
          title: 'Categories',
          icon: Icons.grid_view_rounded,
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
              return _CategoryCard(
                category: categories[index],
                onTap: () {
                  context.read<RecipeProvider>().searchRecipes(categories[index].name);
                  context.push('/search');
                },
              ).animate(delay: (100 * index).ms).fadeIn().scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
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
            childAspectRatio: 0.75,
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
          childAspectRatio: 0.75,
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
          childCount: recipes.length.clamp(0, 10),
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

  const _CategoryCard({
    required this.category,
    required this.onTap,
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
          color: colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
