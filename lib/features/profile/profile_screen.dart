import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'SC';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'SC';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  void _showLanguageDialog() {
    const languages = ['English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese'];
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<UserProvider>(
          builder: (context, provider, _) {
            return SimpleDialog(
              title: const Text('Select Language'),
              children: languages.map((lang) {
                return SimpleDialogOption(
                  onPressed: () {
                    provider.setLanguage(lang);
                    context.pop();
                  },
                  child: Row(
                    children: [
                      if (provider.selectedLanguage == lang)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      Text(lang),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Future<void> _handleAvatarTap() async {
    final userProvider = context.read<UserProvider>();
    final hasPhoto = userProvider.currentUser?.photoUrl != null;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  ctx.pop();
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 85,
                  );
                  if (image != null && mounted) {
                    await context.read<UserProvider>().uploadPhoto(image);
                  }
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: colorScheme.error),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  onTap: () async {
                    ctx.pop();
                    await context.read<UserProvider>().removePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut() async {
    final userProvider = context.read<UserProvider>();
    context.pop();
    await userProvider.logout();
    if (!mounted) return;
    context.go('/get-started');
  }

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
                Consumer<UserProvider>(
                  builder: (context, provider, child) {
                    final user = provider.currentUser;
                    return ProfileAvatar(
                      size: 100,
                      imageUrl: user?.photoUrl,
                      initials: _getInitials(user?.name),
                      showEditButton: true,
                      onTap: _handleAvatarTap,
                    );
                  },
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
          ),

          const Gap.xl(),

          // Stats Cards
          Consumer2<RecipeProvider, UserProvider>(
            builder: (context, recipeProvider, userProvider, _) {
              final user = userProvider.appUser;
              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite,
                      label: 'Favorites',
                      value: recipeProvider.favoriteRecipes.length.toString(),
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const HGap.md(),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.restaurant_menu,
                      label: 'Recipes Made',
                      value: (user?.recipesCooked ?? 0).toString(),
                      color: AppColors.accentGreen,
                    ),
                  ),
                  const HGap.md(),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      label: 'Streak',
                      value: '${user?.currentStreak ?? 0} days',
                      color: AppColors.accentYellow,
                    ),
                  ),
                ],
              );
            },
          ),

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
                onTap: () => context.push('/nutrition-goals'),
              ),
            ],
          ),

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
              Consumer<UserProvider>(
                builder: (context, provider, child) {
                  return SettingsTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Meal reminders, tips',
                    trailing: Switch(
                      value: provider.notificationsEnabled,
                      onChanged: (value) => provider.toggleNotifications(),
                    ),
                  );
                },
              ),
              Consumer<UserProvider>(
                builder: (context, provider, child) {
                  return SettingsTile(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: provider.selectedLanguage,
                    onTap: _showLanguageDialog,
                  );
                },
              ),
            ],
          ),

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
                onTap: () => _launchUrl('https://github.com/topics/smartchefai'),
              ),
              SettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                onTap: () => _launchUrl(
                  'mailto:feedback@smartchef.ai?subject=SmartChef%20AI%20Feedback',
                ),
              ),
              SettingsTile(
                icon: Icons.star_outline,
                title: 'Rate the App',
                onTap: () => _launchUrl(
                  'https://play.google.com/store/apps/details?id=com.example.smartchefai',
                ),
              ),
              SettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
            ],
          ),

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
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: _handleSignOut,
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
          ),

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
