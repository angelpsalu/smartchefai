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
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveToCloud() async {
    final provider = context.read<GroceryListProvider>();
    if (provider.items.isEmpty) return;

    setState(() => _isSaving = true);
    final listId = await provider.createGroceryList('', []);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (listId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grocery list saved to cloud!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save list. Check your connection.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _addItem() {
    if (_textController.text.isEmpty) return;

    final provider = context.read<GroceryListProvider>();
    provider.addItem(
      GroceryItem(
        name: _textController.text,
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
              final hasItems = provider.items.isNotEmpty;
              return _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: hasItems ? _saveToCloud : null,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      tooltip: 'Save list to cloud',
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
                          quantity: '${item.quantity} ${item.unit}'.trim(),
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
                          quantity: '${item.quantity} ${item.unit}'.trim(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Voice add item
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice input coming soon!')),
          );
        },
        icon: const Icon(Icons.mic),
        label: const Text('Add by Voice'),
      ),
    );
  }
}
