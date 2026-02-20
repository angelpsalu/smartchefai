import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/widgets.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  List<String> _detectedIngredients = [];
  XFile? _selectedImage;
  List<Recipe> _scanRecipes = [];
  bool _isSearching = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isProcessing = true;
        });

        try {
          final detected = await FirebaseService().analyzeImage(image);
          if (!mounted) return;
          setState(() {
            _detectedIngredients = detected.map((d) => d.name).toList();
            _isProcessing = false;
          });

          if (_detectedIngredients.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No ingredients detected. Try a clearer photo.'),
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Analysis failed: ${e.toString()}')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _searchRecipes() async {
    if (_detectedIngredients.isEmpty) return;
    setState(() => _isSearching = true);

    final results = await context.read<RecipeProvider>().searchByIngredients(_detectedIngredients);

    if (!mounted) return;
    setState(() {
      _scanRecipes = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: SmartChefAppBar(
        showBackButton: true,
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner, color: colorScheme.primary),
            const HGap.sm(),
            const Text('Scan Ingredients'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.5),
                    colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const HGap.md(),
                  Expanded(
                    child: Text(
                      'Take a photo of your fridge or pantry, and our AI will detect ingredients and suggest recipes!',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

            const Gap.xl(),

            // Image Preview / Camera Options
            if (_selectedImage == null) ...[
              // Camera Option
              _ScanOption(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Capture your ingredients',
                gradient: AppColors.primaryGradient,
                onTap: () => _pickImage(ImageSource.camera),
              ),

              const Gap.md(),

              // Gallery Option
              _ScanOption(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select an existing photo',
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentGreen,
                    AppColors.accentGreen.withValues(alpha: 0.7),
                  ],
                ),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ] else ...[
              // Preview Image
              ClipRRect(
                borderRadius: AppSpacing.borderRadiusLg,
                child: Stack(
                  children: [
                    Image.file(
                      File(_selectedImage!.path),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const Gap.sm(),
                                Text(
                                  'Image Preview',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (_isProcessing)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                                const Gap.md(),
                                Text(
                                  'Analyzing ingredients...',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _detectedIngredients = [];
                            _scanRecipes = [];
                          });
                        },
                        icon: Container(
                          padding: AppSpacing.paddingXs,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Detected Ingredients
            if (_detectedIngredients.isNotEmpty) ...[
              const Gap.xl(),

              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: colorScheme.primary,
                  ),
                  const HGap.sm(),
                  Text(
                    'Detected Ingredients',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const Gap.md(),

              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _detectedIngredients.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ingredient = entry.value;
                  return IngredientChip(
                    name: ingredient,
                    isDetected: true,
                    isSelected: true,
                    onRemove: () {
                      setState(() {
                        _detectedIngredients.removeAt(index);
                      });
                    },
                  );
                }).toList(),
              ),

              const Gap.xl(),

              GradientButton(
                text: 'Find Recipes',
                icon: Icons.search,
                onPressed: _searchRecipes,
              ),

              const Gap.md(),

              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Again'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],

            // Search loading indicator
            if (_isSearching) ...[
              const Gap.xl(),
              const Center(child: CircularProgressIndicator()),
              const Gap.sm(),
              Center(
                child: Text(
                  'Finding matching recipes...',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],

            // Inline recipe results
            if (_scanRecipes.isNotEmpty) ...[
              const Gap.xl(),
              Row(
                children: [
                  Icon(Icons.restaurant_menu, color: colorScheme.primary),
                  const HGap.sm(),
                  Text(
                    '${_scanRecipes.length} recipes found',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Gap.md(),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: _scanRecipes.length,
                  separatorBuilder: (_, __) => const HGap.md(),
                  itemBuilder: (context, index) {
                    final recipe = _scanRecipes[index];
                    return SizedBox(
                      width: 160,
                      child: RecipeCard(
                        id: recipe.id,
                        title: recipe.name,
                        imageUrl: recipe.imageUrl,
                        cookTime: '${recipe.prepTime + recipe.cookTime} min',
                        difficulty: recipe.difficulty,
                        rating: recipe.rating,
                        isFavorite: context
                            .watch<RecipeProvider>()
                            .isFavorite(recipe.id),
                        onTap: () => context.push(
                          '/recipe/${recipe.id}',
                          extra: recipe,
                        ),
                        onFavoriteTap: () => context
                            .read<RecipeProvider>()
                            .toggleFavorite(recipe.id),
                      ),
                    );
                  },
                ),
              ),
              const Gap.lg(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ScanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingXl,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const HGap.lg(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
