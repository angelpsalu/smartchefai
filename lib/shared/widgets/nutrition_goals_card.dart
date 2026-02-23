import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme.dart';
import '../../providers/app_providers.dart';

/// Compact card showing daily nutrition progress with circular indicators.
class NutritionGoalsCard extends StatelessWidget {
  const NutritionGoalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<NutritionProvider>();
    final goals = provider.goals;

    if (goals == null) {
      return Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: InkWell(
          onTap: () => _showSetGoalsDialog(context, provider),
          borderRadius: AppSpacing.borderRadiusMd,
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Icon(
                    Icons.track_changes,
                    color: AppColors.accentGreen,
                  ),
                ),
                const HGap.md(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Nutrition Goals',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Track your daily calorie and macro intake',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Today's Nutrition",
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showSetGoalsDialog(context, provider),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Gap.md(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NutritionRing(
                  label: 'Calories',
                  current: provider.todayCalories,
                  goal: goals.dailyCalories,
                  unit: 'kcal',
                  color: AppColors.primaryOrange,
                ),
                _NutritionRing(
                  label: 'Protein',
                  current: provider.todayProtein,
                  goal: goals.dailyProtein,
                  unit: 'g',
                  color: AppColors.accentGreen,
                ),
                _NutritionRing(
                  label: 'Carbs',
                  current: provider.todayCarbs,
                  goal: goals.dailyCarbs,
                  unit: 'g',
                  color: AppColors.accentYellow,
                ),
                _NutritionRing(
                  label: 'Fat',
                  current: provider.todayFat,
                  goal: goals.dailyFat,
                  unit: 'g',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSetGoalsDialog(BuildContext context, NutritionProvider provider) {
    final goals = provider.goals;
    final calCtrl = TextEditingController(
      text: goals?.dailyCalories.toString() ?? '2000',
    );
    final proteinCtrl = TextEditingController(
      text: goals?.dailyProtein.toString() ?? '150',
    );
    final carbsCtrl = TextEditingController(
      text: goals?.dailyCarbs.toString() ?? '250',
    );
    final fatCtrl = TextEditingController(
      text: goals?.dailyFat.toString() ?? '65',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Daily Goals'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: calCtrl,
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal)',
                  prefixIcon: Icon(Icons.local_fire_department),
                ),
                keyboardType: TextInputType.number,
              ),
              const Gap.sm(),
              TextField(
                controller: proteinCtrl,
                decoration: const InputDecoration(
                  labelText: 'Protein (g)',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                keyboardType: TextInputType.number,
              ),
              const Gap.sm(),
              TextField(
                controller: carbsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Carbs (g)',
                  prefixIcon: Icon(Icons.grain),
                ),
                keyboardType: TextInputType.number,
              ),
              const Gap.sm(),
              TextField(
                controller: fatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Fat (g)',
                  prefixIcon: Icon(Icons.water_drop),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.saveGoals(
                calories: int.tryParse(calCtrl.text) ?? 2000,
                protein: int.tryParse(proteinCtrl.text) ?? 150,
                carbs: int.tryParse(carbsCtrl.text) ?? 250,
                fat: int.tryParse(fatCtrl.text) ?? 65,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _NutritionRing extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final String unit;
  final Color color;

  const _NutritionRing({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round,
              ),
              Text(
                '$current',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '/ $goal$unit',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
