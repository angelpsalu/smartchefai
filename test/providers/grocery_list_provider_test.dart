import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/providers/firebase_providers.dart';
import '../helpers/mock_firebase_service.mocks.dart';
import '../helpers/test_data.dart';

void main() {
  late MockFirebaseService mockService;
  late GroceryListProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    // currentUser = null → _syncFromCloud() and _pushToCloud() return immediately
    when(mockService.currentUser).thenReturn(null);
    provider = GroceryListProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('GroceryListProvider', () {
    test('items is empty initially', () {
      expect(provider.items, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('addItem() adds a GroceryItem to the list', () {
      provider.addItem(TestData.groceryItem);

      expect(provider.items.length, 1);
      expect(provider.items.first.name, TestData.groceryItem.name);
      expect(provider.items.first.checked, false);
    });

    test('addItem() ignores duplicate item names (case-insensitive)', () {
      provider.addItem(TestData.groceryItem);
      provider.addItem(TestData.groceryItem); // exact duplicate

      expect(provider.items.length, 1);
    });

    test('toggleItem() flips the checked state of an item', () {
      provider.addItem(TestData.groceryItem);
      expect(provider.items.first.checked, false);

      provider.toggleItem(TestData.groceryItem.name);
      expect(provider.items.first.checked, true);

      provider.toggleItem(TestData.groceryItem.name);
      expect(provider.items.first.checked, false);
    });

    test('removeItem() removes item by name', () {
      provider.addItem(TestData.groceryItem);
      provider.removeItem(TestData.groceryItem.name);

      expect(provider.items, isEmpty);
    });

    test('clearCheckedItems() removes only checked items', () {
      const anotherItem = GroceryItem(
        name: 'Onion',
        quantity: 1.0,
        unit: 'pcs',
        category: 'vegetables',
        recipes: [],
      );
      provider.addItem(TestData.groceryItem);
      provider.addItem(anotherItem);
      provider.toggleItem(TestData.groceryItem.name);

      provider.clearCheckedItems();

      expect(provider.items.length, 1);
      expect(provider.items.first.name, anotherItem.name);
    });

    test('isLoading is false after getUserGroceryLists completes', () async {
      when(mockService.getGroceryLists()).thenAnswer((_) async => []);

      await provider.getUserGroceryLists('uid-1');

      expect(provider.isLoading, false);
      expect(provider.lists, isEmpty);
    });

    test('getUserGroceryLists() populates lists', () async {
      when(mockService.getGroceryLists()).thenAnswer((_) async => [
            GroceryList(
              id: 'gl1',
              userId: 'uid-1',
              items: const [],
              byCategory: const {},
              totalItems: 0,
              recipes: const [],
              createdAt: DateTime(2024),
              status: 'active',
            ),
          ]);

      await provider.getUserGroceryLists('uid-1');

      expect(provider.lists.length, 1);
    });
  });
}
