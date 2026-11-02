import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/models/menu_item_model.dart';

void main() {
  group('MenuItemModel size pricing', () {
    test('derives the displayed price from sizes instead of stale item price',
        () {
      final item = MenuItemModel.fromJson({
        'id': 'iced-tea',
        'name': 'Iced Tea',
        'description': '',
        'price': 50,
        'sizes': [
          {'name': 'Small', 'price': 70},
          {'name': 'Large', 'price': 90},
        ],
      });

      expect(item.price, 70);
      expect(item.toFirestore().containsKey('price'), isFalse);
    });

    test('keeps the standalone price for an item without sizes', () {
      final item = MenuItemModel(
        id: '',
        name: 'Coffee',
        description: '',
        price: 45,
      );

      expect(item.toFirestore()['price'], 45);
      expect(item.toFirestore()['sizes'], isEmpty);
    });
  });
}
