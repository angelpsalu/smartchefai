import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const SmartChefAppBar(
        title: 'Profile',
        actions: [],
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                const ProfileAvatar(
                  size: 100,
                  initials: 'SC',
                  showEditButton: true,
                ),
                const Gap.md(),
                Consumer<UserProvider>(
                  builder: (context, provider, child) {
                    final user = provider.currentUser;
                    return Column(
                      children: [
                        Text(
                          user?.name ?? 'Smart Chef',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user?.email ?? 'chef@smartchef.ai',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),

          const Gap.xl(),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.favorite,
                  label: 'Favorites',
                  value: context.watch<RecipeProvider>().favoriteRecipes.length.toString(),
                  color: AppColors.primaryOrange,
                ),
              ),
              const HGap.md(),
              Expanded(
                child: _StatCard(
                  icon: Icons.restaurant_menu,
                  label: 'Recipes Made',
                  value: '12',
                  color: AppColors.accentGreen,
                ),
              ),
              const HGap.md(),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '5 days',
                  color: AppColors.accentYellow,
                ),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),

          const Gap.xl(),

          // Settings Sections
          Text(
            'Preferences',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap.md(),

          _SettingsCard(
            children: [
              SettingsTile(
                icon: Icons.restaurant,
                title: 'Dietary Preferences',
                subtitle: 'Vegetarian, Gluten-free...',
                onTap: () => context.push('/dietary-preferences'),
              ),
              SettingsTile(
                icon: Icons.no_food,
                title: 'Allergies',
                subtitle: 'Set your food allergies',
                onTap: () => context.push('/dietary-preferences'),
              ),
              SettingsTile(
                icon: Icons.calculate,
                title: 'Nutrition Goals',
                subtitle: 'Daily calorie targets',
                onTap: () {},
              ),
            ],
          ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.1, end: 0),

          const Gap.lg(),

          Text(
            'App Settings',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap.md(),

          _SettingsCard(
            children: [
              Consumer<UserProvider>(
                builder: (context, provider, child) {
                  return SettingsTile(
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: provider.isDarkMode,
                      onChanged: (value) => provider.toggleDarkMode(),
                    ),
                  );
                },
              ),
              SettingsTile(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Meal reminders, tips',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              SettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
                onTap: () {},
              ),
            ],
          ).animate(delay: 300.ms).fadeIn().slideX(begin: 0.1, end: 0),

          const Gap.lg(),

          Text(
            'Support',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap.md(),

          _SettingsCard(
            children: [
              SettingsTile(
                icon: Icons.help_outline,
                title: 'Help & FAQ',
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.star_outline,
                title: 'Rate the App',
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
            ],
          ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.1, end: 0),

          const Gap.xl(),

          // Logout Button
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Sign out logic
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.logout, color: colorScheme.error),
            label: Text(
              'Sign Out',
              style: TextStyle(color: colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.error),
              minimumSize: const Size(double.infinity, 48),
            ),
          ).animate(delay: 500.ms).fadeIn(),

          const Gap.xxxl(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const Gap.xs(),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          return Column(
            children: [
              child,
              if (index < children.length - 1)
                Divider(
                  height: 1,
                  indent: 56,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
