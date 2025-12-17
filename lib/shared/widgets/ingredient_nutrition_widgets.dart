import 'package:flutter/material.dart';
import '../../app/theme/theme.dart';

/// Ingredient Chip for displaying detected or selected ingredients
class IngredientChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isDetected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const IngredientChip({
    super.key,
    required this.name,
    this.isSelected = false,
    this.isDetected = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: _getBackgroundColor(colorScheme),
        borderRadius: AppSpacing.borderRadiusFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDetected) ...[
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const HGap.xxs(),
                ],
                Text(
                  name,
                  style: textTheme.labelMedium?.copyWith(
                    color: _getTextColor(colorScheme),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (onRemove != null) ...[
                  const HGap.xxs(),
                  GestureDetector(
                    onTap: onRemove,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (isSelected) return colorScheme.primaryContainer;
    if (isDetected) return colorScheme.tertiaryContainer;
    return colorScheme.surfaceContainerHighest;
  }

  Color _getTextColor(ColorScheme colorScheme) {
    if (isSelected) return colorScheme.onPrimaryContainer;
    if (isDetected) return colorScheme.onTertiaryContainer;
    return colorScheme.onSurfaceVariant;
  }
}

/// Nutrition Info Card
class NutritionCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color? color;

  const NutritionCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: effectiveColor,
            size: 24,
          ),
          const Gap.sm(),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          ),
          Text(
            unit,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap.xs(),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grocery Item Tile
class GroceryItemTile extends StatelessWidget {
  final String name;
  final String? quantity;
  final bool isChecked;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onDelete;

  const GroceryItemTile({
    super.key,
    required this.name,
    this.quantity,
    required this.isChecked,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: isChecked
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        leading: Checkbox(
          value: isChecked,
          onChanged: onChanged,
          shape: const CircleBorder(),
        ),
        title: Text(
          name,
          style: textTheme.bodyLarge?.copyWith(
            decoration: isChecked ? TextDecoration.lineThrough : null,
            color: isChecked ? colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: quantity != null
            ? Text(
                quantity!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: colorScheme.error,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

/// Profile Avatar
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final VoidCallback? onTap;
  final bool showEditButton;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 80,
    this.onTap,
    this.showEditButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitials(
                        colorScheme,
                        textTheme,
                      ),
                    ),
                  )
                : _buildInitials(colorScheme, textTheme),
          ),
          if (showEditButton)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: size * 0.2,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitials(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Text(
        initials ?? 'U',
        style: textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Settings/Profile List Tile
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: AppSpacing.paddingSm,
        decoration: BoxDecoration(
          color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: Icon(
          icon,
          color: iconColor ?? colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
    );
  }
}
