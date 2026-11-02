import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/regionality_model.dart';

/// Handles reading and writing regionalities to Firestore.
///
/// Unlike [CategoryService], creating a regionality here is a deliberate,
/// explicit call — the "+ Add regionality" dialog on the menu item form
/// does NOT call [createRegionality] itself. A newly typed regionality is
/// only persisted (via this service) once the surrounding menu item form
/// is actually submitted, since a regionality only has meaning attached
/// to a dish.
///
/// [updateRegionality]/[deleteRegionality] are used by the manage-category
/// screen, where edits/deletes are immediate — same contract as
/// [PreparationService].
class RegionalityService {
  RegionalityService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('menu_regionalities');

  Future<List<RegionalityModel>> fetchRegionalities() async {
    final snapshot = await _col.get();
    final regionalities = snapshot.docs
        .map(RegionalityModel.fromFirestore)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return regionalities;
  }

  Stream<List<RegionalityModel>> streamRegionalities() {
    return _col.snapshots().map((snapshot) {
      final regionalities = snapshot.docs
          .map(RegionalityModel.fromFirestore)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return regionalities;
    });
  }

  /// Creates a regionality with a readable slug ID derived from the name
  /// (e.g. "Punjabi" -> "punjabi"), with a numeric suffix appended on
  /// collision — matching [CategoryService]'s ID scheme.
  Future<RegionalityModel> createRegionality({required String name}) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Regionality name cannot be empty.');
    }

    final slug = await _uniqueSlug(_slugify(trimmedName));

    await _col.doc(slug).set({
      'name': trimmedName,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return RegionalityModel(id: slug, name: trimmedName);
  }

  /// Renames an existing regionality in place (keeps the same doc/slug
  /// ID). Used by the manage-category screen's immediate-edit flow.
  Future<void> updateRegionality(RegionalityModel regionality) async {
    if (regionality.id.trim().isEmpty) {
      throw ArgumentError('Cannot update a regionality without an ID.');
    }

    await _col.doc(regionality.id).update({
      'name': regionality.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRegionality(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Cannot delete a regionality without an ID.');
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

    return slug.isEmpty ? 'regionality' : slug;
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
