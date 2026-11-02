import 'package:cloud_firestore/cloud_firestore.dart';

/// Persists the restaurant's total table count independently of any
/// order / checkout form submission.
///
/// Stored at: `restaurant_settings/tables`
class TableConfigService {
  TableConfigService({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const int maxTables = 50;
  static const int minTables = 1;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('table').doc('tables');

  /// Returns the saved total table count, or `null` if never set.
  Future<int?> fetchTableCount() async {
    final snap = await _doc.get();
    if (!snap.exists) return null;

    final raw = snap.data()?['total_tables'];
    if (raw is int) return raw.clamp(minTables, maxTables);
    if (raw is num) return raw.toInt().clamp(minTables, maxTables);
    return null;
  }

  /// Persists the total table count (clamped to 1–50).
  ///
  /// This runs on its own — it does **not** depend on placing an order.
  Future<void> saveTableCount(int count) async {
    final clamped = count.clamp(minTables, maxTables);
    await _doc.set(
      {
        'total_tables': clamped,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
