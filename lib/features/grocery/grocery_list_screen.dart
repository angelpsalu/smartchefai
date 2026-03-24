import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final _textController = TextEditingController();
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<GroceryListProvider>();
    provider.addItem(
      GroceryItem(
        name: text,
        quantity: 1.0,
        unit: '',
        category: 'other',
        checked: false,
        recipes: [],
      ),
    );

    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: SmartChefAppBar(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart,
              color: AppColors.accentGreen,
            ),
            const HGap.sm(),
            Text(
              'Grocery List',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<GroceryListProvider>(
            builder: (context, provider, child) {
              return Tooltip(
                message: provider.isSynced ? 'Synced to cloud' : 'Local only',
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    provider.isSynced
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    color: provider.isSynced
                        ? AppColors.accentGreen
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          Consumer<GroceryListProvider>(
            builder: (context, provider, child) {
              final hasChecked = provider.items.any((item) => item.checked);
              return IconButton(
                onPressed: hasChecked
                    ? () => provider.clearCheckedItems()
                    : null,
                icon: Icon(
                  Icons.delete_sweep,
                  color: hasChecked ? colorScheme.error : null,
                ),
                tooltip: 'Clear checked items',
              );
            },
          ),
        ],
      ),
      body: Column(
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
                    controller: _textController,
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
                  return EmptyState(
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
                    // Unchecked Items
                    if (uncheckedItems.isNotEmpty) ...[
                      Text(
                        'To Buy (${uncheckedItems.length})',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap.sm(),
                      ...uncheckedItems.map((item) {
                        return GroceryItemTile(
                          name: item.name,
                          quantity: item.unit.isNotEmpty
                              ? '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}'
                              : '',
                          isChecked: item.checked,
                          onChanged: (value) {
                            provider.toggleItem(item.name);
                          },
                          onDelete: () {
                            provider.removeItem(item.name);
                          },
                        );
                      }),
                    ],

                    // Checked Items
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
                            onPressed: () => provider.clearCheckedItems(),
                            child: const Text('Clear all'),
                          ),
                        ],
                      ),
                      const Gap.sm(),
                      ...checkedItems.map((item) {
                        return GroceryItemTile(
                          name: item.name,
                          quantity: item.unit.isNotEmpty
                              ? '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}'
                              : '',
                          isChecked: item.checked,
                          onChanged: (value) {
                            provider.toggleItem(item.name);
                          },
                          onDelete: () {
                            provider.removeItem(item.name);
                          },
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
