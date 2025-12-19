import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/app_providers.dart';
import 'package:go_router/go_router.dart';

class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  State<DietaryPreferencesScreen> createState() => _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> {
  // Dietary preferences
  final Set<String> _selectedPreferences = {};
  final Set<String> _selectedAllergies = {};

  final List<String> _availablePreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Low-Carb',
    'Keto',
    'Paleo',
    'Pescatarian',
    'Halal',
    'Kosher',
    'Low-Sodium',
    'High-Protein',
  ];

  final List<String> _commonAllergies = [
    'Peanuts',
    'Tree Nuts',
    'Milk',
    'Eggs',
    'Wheat',
    'Soy',
    'Fish',
    'Shellfish',
    'Sesame',
    'Mustard',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    
    if (user != null) {
      setState(() {
        _selectedPreferences.addAll(user.dietaryPreferences);
        _selectedAllergies.addAll(user.allergies);
      });
    }
  }

  void _savePreferences() async {
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.setPreferences(
      _selectedPreferences.toList(),
      _selectedAllergies.toList(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Preferences saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save preferences'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: SmartChefAppBar(
        title: 'Dietary Preferences',
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // Dietary Preferences Section
          Text(
            'Dietary Preferences',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
          
          const Gap.sm(),
          
          Text(
            'Select your dietary preferences to get personalized recipe recommendations',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 100.ms).fadeIn(),
          
          const Gap.lg(),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availablePreferences.map((pref) {
              final isSelected = _selectedPreferences.contains(pref);
              return FilterChip(
                label: Text(pref),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPreferences.add(pref);
                    } else {
                      _selectedPreferences.remove(pref);
                    }
                  });
                },
                selectedColor: AppColors.primaryOrange.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primaryOrange,
              ).animate(delay: (50 * _availablePreferences.indexOf(pref)).ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
            }).toList(),
          ),
          
          const Gap.xxl(),
          
          // Allergies Section
          Text(
            'Allergies & Intolerances',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: -0.2, end: 0),
          
          const Gap.sm(),
          
          Text(
            'Let us know about any food allergies or intolerances',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ).animate(delay: 300.ms).fadeIn(),
          
          const Gap.lg(),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonAllergies.map((allergy) {
              final isSelected = _selectedAllergies.contains(allergy);
              return FilterChip(
                label: Text(allergy),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAllergies.add(allergy);
                    } else {
                      _selectedAllergies.remove(allergy);
                    }
                  });
                },
                selectedColor: Colors.red.withValues(alpha: 0.2),
                checkmarkColor: Colors.red,
              ).animate(delay: (50 * _commonAllergies.indexOf(allergy)).ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
            }).toList(),
          ),
          
          const Gap.xxxl(),
          
          // Save Button
          GradientButton(
            text: 'Save Preferences',
            gradient: AppColors.primaryGradient,
            onPressed: _savePreferences,
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),
          
          const Gap.xl(),
        ],
      ),
    );
  }
}
