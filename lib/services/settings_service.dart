import 'package:cloud_firestore/cloud_firestore.dart';

/// Pure data-access layer for restaurant settings.
/// No UI or Riverpod dependencies — safe to unit-test in isolation.
class SettingsService {
  SettingsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _collection = 'settings';
  static const _docId = 'restaurant';

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection(_collection).doc(_docId);

  /// Loads the restaurant settings document. Returns null if it does not exist.
  Future<Map<String, dynamic>?> load() async {
    final snapshot = await _doc.get();
    if (!snapshot.exists) return null;
    return snapshot.data();
  }

  /// Merges [data] into the restaurant settings document.
  Future<void> save(Map<String, dynamic> data) async {
    await _doc.set(
      {
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Convenience: update a single boolean toggle field.
  Future<void> updateToggle(String field, bool value) async {
    await save({field: value});
  }
}
