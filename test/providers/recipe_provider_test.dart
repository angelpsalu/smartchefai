import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/providers/firebase_providers.dart';
import '../helpers/mock_firebase_service.mocks.dart';
import '../helpers/test_data.dart';

void main() {
  late MockFirebaseService mockService;
  late RecipeProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    when(mockService.getFavoriteIds()).thenAnswer((_) async => []);
    provider = RecipeProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('RecipeProvider', () {
    test('initial state: empty, not loading', () {
      expect(provider.recipes, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('loadRecipes() populates recipes list', () async {
      when(mockService.getAllRecipes()).thenAnswer(
        (_) async => [TestData.recipe, TestData.recipe2],
      );

      await provider.loadRecipes();

      expect(provider.recipes.length, 2);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('loadRecipes() sets error on exception', () async {
      when(mockService.getAllRecipes()).thenThrow(Exception('Network error'));

      await provider.loadRecipes();

      expect(provider.error, isNotNull);
      expect(provider.isLoading, false);
    });

    test('isFavorite() returns false for unknown id', () {
      expect(provider.isFavorite('unknown'), false);
    });

    test('toggleFavorite() adds recipe to favorites', () async {
      when(mockService.addFavorite(any)).thenAnswer((_) async {});
      when(mockService.removeFavorite(any)).thenAnswer((_) async {});

      when(mockService.getAllRecipes()).thenAnswer((_) async => [TestData.recipe]);
      await provider.loadRecipes();

      provider.toggleFavorite('r1');

      expect(provider.isFavorite('r1'), true);
      expect(provider.favorites.any((r) => r.id == 'r1'), true);
    });

    test('toggleFavorite() removes recipe already in favorites', () async {
      when(mockService.addFavorite(any)).thenAnswer((_) async {});
      when(mockService.removeFavorite(any)).thenAnswer((_) async {});

      when(mockService.getAllRecipes()).thenAnswer((_) async => [TestData.recipe]);
      await provider.loadRecipes();

      provider.toggleFavorite('r1'); // add
      provider.toggleFavorite('r1'); // remove

      expect(provider.isFavorite('r1'), false);
    });

    test('searchRecipes() returns matched recipes', () async {
      when(mockService.searchRecipes(any)).thenAnswer(
        (_) async => [TestData.recipe],
      );

      final results = await provider.searchRecipes('pasta');

      expect(results.length, 1);
      expect(results.first.name, 'Test Pasta');
    });
  });
}
