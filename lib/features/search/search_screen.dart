import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../app/theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/app_providers.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String? _selectedCategory;
  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  Timer? _debounceTimer;

  final List<String> _categories = [
    'Beef',
    'Chicken',
    'Seafood',
    'Vegetarian',
    'Pasta',
    'Dessert',
    'Breakfast',
    'Side',
  ];

  final List<String> _recentSearches = [
    'Chicken curry',
    'Pasta carbonara',
    'Vegetable stir fry',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  void _startListening() async {
    if (!_speech.isAvailable) return;

    setState(() => _isListening = true);
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            _searchController.text = result.recognizedWords;
            _isListening = false;
          });
          _performSearch(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer for debouncing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<RecipeProvider>().searchRecipes(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _speech.stop();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const SmartChefAppBar(
        showBackButton: true,
        title: 'Search Recipes',
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: AppSpacing.paddingMd,
            child: SmartSearchBar(
              controller: _searchController,
              autofocus: true,
              hintText: 'Search by name, ingredient, or cuisine...',
              onSubmitted: _performSearch,
              onChanged: (value) {
                if (value.length > 2) {
                  _performSearch(value);
                }
              },
              onVoiceTap: _isListening ? _stopListening : _startListening,
              onCameraTap: () => Navigator.pushNamed(context, '/scan'),
            ),
          ),

          // Voice Listening Indicator
          if (_isListening)
            Container(
              padding: AppSpacing.paddingSm,
              margin: AppSpacing.paddingHorizontalMd,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: colorScheme.primary,
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
                  const HGap.sm(),
                  Text(
                    'Listening... Say ingredient or recipe name',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

          // Category Chips
          const Gap.md(),
          CategoryChips(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onSelected: (category) {
              setState(() => _selectedCategory = category);
              if (category != null) {
                _performSearch(category);
              } else {
                context.read<RecipeProvider>().loadRecipes();
              }
            },
          ),

          const Gap.md(),

          // Results
          Expanded(
            child: _buildSearchResults(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final recipes = provider.recipes;
    final isLoading = provider.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Show recent searches if no search query
    if (_searchController.text.isEmpty && _selectedCategory == null) {
      return ListView(
        padding: AppSpacing.paddingMd,
        children: [
          Text(
            'Recent Searches',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap.md(),
          ..._recentSearches.map((search) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(search),
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.north_west),
                  onPressed: () {
                    _searchController.text = search;
                  },
                ),
              )),
          const Gap.xl(),
          Text(
            'Popular Categories',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap.md(),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _categories
                .map((cat) => ActionChip(
                      label: Text(cat),
                      onPressed: () {
                        setState(() => _selectedCategory = cat);
                        _performSearch(cat);
                      },
                    ))
                .toList(),
          ),
        ],
      );
    }

    if (isLoading) {
      return GridView.builder(
        padding: AppSpacing.paddingMd,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => ShimmerPlaceholder(
          height: 200,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
      );
    }

    if (recipes.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No recipes found',
        subtitle: 'Try a different search term or category',
        actionText: 'Clear Search',
        onAction: () {
          _searchController.clear();
          setState(() => _selectedCategory = null);
          context.read<RecipeProvider>().loadRecipes();
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: AppSpacing.paddingHorizontalMd,
          child: Row(
            children: [
              Text(
                '${recipes.length} recipes found',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Gap.sm(),
        Expanded(
          child: GridView.builder(
            padding: AppSpacing.paddingMd,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(
                id: recipe.id,
                title: recipe.name,
                imageUrl: recipe.imageUrl,
                cookTime: '${recipe.prepTime + recipe.cookTime} min',
                difficulty: recipe.difficulty,
                rating: recipe.rating,
                isFavorite: context.watch<RecipeProvider>().isFavorite(recipe.id),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/recipe/${recipe.id}',
                  arguments: recipe,
                ),
                onFavoriteTap: () {
                  context.read<RecipeProvider>().toggleFavorite(recipe.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
