import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _servings = 4;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final recipe = widget.recipe;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  final cuisineInfo = recipe.cuisine.isNotEmpty
                      ? '${recipe.cuisine} • '
                      : '';
                  final totalTime = recipe.prepTime + recipe.cookTime;
                  Share.share(
                    'Check out this recipe: ${recipe.name}\n\n'
                    '$cuisineInfo$totalTime min\n\n'
                    'https://smartchefai.web.app/recipe/${recipe.id}',
                  );
                },
                icon: Container(
                  padding: AppSpacing.paddingSm,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white),
                ),
              ),
              if (FirebaseService().isSignedIn)
                IconButton(
                  onPressed: () {
                    context.read<RecipeProvider>().toggleFavorite(recipe.id);
                  },
                  icon: Container(
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      context.watch<RecipeProvider>().isFavorite(recipe.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: context.watch<RecipeProvider>().isFavorite(recipe.id)
                          ? AppColors.primaryOrange
                          : Colors.white,
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recipe-image-${recipe.id}',
                    child: CachedNetworkImage(
                      imageUrl: recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.restaurant, size: 64),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recipe Info
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (recipe.rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentYellow.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: AppColors.accentYellow,
                              ),
                              const HGap.xxs(),
                              Text(
                                recipe.rating!.toStringAsFixed(1),
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const Gap.sm(),

                  // Cuisine tag
                  if (recipe.cuisine.isNotEmpty)
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        Chip(
                          label: Text(recipe.cuisine),
                          backgroundColor: colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        if (recipe.difficulty.isNotEmpty)
                          Chip(
                            label: Text(recipe.difficulty),
                            backgroundColor: colorScheme.tertiaryContainer,
                            labelStyle: TextStyle(
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                      ],
                    ),

                  const Gap.lg(),

                  // Quick Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.schedule,
                          label: 'Prep',
                          value: '${recipe.prepTime} min',
                          color: colorScheme.primary,
                        ),
                      ),
                      const HGap.md(),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.local_fire_department,
                          label: 'Cook',
                          value: '${recipe.cookTime} min',
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      const HGap.md(),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.timer_outlined,
                          label: 'Total',
                          value: '${recipe.prepTime + recipe.cookTime} min',
                          color: AppColors.accentYellow,
                        ),
                      ),
                      const HGap.md(),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.restaurant,
                          label: 'Servings',
                          value: '$_servings',
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),

                  const Gap.lg(),

                  // Start Cooking Button (only for signed-in users)
                  if (FirebaseService().isSignedIn) ...[
                    GradientButton(
                      text: 'Start Cooking',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => _startCooking(context),
                    ),
                    const Gap.sm(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Add to Meal Plan'),
                      onPressed: () => _showAddToMealPlanSheet(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],

                  const Gap.md(),
                ],
              ),
            ),
          ),

          // Pinned Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Ingredients'),
                  Tab(text: 'Instructions'),
                  Tab(text: 'Nutrition'),
                ],
              ),
              colorScheme.surface,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _IngredientsTab(
              ingredients: recipe.ingredients,
              servings: _servings,
              onServingsChanged: (value) {
                setState(() => _servings = value);
              },
              onAddToGrocery: FirebaseService().isSignedIn
                  ? () => _addToGroceryList(context, recipe)
                  : null,
            ),
            _InstructionsTab(instructions: recipe.instructions),
            _NutritionTab(nutrition: recipe.nutrition),
          ],
        ),
      ),
    );
  }

  Future<void> _startCooking(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final userProvider = context.read<UserProvider>();
    final nutritionProvider = context.read<NutritionProvider>();
    // Run both in parallel for faster response
    await Future.wait([
      userProvider.incrementRecipesCooked(),
      nutritionProvider.logRecipe(widget.recipe),
    ]);
    if (!mounted) return;
    // Switch to instructions tab
    _tabController.animateTo(1);
    messenger.showSnackBar(
      const SnackBar(content: Text('Good luck! Follow the instructions below.')),
    );
  }

  void _addToGroceryList(BuildContext context, Recipe recipe) {
    final groceryProvider = context.read<GroceryListProvider>();

    // Create grocery items from ingredients
    for (final ingredient in recipe.ingredients) {
      groceryProvider.addItem(
        GroceryItem(
          name: ingredient,
          quantity: 1.0,
          unit: '',
          category: 'other',
          checked: false,
          recipes: [recipe.name],
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${recipe.ingredients.length} ingredients added to grocery list',
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => context.push('/grocery'),
        ),
      ),
    );
  }

  Future<void> _showAddToMealPlanSheet(BuildContext context) async {
    final mealPlanProvider = context.read<MealPlanProvider>();
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const slots = ['breakfast', 'lunch', 'dinner', 'snack'];
    const slotIcons = {
      'breakfast': Icons.free_breakfast,
      'lunch': Icons.lunch_dining,
      'dinner': Icons.dinner_dining,
      'snack': Icons.coffee,
    };

    String? selectedDay;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedDay == null ? 'Choose a Day' : 'Choose Meal Slot · $selectedDay',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedDay == null)
                    ...days.map((day) {
                      final key = day.toLowerCase();
                      final daySlots = mealPlanProvider.mealPlan?.days[key] ?? {};
                      final filledCount = daySlots.values.where((v) => v != null).length;
                      return ListTile(
                        leading: Icon(Icons.calendar_today_outlined,
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(day),
                        subtitle: filledCount > 0
                            ? Text('$filledCount meal${filledCount > 1 ? 's' : ''} planned')
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => setSheetState(() => selectedDay = day),
                      );
                    })
                  else
                    ...slots.map((slot) {
                      final key = selectedDay!.toLowerCase();
                      final daySlots = mealPlanProvider.mealPlan?.days[key] ?? {};
                      final assignedId = daySlots[slot];
                      final assignedName = assignedId != null
                          ? (mealPlanProvider.assignedRecipes[assignedId]?.name ?? 'Recipe')
                          : null;
                      final label = '${slot[0].toUpperCase()}${slot.substring(1)}';
                      return ListTile(
                        leading: Icon(
                          slotIcons[slot] ?? Icons.restaurant,
                          color: assignedId != null
                              ? Theme.of(ctx).colorScheme.primary
                              : Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(label),
                        subtitle: assignedId != null
                            ? Text(
                                'Replace: $assignedName',
                                style: TextStyle(
                                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                                ),
                              )
                            : null,
                        onTap: () async {
                          Navigator.of(sheetCtx).pop();
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);
                          final name = widget.recipe.name;
                          try {
                            await mealPlanProvider.assignRecipe(
                              key, slot, widget.recipe,
                            );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('$name added to $selectedDay · $label'),
                                action: SnackBarAction(
                                  label: 'View Planner',
                                  onPressed: () => router.go('/planner'),
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to save: $e')),
                            );
                          }
                        },
                      );
                    }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const Gap.xs(),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

class _IngredientsTab extends StatelessWidget {
  final List<String> ingredients;
  final int servings;
  final ValueChanged<int> onServingsChanged;
  final VoidCallback? onAddToGrocery;

  const _IngredientsTab({
    required this.ingredients,
    required this.servings,
    required this.onServingsChanged,
    this.onAddToGrocery,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: AppSpacing.paddingMd,
      children: [
        // Servings Adjuster
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Servings:', style: textTheme.bodyLarge),
            const HGap.md(),
            IconButton(
              onPressed: servings > 1
                  ? () => onServingsChanged(servings - 1)
                  : null,
              icon: Container(
                padding: AppSpacing.paddingXs,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.remove,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Text(
              '$servings',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              onPressed: () => onServingsChanged(servings + 1),
              icon: Container(
                padding: AppSpacing.paddingXs,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ),

        const Gap.md(),

        // Ingredients List
        ...ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          return ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            title: Text(ingredient),
          );
        }),

        const Gap.xl(),

        // Add to Grocery Button (only for signed-in users)
        if (onAddToGrocery != null)
          GradientButton(
            text: 'Add to Grocery List',
            icon: Icons.add_shopping_cart,
            onPressed: onAddToGrocery!,
          ),

        const Gap.lg(),
      ],
    );
  }
}

class _InstructionsTab extends StatelessWidget {
  final List<String> instructions;

  const _InstructionsTab({required this.instructions});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (instructions.isEmpty) {
      return const EmptyState(
        icon: Icons.list_alt,
        title: 'No instructions available',
        subtitle: 'Instructions for this recipe are not available yet',
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: instructions.length,
      itemBuilder: (context, index) {
        final step = instructions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const HGap.md(),
              Expanded(
                child: Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Text(step, style: textTheme.bodyLarge),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NutritionTab extends StatelessWidget {
  final Nutrition? nutrition;

  const _NutritionTab({this.nutrition});

  @override
  Widget build(BuildContext context) {
    if (nutrition == null) {
      return const EmptyState(
        icon: Icons.analytics_outlined,
        title: 'No nutrition info',
        subtitle: 'Nutrition information is not available for this recipe',
      );
    }

    return ListView(
      padding: AppSpacing.paddingMd,
      children: [
        const Gap.md(),
        Row(
          children: [
            Expanded(
              child: NutritionCard(
                label: 'Calories',
                value: nutrition!.calories.toString(),
                unit: 'kcal',
                icon: Icons.local_fire_department,
                color: AppColors.primaryOrange,
              ),
            ),
            const HGap.md(),
            Expanded(
              child: NutritionCard(
                label: 'Protein',
                value: nutrition!.protein,
                unit: 'g',
                icon: Icons.fitness_center,
                color: AppColors.accentGreen,
              ),
            ),
          ],
        ),
        const Gap.md(),
        Row(
          children: [
            Expanded(
              child: NutritionCard(
                label: 'Carbs',
                value: nutrition!.carbs,
                unit: 'g',
                icon: Icons.grain,
                color: AppColors.accentYellow,
              ),
            ),
            const HGap.md(),
            Expanded(
              child: NutritionCard(
                label: 'Fat',
                value: nutrition!.fat,
                unit: 'g',
                icon: Icons.water_drop,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
