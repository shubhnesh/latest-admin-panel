import 'menu_item_model.dart';

/// A single add-on selected for a cart line (name + optional price).
class CartAddOn {
  final String name;
  final double price;

  const CartAddOn({
    required this.name,
    this.price = 0,
  });

  String get displayLabel =>
      price > 0 ? '$name (+₹${price.toStringAsFixed(0)})' : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartAddOn && name == other.name && price == other.price;

  @override
  int get hashCode => Object.hash(name, price);
}

/// One line in the active order cart.
class CartLineItem {
  final String id;
  final MenuItemModel menuItem;
  final int quantity;
  final String? spiceLevel;
  final List<CartAddOn> addOns;
  final String? notes;

  const CartLineItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    this.spiceLevel,
    this.addOns = const [],
    this.notes,
  });

  double get unitPrice =>
      menuItem.price + addOns.fold<double>(0, (sum, a) => sum + a.price);

  double get subtotal => unitPrice * quantity;

  CartLineItem copyWith({
    String? id,
    MenuItemModel? menuItem,
    int? quantity,
    String? spiceLevel,
    List<CartAddOn>? addOns,
    String? notes,
  }) {
    return CartLineItem(
      id: id ?? this.id,
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      addOns: addOns ?? this.addOns,
      notes: notes ?? this.notes,
    );
  }
}

/// Predefined spice levels shown in the customize sheet.
const List<String> kSpiceLevels = [
  'Mild',
  'Medium',
  'Hot',
  'Extra Hot',
];

/// Quick add-ons offered in the customize sheet.
const List<CartAddOn> kQuickAddOns = [
  CartAddOn(name: 'Extra Cheese', price: 30),
  CartAddOn(name: 'Extra Sauce', price: 20),
  CartAddOn(name: 'No Onion', price: 0),
  CartAddOn(name: 'Extra Spicy', price: 0),
];
