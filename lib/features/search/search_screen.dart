import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/theme.dart';
import '../../constants/firestore_constants.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/app_providers.dart';
import '../../services/voice_search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  /// Whether the voice overlay is currently open (drives mic button state).
  bool _isListening = false;

  /// Centralized voice service — shared between this screen and the overlay.
  final VoiceSearchService _voiceService = VoiceSearchService();

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

  @override
  void initState() {
    super.initState();
    // Pre-warm the speech engine so the first tap is instant.
    _voiceService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadRecentSearches();
    });
  }

  // ─── Voice ──────────────────────────────────────────────────────────────────

  Future<void> _onVoiceTap() async {
    if (_isListening) {
      // User tapped mic while overlay is open — cancel.
      await _voiceService.cancel();
      return;
    }

    setState(() => _isListening = true);

    final result = await showVoiceSearchOverlay(
      context: context,
      service: _voiceService,
    );

    if (!mounted) return;
    setState(() => _isListening = false);

    if (result != null && result.isNotEmpty) {
      _searchController.text = result;
      _performSearch(result);
    }
  }

  // ─── Search ─────────────────────────────────────────────────────────────────

  void _performSearch(String query) {
    if (query.isEmpty) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<RecipeProvider>().searchRecipes(query);
      context.read<UserProvider>().addRecentSearch(query);
    });
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _searchController.dispose();
    _voiceService.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartChefAppBar(title: 'Search'),
      body: Column(
        children: [
          // Search Bar — mic button reflects listening state
          Padding(
            padding: AppSpacing.paddingMd,
            child: SmartSearchBar(
              controller: _searchController,
              autofocus: false,
              hintText: 'Search by name, ingredient, or cuisine...',
              onSubmitted: _performSearch,
              onChanged: (value) {
                if (value.length > 2) _performSearch(value);
              },
              onVoiceTap: _onVoiceTap,
              onCameraTap: () => context.push('/scan'),
              isListening: _isListening,
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
          Expanded(child: _buildSearchResults(context)),
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

    // Show recent searches if no query
    if (_searchController.text.isEmpty && _selectedCategory == null) {
      final recentSearches = context.watch<UserProvider>().recentSearches;
      return ListView(
        padding: AppSpacing.paddingMd,
        children: [
          Text(
            'Recent Searches',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Gap.md(),
          ...recentSearches.map((search) => ListTile(
                leading: Icon(Icons.history, color: colorScheme.onSurfaceVariant),
                title: Text(
                  search,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                ),
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
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
          childAspectRatio: AppLayout.recipeCardAspectRatio,
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
              childAspectRatio: AppLayout.recipeCardAspectRatio,
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
                onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
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
