import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inventory_category_model.dart';

class InventoryCategoryService {
  InventoryCategoryService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('inventory_categories');

  Future<List<InventoryCategoryModel>> fetchCategories() async {
    final snapshot = await _col.get();
    final categories = snapshot.docs
        .map(InventoryCategoryModel.fromFirestore)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return categories;
  }

  Stream<List<InventoryCategoryModel>> streamCategories() {
    return _col.snapshots().map((snapshot) {
      final categories = snapshot.docs
          .map(InventoryCategoryModel.fromFirestore)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return categories;
    });
  }

  Future<InventoryCategoryModel> createCategory({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    final slug = await _uniqueSlug(_slugify(trimmed));
    await _col.doc(slug).set({
      'name': trimmed,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return InventoryCategoryModel(id: slug, name: trimmed);
  }

  Future<void> updateCategory(InventoryCategoryModel category) async {
    if (category.id.trim().isEmpty) {
      throw ArgumentError('Cannot update a category without an ID.');
    }
    await _col.doc(category.id).update({
      'name': category.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Cannot delete a category without an ID.');
    }
    await _col.doc(id).delete();
  }

  String _slugify(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s-]"), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty ? 'category' : slug;
  }

  Future<String> _uniqueSlug(String baseSlug) async {
    var slug = baseSlug;
    var suffix = 2;
    while ((await _col.doc(slug).get()).exists) {
      slug = '$baseSlug-$suffix';
      suffix++;
    }
    return slug;
  }
}
