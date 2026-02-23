import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/widgets.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _addItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealPlanProvider>().loadMealPlan();
      context.read<GroceryListProvider>().syncOnLogin();
      // Ensure recipes are available for the picker
      if (context.read<RecipeProvider>().recipes.isEmpty) {
        context.read<RecipeProvider>().loadRecipes();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.primaryOrange),
            const HGap.sm(),
            Text(
              'Planner',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu_outlined), text: 'Meal Plan'),
            Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Shopping List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MealPlanTab(onSwitchToShopping: () => _tabController.animateTo(1)),
          _GroceryTab(controller: _addItemController),
        ],
      ),
    );
  }
}

// ── Meal Plan Tab ─────────────────────────────────────────────────────────────

class _MealPlanTab extends StatelessWidget {
  final VoidCallback? onSwitchToShopping;

  const _MealPlanTab({this.onSwitchToShopping});

  static const List<String> _dayLabels = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  Future<void> _showRecipePickerSheet(
    BuildContext context,
    String day,
    MealPlanProvider mealPlanProvider,
  ) async {
    final allRecipes = context.read<RecipeProvider>().recipes;

    if (allRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recipes loaded yet. Go to Home tab and pull to refresh.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        var query = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = query.isEmpty
                ? allRecipes
                : allRecipes
                    .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
                    .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (_, scrollCtrl) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: AppSpacing.paddingHorizontalMd,
                      child: Text(
                        'Add recipe to $day',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: TextField(
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Search recipes...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: AppSpacing.borderRadiusMd,
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(ctx).colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        onChanged: (v) => setSheetState(() => query = v),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No recipes found'))
                          : ListView.builder(
                              controller: scrollCtrl,
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final recipe = filtered[i];
                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: AppSpacing.borderRadiusSm,
                                    child: CachedNetworkImage(
                                      imageUrl: recipe.imageUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        width: 48,
                                        height: 48,
                                        color: AppColors.primaryOrange
                                            .withValues(alpha: 0.15),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: AppColors.primaryOrange
                                            .withValues(alpha: 0.15),
                                        child: const Icon(Icons.restaurant),
                                      ),
                                    ),
                                  ),
                                  title: Text(recipe.name),
                                  subtitle: Text(
                                    '${recipe.prepTime + recipe.cookTime} min · ${recipe.difficulty}',
                                  ),
                                  onTap: () async {
                                    Navigator.of(sheetCtx).pop();
                                    await mealPlanProvider.assignRecipe(
                                      day.toLowerCase(),
                                      recipe,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<MealPlanProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.error!, textAlign: TextAlign.center),
                const Gap.md(),
                ElevatedButton(
                  onPressed: provider.loadMealPlan,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final plan = provider.mealPlan;
        final plannedIds = plan?.days.values.whereType<String>().toList() ?? [];
        final hasPlanned = plannedIds.isNotEmpty;

        return Column(
          children: [
            if (hasPlanned)
              Padding(
                padding: AppSpacing.paddingMd,
                child: FilledButton.icon(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Add all ingredients to Shopping List'),
                  onPressed: () {
                    final items = provider.generateGroceryItems();
                    context.read<GroceryListProvider>().addItems(items);
                    onSwitchToShopping?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${items.length} ingredients added to shopping list',
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                      padding: AppSpacing.paddingMd,
                      itemCount: 7,
                      separatorBuilder: (_, __) => const Gap.sm(),
                      itemBuilder: (context, index) {
                        final day = _dayLabels[index];
                        final recipeId = plan?.days[day.toLowerCase()];
                        final hasRecipe = recipeId != null;
                        final recipeName = hasRecipe
                            ? (provider.assignedRecipes[recipeId]?.name ?? recipeId)
                            : null;

                        return Card(
                          child: ListTile(
                            onTap: () => _showRecipePickerSheet(
                              context,
                              day,
                              provider,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: hasRecipe
                                    ? AppColors.primaryOrange
                                        .withValues(alpha: 0.15)
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: AppSpacing.borderRadiusMd,
                              ),
                              child: Center(
                                child: Text(
                                  day.substring(0, 3),
                                  style: textTheme.labelMedium?.copyWith(
                                    color: hasRecipe
                                        ? AppColors.primaryOrange
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              hasRecipe ? recipeName! : 'Tap to add a recipe',
                              style: textTheme.bodyMedium?.copyWith(
                                color: hasRecipe
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: hasRecipe
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () =>
                                        provider.removeRecipe(day.toLowerCase()),
                                  )
                                : Icon(
                                    Icons.add_circle_outline,
                                    color: colorScheme.primary,
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Grocery Tab ───────────────────────────────────────────────────────────────

class _GroceryTab extends StatefulWidget {
  final TextEditingController controller;

  const _GroceryTab({required this.controller});

  @override
  State<_GroceryTab> createState() => _GroceryTabState();
}

class _GroceryTabState extends State<_GroceryTab> {
  void _addItem() {
    if (widget.controller.text.isEmpty) return;
    context.read<GroceryListProvider>().addItem(
          GroceryItem(
            name: widget.controller.text,
            quantity: 1.0,
            unit: '',
            category: 'other',
            checked: false,
            recipes: [],
          ),
        );
    widget.controller.clear();
  }

  String _formatQuantity(GroceryItem item) {
    if (item.unit.isEmpty) return '';
    final qty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(1);
    return '$qty ${item.unit}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Add Item Input
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hintText: 'Add grocery item...',
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              const HGap.sm(),
              IconButton.filled(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: Consumer<GroceryListProvider>(
            builder: (context, provider, child) {
              final items = provider.items;

              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your list is empty',
                  subtitle: 'Add items manually or from a recipe',
                );
              }

              final uncheckedItems = items.where((i) => !i.checked).toList();
              final checkedItems = items.where((i) => i.checked).toList();

              return ListView(
                padding: AppSpacing.paddingMd,
                children: [
                  if (uncheckedItems.isNotEmpty) ...[
                    Text(
                      'To Buy (${uncheckedItems.length})',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap.sm(),
                    ...uncheckedItems.map((item) => GroceryItemTile(
                          name: item.name,
                          quantity: _formatQuantity(item),
                          isChecked: item.checked,
                          onChanged: (_) => provider.toggleItem(item.name),
                          onDelete: () => provider.removeItem(item.name),
                        )),
                  ],
                  if (checkedItems.isNotEmpty) ...[
                    const Gap.lg(),
                    Row(
                      children: [
                        Text(
                          'Completed (${checkedItems.length})',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: provider.clearCheckedItems,
                          child: const Text('Clear all'),
                        ),
                      ],
                    ),
                    const Gap.sm(),
                    ...checkedItems.map((item) => GroceryItemTile(
                          name: item.name,
                          quantity: _formatQuantity(item),
                          isChecked: item.checked,
                          onChanged: (_) => provider.toggleItem(item.name),
                          onDelete: () => provider.removeItem(item.name),
                        )),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
