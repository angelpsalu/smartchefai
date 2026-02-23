import 'package:flutter_test/flutter_test.dart';
import 'package:smartchefai/models/models.dart';
import '../helpers/test_data.dart';

void main() {
  group('GroceryItem', () {
    test('fromJson parses all fields', () {
      final item = GroceryItem.fromJson({
        'name': 'Tomato',
        'quantity': 2.0,
        'unit': 'pcs',
        'category': 'vegetables',
        'checked': false,
        'recipes': ['r1'],
      });
      expect(item.name, 'Tomato');
      expect(item.quantity, 2.0);
      expect(item.unit, 'pcs');
      expect(item.category, 'vegetables');
      expect(item.checked, false);
      expect(item.recipes, ['r1']);
    });

    test('fromJson uses defaults for missing fields', () {
      final item = GroceryItem.fromJson({'name': 'Sugar'});
      expect(item.quantity, 1.0);
      expect(item.unit, '');
      expect(item.category, 'other');
      expect(item.checked, false);
    });

    test('copyWith toggles checked', () {
      final item = TestData.groceryItem;
      final toggled = item.copyWith(checked: true);
      expect(toggled.checked, true);
      expect(toggled.name, item.name);
    });

    test('toJson round-trips', () {
      final item = TestData.groceryItem;
      final json = item.toJson();
      final restored = GroceryItem.fromJson(json);
      expect(restored.name, item.name);
      expect(restored.quantity, item.quantity);
      expect(restored.checked, item.checked);
    });
  });

  group('GroceryList', () {
    test('fromJson groups items by category', () {
      final list = GroceryList.fromJson({
        'id': 'gl1',
        'user_id': 'uid-1',
        'items': [
          {'name': 'Tomato', 'quantity': 1.0, 'unit': '', 'category': 'vegetables', 'checked': false, 'recipes': []},
          {'name': 'Apple',  'quantity': 2.0, 'unit': '', 'category': 'fruits',     'checked': false, 'recipes': []},
          {'name': 'Carrot', 'quantity': 1.0, 'unit': '', 'category': 'vegetables', 'checked': true,  'recipes': []},
        ],
        'recipes': [],
        'status': 'active',
        'created_at': '2024-01-01T00:00:00.000',
      });
      expect(list.byCategory['vegetables']!.length, 2);
      expect(list.byCategory['fruits']!.length, 1);
      expect(list.items.length, 3);
    });

    test('fromJson uses empty list for missing items', () {
      final list = GroceryList.fromJson({
        'id': 'gl2',
        'user_id': 'uid-1',
        'recipes': [],
        'created_at': '2024-01-01T00:00:00.000',
        'status': 'active',
      });
      expect(list.items, isEmpty);
    });
  });
}
