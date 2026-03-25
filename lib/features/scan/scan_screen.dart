import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/firebase_service.dart';
import '../../services/voice_search_service.dart';
import '../../shared/widgets/widgets.dart';
import '../../utils/ingredient_parser.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final VoiceSearchService _voiceService = VoiceSearchService();
  bool _isProcessing = false;
  List<String> _detectedIngredients = [];
  XFile? _selectedImage;
  List<({Recipe recipe, int matchCount})> _scanRecipes = [];
  int _totalRequested = 0;
  bool _hasSearched = false;
  bool _isSearching = false;
  String _inputSource = ''; // 'camera', 'gallery', or 'voice'

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
          _inputSource = source == ImageSource.camera ? 'camera' : 'gallery';
          // Reset previous search state so stale "No recipes found" doesn't
          // flash when the user switches from voice → camera/gallery.
          _detectedIngredients = [];
          _scanRecipes = [];
          _hasSearched = false;
          _totalRequested = 0;
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
          final msg = e.toString().contains('VISION_API_KEY')
              ? 'Ingredient scanning is unavailable. Please try again later.'
              : 'Could not analyse image. Please try a clearer photo.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open camera. Please try again.')),
      );
    }
  }

  Future<void> _onVoiceInput() async {
    final result = await showVoiceSearchOverlay(
      context: context,
      service: _voiceService,
      mode: VoiceOverlayMode.ingredientInput,
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      final parsed = IngredientParser.parse(result);

      if (parsed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not detect ingredients. Try saying them separated by commas.'),
          ),
        );
        return;
      }

      setState(() {
        _detectedIngredients = parsed;
        _selectedImage = null;
        _inputSource = 'voice';
        _scanRecipes = [];
        _hasSearched = false;
      });

      // Auto-trigger recipe search for voice input
      _searchRecipes();
    }
  }

  Future<void> _searchRecipes() async {
    if (_detectedIngredients.isEmpty) return;

    // Set _totalRequested before await so it reflects post-removal chip count.
    final requested = _detectedIngredients.length;
    setState(() {
      _isSearching = true;
      _totalRequested = requested;
    });

    try {
      final results =
          await FirebaseService().searchByIngredients(_detectedIngredients);
      if (!mounted) return;
      setState(() {
        _scanRecipes = results;
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not find matching recipes. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  String _buildResultsHeader() {
    final exactCount =
        _scanRecipes.where((m) => m.matchCount == _totalRequested).length;
    final partialCount = _scanRecipes.length - exactCount;

    if (exactCount > 0 && partialCount > 0) {
      return '$exactCount exact · $partialCount partial';
    } else if (exactCount > 0) {
      return '$exactCount recipe${exactCount == 1 ? '' : 's'} found';
    } else {
      return '$partialCount partial match${partialCount == 1 ? '' : 'es'}';
    }
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
            Icon(Icons.auto_awesome, color: colorScheme.primary),
            const HGap.sm(),
            const Text('Find by Ingredients'),
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
                      'Scan a photo, choose from gallery, or speak your ingredients. We\'ll find matching recipes!',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

            const Gap.xl(),

            // Image Preview / Camera Options
            if (_selectedImage == null && _detectedIngredients.isEmpty) ...[
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

              const Gap.md(),

              // Voice Input Option
              _ScanOption(
                icon: Icons.mic,
                title: 'Voice Input',
                subtitle: 'Say your ingredients aloud',
                gradient: LinearGradient(
                  colors: [
                    AppColors.info,
                    AppColors.info.withValues(alpha: 0.7),
                  ],
                ),
                onTap: _onVoiceInput,
              ),
            ] else if (_selectedImage != null) ...[
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
                            _hasSearched = false;
                            _totalRequested = 0;
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
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _detectedIngredients = [];
                    _scanRecipes = [];
                    _inputSource = '';
                    _hasSearched = false;
                    _totalRequested = 0;
                  });
                },
                icon: Icon(_inputSource == 'voice' ? Icons.mic : Icons.refresh),
                label: Text(_inputSource == 'voice' ? 'Try Again' : 'Scan Again'),
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

            // Empty state — only shown after a completed search with zero results
            if (_hasSearched && _scanRecipes.isEmpty && !_isSearching) ...[
              const Gap.xl(),
              EmptyState(
                icon: Icons.search_off,
                title: 'No recipes found',
                subtitle: 'Try removing an ingredient or scanning again.',
              ),
            ],

            // Recipe results — vertical list with match badges
            if (_scanRecipes.isNotEmpty) ...[
              const Gap.xl(),
              Row(
                children: [
                  Icon(Icons.restaurant_menu, color: colorScheme.primary),
                  const HGap.sm(),
                  Text(
                    _buildResultsHeader(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Gap.md(),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _scanRecipes.length,
                separatorBuilder: (_, __) => const Gap.md(),
                itemBuilder: (context, index) {
                  final match = _scanRecipes[index];
                  return SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        RecipeCard(
                          id: match.recipe.id,
                          title: match.recipe.name,
                          imageUrl: match.recipe.imageUrl,
                          cookTime:
                              '${match.recipe.prepTime + match.recipe.cookTime} min',
                          difficulty: match.recipe.difficulty,
                          rating: match.recipe.rating,
                          isFavorite: context
                              .watch<RecipeProvider>()
                              .isFavorite(match.recipe.id),
                          onTap: () => context.push(
                            '/recipe/${match.recipe.id}',
                            extra: match.recipe,
                          ),
                          onFavoriteTap: () => context
                              .read<RecipeProvider>()
                              .toggleFavorite(match.recipe.id),
                        ),
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: _MatchBadge(
                            matchCount: match.matchCount,
                            totalRequested: _totalRequested,
                          ),
                        ),
                      ],
                    ),
                  );
                },
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

class _MatchBadge extends StatelessWidget {
  final int matchCount;
  final int totalRequested;

  const _MatchBadge({
    required this.matchCount,
    required this.totalRequested,
  });

  @override
  Widget build(BuildContext context) {
    final isExact = matchCount == totalRequested;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isExact
            ? AppColors.primaryOrange
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isExact ? 'All $matchCount matched' : '$matchCount of $totalRequested',
        style: TextStyle(
          color: isExact ? Colors.white : colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
