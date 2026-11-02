import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/preparation_model.dart';

/// Handles reading and writing preparation styles to Firestore.
///
/// Like [RegionalityService], creating a preparation from the menu item
/// form is deferred — the "+ Add preparation" dialog on the form does NOT
/// call [createPreparation] itself. A newly typed preparation is only
/// persisted once the surrounding menu item form is actually submitted.
/// [updatePreparation]/[deletePreparation] are used by the manage-category
/// screen, where edits/deletes are immediate.
class PreparationService {
  PreparationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('menu_preparations');

  Future<List<PreparationModel>> fetchPreparations() async {
    final snapshot = await _col.get();
    final preparations = snapshot.docs
        .map(PreparationModel.fromFirestore)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return preparations;
  }

  Stream<List<PreparationModel>> streamPreparations() {
    return _col.snapshots().map((snapshot) {
      final preparations = snapshot.docs
          .map(PreparationModel.fromFirestore)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return preparations;
    });
  }

  Future<PreparationModel> createPreparation({required String name}) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Preparation name cannot be empty.');
    }

    final slug = await _uniqueSlug(_slugify(trimmedName));

    await _col.doc(slug).set({
      'name': trimmedName,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return PreparationModel(id: slug, name: trimmedName);
  }

  Future<void> updatePreparation(PreparationModel preparation) async {
    if (preparation.id.trim().isEmpty) {
      throw ArgumentError('Cannot update a preparation without an ID.');
    }

    await _col.doc(preparation.id).update({
      'name': preparation.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePreparation(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Cannot delete a preparation without an ID.');
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

    return slug.isEmpty ? 'preparation' : slug;
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
