import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/unit_model.dart';

class UnitService {
  UnitService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('inventory_units');

  Future<List<UnitModel>> fetchUnits() async {
    final snapshot = await _col.get();
    final units = snapshot.docs.map(UnitModel.fromFirestore).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return units;
  }

  Stream<List<UnitModel>> streamUnits() {
    return _col.snapshots().map((snapshot) {
      final units = snapshot.docs.map(UnitModel.fromFirestore).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return units;
    });
  }

  Future<UnitModel> createUnit({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Unit name cannot be empty.');
    }

    final slug = await _uniqueSlug(_slugify(trimmed));
    await _col.doc(slug).set({
      'name': trimmed,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return UnitModel(id: slug, name: trimmed);
  }

  Future<void> updateUnit(UnitModel unit) async {
    if (unit.id.trim().isEmpty) {
      throw ArgumentError('Cannot update a unit without an ID.');
    }
    await _col.doc(unit.id).update({
      'name': unit.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUnit(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Cannot delete a unit without an ID.');
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
    return slug.isEmpty ? 'unit' : slug;
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
