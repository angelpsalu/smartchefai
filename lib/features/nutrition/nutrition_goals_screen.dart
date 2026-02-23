import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';

class NutritionGoalsScreen extends StatelessWidget {
  const NutritionGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Goals'),
        centerTitle: true,
      ),
      body: Consumer<NutritionProvider>(
        builder: (context, provider, _) {
          final uid = context.read<UserProvider>().currentUser?.id ?? '';
          final goals = provider.goals ?? NutritionGoals.defaults(uid);
          return ListView(
            padding: AppSpacing.paddingMd,
            children: [
              _SectionHeader(title: "Today's Progress"),
              const Gap.sm(),
              _MacroProgressCard(provider: provider, goals: goals),
              const Gap.lg(),
              _SectionHeader(title: "Today's Meals"),
              const Gap.sm(),
              _TodayMealsList(provider: provider),
              const Gap.lg(),
              _SectionHeader(
                title: 'Daily Goals',
                trailing: TextButton.icon(
                  onPressed: () => _showEditSheet(context, provider, goals),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const Gap.sm(),
              _GoalsSummaryCard(goals: goals),
              const Gap.lg(),
            ],
          );
        },
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    NutritionProvider provider,
    NutritionGoals goals,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditGoalsSheet(provider: provider, goals: goals),
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Macro Progress Card ─────────────────────────────────────────────────────

class _MacroProgressCard extends StatelessWidget {
  final NutritionProvider provider;
  final NutritionGoals goals;

  const _MacroProgressCard({required this.provider, required this.goals});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          children: [
            _MacroRow(
              label: 'Calories',
              consumed: provider.todayCalories,
              goal: goals.dailyCalories,
              unit: 'kcal',
            ),
            const Gap.sm(),
            _MacroRow(
              label: 'Protein',
              consumed: provider.todayProtein,
              goal: goals.dailyProtein,
              unit: 'g',
            ),
            const Gap.sm(),
            _MacroRow(
              label: 'Carbs',
              consumed: provider.todayCarbs,
              goal: goals.dailyCarbs,
              unit: 'g',
            ),
            const Gap.sm(),
            _MacroRow(
              label: 'Fat',
              consumed: provider.todayFat,
              goal: goals.dailyFat,
              unit: 'g',
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final int consumed;
  final int goal;
  final String unit;

  const _MacroRow({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = goal > 0 ? consumed / goal : 0.0;
    final isOver = ratio > 1.0;
    final barColor = isOver ? Theme.of(context).colorScheme.error : AppColors.primaryOrange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$consumed / $goal $unit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOver ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusSm,
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            color: barColor,
          ),
        ),
      ],
    );
  }
}

// ── Today's Meals List ──────────────────────────────────────────────────────

class _TodayMealsList extends StatelessWidget {
  final NutritionProvider provider;

  const _TodayMealsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final meals = provider.todayMeals;
    if (meals.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Center(
            child: Text(
              'No meals logged today.\nCook a recipe to track intake.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: meals.map((m) {
          return ListTile(
            leading: const Icon(Icons.restaurant_menu_outlined),
            title: Text(m.name, style: Theme.of(context).textTheme.bodyMedium),
            trailing: Text(
              '${m.calories} kcal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Daily Goals Summary ─────────────────────────────────────────────────────

class _GoalsSummaryCard extends StatelessWidget {
  final NutritionGoals goals;

  const _GoalsSummaryCard({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          children: [
            _GoalRow(label: 'Calories', value: '${goals.dailyCalories} kcal'),
            _GoalRow(label: 'Protein',  value: '${goals.dailyProtein} g'),
            _GoalRow(label: 'Carbs',    value: '${goals.dailyCarbs} g'),
            _GoalRow(label: 'Fat',      value: '${goals.dailyFat} g'),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String label;
  final String value;

  const _GoalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Edit Goals Bottom Sheet ─────────────────────────────────────────────────

class _EditGoalsSheet extends StatefulWidget {
  final NutritionProvider provider;
  final NutritionGoals goals;

  const _EditGoalsSheet({required this.provider, required this.goals});

  @override
  State<_EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends State<_EditGoalsSheet> {
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.goals;
    _calories = TextEditingController(text: g.dailyCalories.toString());
    _protein  = TextEditingController(text: g.dailyProtein.toString());
    _carbs    = TextEditingController(text: g.dailyCarbs.toString());
    _fat      = TextEditingController(text: g.dailyFat.toString());
  }

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final calories = int.tryParse(_calories.text) ?? 0;
    final protein  = int.tryParse(_protein.text) ?? 0;
    final carbs    = int.tryParse(_carbs.text) ?? 0;
    final fat      = int.tryParse(_fat.text) ?? 0;

    setState(() => _isSaving = true);
    await widget.provider.saveGoals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (widget.provider.error == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${widget.provider.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Daily Goals', style: Theme.of(context).textTheme.titleLarge),
              const Gap.lg(),
              _GoalField(controller: _calories, label: 'Calories', unit: 'kcal'),
              const Gap.md(),
              _GoalField(controller: _protein, label: 'Protein', unit: 'g'),
              const Gap.md(),
              _GoalField(controller: _carbs, label: 'Carbs', unit: 'g'),
              const Gap.md(),
              _GoalField(controller: _fat, label: 'Fat', unit: 'g'),
              const Gap.lg(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Goals'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;

  const _GoalField({
    required this.controller,
    required this.label,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
