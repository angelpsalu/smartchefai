import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme/theme.dart';
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isProcessing = true;
        });

        // Simulate AI processing
        await Future.delayed(const Duration(seconds: 2));

        // Mock detected ingredients
        setState(() {
          _detectedIngredients = [
            'Tomatoes',
            'Onion',
            'Garlic',
            'Bell Pepper',
            'Olive Oil',
            'Basil',
          ];
          _isProcessing = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _searchRecipes() {
    if (_detectedIngredients.isEmpty) return;

    Navigator.pushNamed(
      context,
      '/search',
      arguments: {'ingredients': _detectedIngredients},
    );
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
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

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
                  ).animate(delay: (50 * index).ms).fadeIn().scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
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
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0);
  }
}
