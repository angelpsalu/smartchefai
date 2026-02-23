import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/widgets.dart';
import '../../utils/meal_classifier.dart';

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
      // Only load if not yet loaded — avoids overwriting in-memory state
      // that was just set by assignRecipe() (race condition with ShellRoute rebuild)
      final mealPlanProv = context.read<MealPlanProvider>();
      if (!mealPlanProv.hasLoaded && !mealPlanProv.isLoading) {
        mealPlanProv.loadMealPlan();
      }
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

  static const Map<String, IconData> _slotIcons = {
    'breakfast': Icons.free_breakfast,
    'lunch': Icons.lunch_dining,
    'dinner': Icons.dinner_dining,
    'snack': Icons.coffee,
  };

  Future<void> _showRecipePickerSheet(
    BuildContext context,
    String day,
    String slot,
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

    // Sort recipes: suggested for this slot first
    final sortedRecipes = MealClassifier.sortedForSlot(allRecipes, slot);
    final suggestedCount = MealClassifier.suggestedCount(allRecipes, slot);

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
                ? sortedRecipes
                : sortedRecipes
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
                        color: Theme.of(ctx).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: AppSpacing.paddingHorizontalMd,
                      child: Text(
                        'Add ${slot[0].toUpperCase()}${slot.substring(1)} · $day',
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
                              itemCount: filtered.length + (query.isEmpty && suggestedCount > 0 && slot != 'dinner' ? 2 : 0),
                              itemBuilder: (_, i) {
                                // Section headers for suggested/all
                                if (query.isEmpty && suggestedCount > 0 && slot != 'dinner') {
                                  if (i == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.xs,
                                      ),
                                      child: Text(
                                        'Suggested for ${slot[0].toUpperCase()}${slot.substring(1)}',
                                        style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                                          color: AppColors.primaryOrange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }
                                  if (i == suggestedCount + 1) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.xs,
                                      ),
                                      child: Text(
                                        'All Recipes',
                                        style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }
                                  final recipeIndex = i <= suggestedCount ? i - 1 : i - 2;
                                  if (recipeIndex < 0 || recipeIndex >= filtered.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final recipe = filtered[recipeIndex];
                                  return _RecipePickerTile(
                                    recipe: recipe,
                                    onTap: () async {
                                      Navigator.of(sheetCtx).pop();
                                      await mealPlanProvider.assignRecipe(
                                        day.toLowerCase(), slot, recipe,
                                      );
                                    },
                                  );
                                }

                                final recipe = filtered[i];
                                return _RecipePickerTile(
                                  recipe: recipe,
                                  onTap: () async {
                                    Navigator.of(sheetCtx).pop();
                                    await mealPlanProvider.assignRecipe(
                                      day.toLowerCase(), slot, recipe,
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
        // Check if any slot across any day has a recipe
        final hasPlanned = plan?.days.values.any(
          (slots) => slots.values.any((id) => id != null),
        ) ?? false;

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
              child: ListView.builder(
                padding: AppSpacing.paddingMd,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final day = _dayLabels[index];
                  final dayKey = day.toLowerCase();
                  final daySlots = plan?.days[dayKey] ?? {};
                  final filledSlots = daySlots.values.where((v) => v != null).length;

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: filledSlots > 0
                                ? AppColors.primaryOrange.withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Center(
                            child: Text(
                              day.substring(0, 3),
                              style: textTheme.labelLarge?.copyWith(
                                color: filledSlots > 0
                                    ? AppColors.primaryOrange
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          day,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          filledSlots > 0
                              ? '$filledSlots meal${filledSlots > 1 ? 's' : ''} planned'
                              : 'No meals planned',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        children: [
                          for (final slot in MealPlan.mealSlots)
                            _MealSlotTile(
                              slot: slot,
                              icon: _slotIcons[slot] ?? Icons.restaurant,
                              recipeId: daySlots[slot],
                              recipeName: daySlots[slot] != null
                                  ? provider.assignedRecipes[daySlots[slot]]?.name
                                  : null,
                              recipeImage: daySlots[slot] != null
                                  ? provider.assignedRecipes[daySlots[slot]]?.imageUrl
                                  : null,
                              onAdd: () => _showRecipePickerSheet(
                                context, day, slot, provider,
                              ),
                              onRemove: daySlots[slot] != null
                                  ? () => provider.removeRecipe(dayKey, slot)
                                  : null,
                            ),
                        ],
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

class _MealSlotTile extends StatelessWidget {
  final String slot;
  final IconData icon;
  final String? recipeId;
  final String? recipeName;
  final String? recipeImage;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const _MealSlotTile({
    required this.slot,
    required this.icon,
    this.recipeId,
    this.recipeName,
    this.recipeImage,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasRecipe = recipeId != null;
    final label = '${slot[0].toUpperCase()}${slot.substring(1)}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      leading: hasRecipe && recipeImage != null
          ? ClipRRect(
              borderRadius: AppSpacing.borderRadiusSm,
              child: CachedNetworkImage(
                imageUrl: recipeImage!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: AppColors.primaryOrange.withValues(alpha: 0.15),
                  child: Icon(icon, size: 20),
                ),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            ),
      title: Text(
        hasRecipe ? recipeName ?? recipeId! : label,
        style: textTheme.bodyMedium?.copyWith(
          color: hasRecipe ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          fontWeight: hasRecipe ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      subtitle: hasRecipe
          ? null
          : Text(
              'Tap to add $label',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
      trailing: hasRecipe
          ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
            )
          : Icon(Icons.add_circle_outline, color: colorScheme.primary, size: 20),
      onTap: onAdd,
    );
  }
}

class _RecipePickerTile extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipePickerTile({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.primaryOrange.withValues(alpha: 0.15),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 48,
            height: 48,
            color: AppColors.primaryOrange.withValues(alpha: 0.15),
            child: const Icon(Icons.restaurant),
          ),
        ),
      ),
      title: Text(recipe.name),
      subtitle: Text(
        '${recipe.prepTime + recipe.cookTime} min · ${recipe.difficulty}',
      ),
      onTap: onTap,
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
            category: 'Other',
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

  static const _categoryOrder = [
    'Produce', 'Dairy', 'Meat & Seafood', 'Bakery', 'Spices & Herbs', 'Pantry', 'Other', 'meal-plan', 'other',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Produce': Icons.eco,
    'Dairy': Icons.egg_alt,
    'Meat & Seafood': Icons.set_meal,
    'Bakery': Icons.bakery_dining,
    'Spices & Herbs': Icons.grass,
    'Pantry': Icons.kitchen,
    'Other': Icons.shopping_bag,
    'meal-plan': Icons.calendar_month,
    'other': Icons.shopping_bag,
  };

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

        // Items List grouped by category
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

              // Group unchecked items by category
              final grouped = <String, List<GroceryItem>>{};
              for (final item in uncheckedItems) {
                final cat = item.category.isEmpty ? 'Other' : item.category;
                grouped.putIfAbsent(cat, () => []).add(item);
              }

              // Sort categories
              final sortedCategories = grouped.keys.toList()
                ..sort((a, b) {
                  final ai = _categoryOrder.indexOf(a);
                  final bi = _categoryOrder.indexOf(b);
                  return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
                });

              return ListView(
                padding: AppSpacing.paddingMd,
                children: [
                  // Grouped unchecked items
                  for (final category in sortedCategories) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _categoryIcons[category] ?? Icons.shopping_bag,
                            size: 18,
                            color: AppColors.primaryOrange,
                          ),
                          const HGap.sm(),
                          Text(
                            category,
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const HGap.sm(),
                          Text(
                            '(${grouped[category]!.length})',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...grouped[category]!.map((item) => GroceryItemTile(
                          name: item.name,
                          quantity: _formatQuantity(item),
                          isChecked: item.checked,
                          onChanged: (_) => provider.toggleItem(item.name),
                          onDelete: () => provider.removeItem(item.name),
                          subtitle: item.recipes.isNotEmpty
                              ? 'From: ${item.recipes.join(", ")}'
                              : null,
                        )),
                  ],

                  // Completed section
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
