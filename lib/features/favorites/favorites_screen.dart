import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/theme.dart';
import '../../constants/firestore_constants.dart';
import '../../shared/widgets/widgets.dart';
import '../../providers/app_providers.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: SmartChefAppBar(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              color: AppColors.primaryOrange,
            ),
            const HGap.sm(),
            Text(
              'My Favorites',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Sort options
            },
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, child) {
          final favorites = provider.favoriteRecipes;

          if (favorites.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_outline,
              title: 'No favorites yet',
              subtitle: 'Start exploring and save recipes you love!',
              actionText: 'Browse Recipes',
              onAction: () => context.go('/'),
            );
          }

          return GridView.builder(
            padding: AppSpacing.paddingMd,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: AppLayout.recipeCardAspectRatio,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final recipe = favorites[index];
              return RecipeCard(
                id: recipe.id,
                title: recipe.name,
                imageUrl: recipe.imageUrl,
                cookTime: '${recipe.prepTime + recipe.cookTime} min',
                difficulty: recipe.difficulty,
                rating: recipe.rating,
                isFavorite: true,
                onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
                onFavoriteTap: () {
                  provider.toggleFavorite(recipe.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
