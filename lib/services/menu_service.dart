import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item_model.dart';

class MenuService {
  MenuService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('menu_items');

  Future<List<MenuItemModel>> fetchMenuItems() async {
    final snapshot = await _col.get();
    final items = snapshot.docs.map(MenuItemModel.fromFirestore).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Stream<List<MenuItemModel>> streamMenuItems() {
    return _col.snapshots().map((snapshot) {
      final items = snapshot.docs.map(MenuItemModel.fromFirestore).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return items;
    });
  }

  Future<MenuItemModel> fetchItemById(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Menu item ID cannot be empty.');
    }

    final doc = await _col.doc(id).get();

    if (!doc.exists) {
      throw Exception('Menu item not found.');
    }

    return MenuItemModel.fromFirestore(doc);
  }

  /// Creates a new menu item.
  ///
  /// Uses the item name as the document ID so the collection shows
  /// readable names instead of random auto-generated IDs.
  Future<String> createItem(MenuItemModel item) async {
    final docId = item.name.trim();
    final data = item.toFirestore();

    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();

    await _col.doc(docId).set(data);

    return docId;
  }

  /// Updates an existing menu item.
  ///
  /// created_at is intentionally NOT touched.
  Future<void> updateItem(MenuItemModel item) async {
    if (item.id.trim().isEmpty) {
      throw ArgumentError(
        'Cannot update a menu item without an ID.',
      );
    }

    final data = item.toFirestore();

    data['updated_at'] = FieldValue.serverTimestamp();

    await _col.doc(item.id).update(data);
  }

  /// Creates or updates depending on whether the item has an ID.
  Future<String?> saveItem(MenuItemModel item) async {
    if (item.id.trim().isEmpty) {
      return createItem(item);
    }

    await updateItem(item);

    return item.id;
  }

  Future<void> deleteItem(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError(
        'Cannot delete a menu item without an ID.',
      );
    }

    await _col.doc(id).delete();
  }

  Future<void> toggleAvailability(
    String id,
    bool available,
  ) async {
    if (id.trim().isEmpty) {
      throw ArgumentError(
        'Cannot change availability without an ID.',
      );
    }

    await _col.doc(id).update({
      'available': available,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDisplaySettings({
    required String id,
    required bool showOnMobileApp,
    required bool featuredItem,
  }) async {
    if (id.trim().isEmpty) {
      throw ArgumentError(
        'Cannot update display settings without an ID.',
      );
    }

    await _col.doc(id).update({
      'show_on_mobile_app': showOnMobileApp,
      'featured_item': featuredItem,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
