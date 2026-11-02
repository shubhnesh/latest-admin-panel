import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('inventory');

  Future<List<InventoryItemModel>> fetchInventory() async {
    final snap = await _col.get();
    final items = snap.docs.map(InventoryItemModel.fromFirestore).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Future<InventoryItemModel?> getItem(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return InventoryItemModel.fromFirestore(doc);
  }

  /// Blunt quantity overwrite (kept for backward compatibility with any
  /// existing call-sites). Prefer [addStock] / [useStock] for restocking
  /// and consumption — this method recomputes total_cost from scratch
  /// using the *current* unit cost, which is only correct if you truly
  /// mean "this is the new total quantity, re-priced at today's rate".
  Future<void> updateQuantity(
    String id,
    double quantity, {
    DateTime? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now();
    final doc = await _col.doc(id).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final unitCost = (data['unit_cost'] as num?)?.toDouble() ?? 0;

    await _col.doc(id).update({
      'quantity': quantity,
      'unit_cost': unitCost,
      'total_cost': quantity * unitCost,
      'updated_at': Timestamp.fromDate(ts),
    });
  }

  /// Restocking. Adds [addedQuantity] to the current quantity, and adds
  /// (addedQuantity * current unit cost) to the *existing* total_cost —
  /// it never recomputes the whole stock at the new/current unit price.
  /// This is what keeps older stock's cost basis intact when the market
  /// price moves.
  ///
  /// [timestamp] is sent explicitly (rather than relying on
  /// FieldValue.serverTimestamp()) so the same date/time value is used for
  /// both `updated_at` and `last_added_at` — the caller decides the moment
  /// this restock happened, and both fields agree on it.
  Future<void> addStock(
    String id,
    double addedQuantity, {
    DateTime? timestamp,
  }) async {
    if (addedQuantity <= 0) return;
    if (addedQuantity > 999) {
      throw ArgumentError('Cannot add more than 999 units at once');
    }
    final ts = timestamp ?? DateTime.now();
    final doc = await _col.doc(id).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final currentQty = (data['quantity'] as num?)?.toDouble() ?? 0;
    final unitCost = (data['unit_cost'] as num?)?.toDouble() ?? 0;
    final currentTotalCost =
        (data['total_cost'] as num?)?.toDouble() ?? (currentQty * unitCost);
    final currentTotalAdded =
        (data['total_added'] as num?)?.toDouble() ?? 0;

    final addedCost = addedQuantity * unitCost;
    final firestoreTs = Timestamp.fromDate(ts);

    await _col.doc(id).update({
      'quantity': currentQty + addedQuantity,
      'total_cost': currentTotalCost + addedCost,
      'updated_at': firestoreTs,
      'last_added_at': firestoreTs,
      'last_added_qty': addedQuantity,
      'total_added': currentTotalAdded + addedQuantity,
    });
  }

  /// Consumption. Subtracts [usedQuantity] from the current quantity.
  /// total_cost is left untouched on purpose — using material that was
  /// already bought and paid for isn't a new financial transaction, so
  /// it must not reduce the recorded cost of the (remaining) stock.
  ///
  /// [timestamp] is sent explicitly so `updated_at` and `last_used_at`
  /// share the exact same date/time value for this transaction.
  Future<void> useStock(
    String id,
    double usedQuantity, {
    DateTime? timestamp,
  }) async {
    if (usedQuantity <= 0) return;
    final ts = timestamp ?? DateTime.now();
    final doc = await _col.doc(id).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final currentQty = (data['quantity'] as num?)?.toDouble() ?? 0;
    if (usedQuantity > currentQty) {
      throw ArgumentError('Cannot use more than current stock');
    }
    final newQty = currentQty - usedQuantity;
    final currentTotalUsed =
        (data['total_used'] as num?)?.toDouble() ?? 0;
    final firestoreTs = Timestamp.fromDate(ts);

    await _col.doc(id).update({
      'quantity': newQty < 0 ? 0 : newQty,
      // total_cost intentionally omitted from this update.
      'updated_at': firestoreTs,
      'last_used_at': firestoreTs,
      'last_used_qty': usedQuantity,
      'total_used': currentTotalUsed + usedQuantity,
    });
  }

  /// Creating vs editing behave differently on purpose:
  /// - New item (empty id): total_cost is computed fresh as
  ///   quantity * unitCost — this is the material's initial cost basis.
  ///   created_at and updated_at are both set to [timestamp] (or now),
  ///   so the record's creation moment and its first "updated" moment
  ///   match exactly.
  /// - Existing item (edit): total_cost is taken as-is from [item]
  ///   (the caller is expected to pass along the existing total_cost
  ///   unchanged), so editing name/category/unit cost/min/max through
  ///   the form never silently re-prices stock that was already bought.
  ///   Only updated_at advances to [timestamp]; created_at is preserved
  ///   from the original document.
  ///   Stock quantity changes belong to [addStock] / [useStock], not to
  ///   this general-purpose save.
  Future<String> saveItem(
    InventoryItemModel item, {
    DateTime? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now();
    final isNew = item.id.isEmpty;
    final itemToSave = isNew
        ? item.copyWith(
            totalCost: item.computedTotalCost,
            totalAdded: item.quantity,
            totalUsed: 0,
            lastAddedAt: item.quantity > 0 ? ts : null,
            lastAddedQty: item.quantity > 0 ? item.quantity : null,
            createdAt: ts,
            updatedAt: ts,
          )
        : item.copyWith(updatedAt: ts);
    final data = itemToSave.toJson();
    if (isNew) {
      // Use the material name as the document ID so the collection
      // shows readable names instead of random auto-generated IDs.
      final docId = item.name.trim();
      await _col.doc(docId).set(data);
      return docId;
    } else {
      await _col.doc(item.id).set(data, SetOptions(merge: true));
      return item.id;
    }
  }

  Future<void> deleteItem(String id) async {
    await _col.doc(id).delete();
  }

  /// Returns only items that are below their minimum required level.
  Future<List<InventoryItemModel>> fetchLowStock() async {
    final all = await fetchInventory();
    return all.where((e) => e.needsRestock).toList();
  }
}
