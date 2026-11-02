import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tag_model.dart';

/// Handles reading and writing custom tags to Firestore.
///
/// Unlike [PreparationService]/[RegionalityService], a custom tag is
/// persisted immediately when created — tags are managed as their own
/// pool (editable/deletable from the manage-category screen) independent
/// of any single menu item, the same way categories are.
class TagService {
  TagService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Only 4 custom tags are allowed, on top of the 4 fixed built-in tags
  /// (Featured, Bestseller, New, Popular) that live in the UI only.
  static const maxCustomTags = 4;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('menu_tags');

  Future<List<TagModel>> fetchTags() async {
    final snapshot = await _col.get();
    final tags = snapshot.docs.map(TagModel.fromFirestore).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return tags;
  }

  Stream<List<TagModel>> streamTags() {
    return _col.snapshots().map((snapshot) {
      final tags = snapshot.docs.map(TagModel.fromFirestore).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return tags;
    });
  }

  Future<TagModel> createTag({required String name}) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Tag name cannot be empty.');
    }

    final existing = await fetchTags();
    if (existing.length >= maxCustomTags) {
      throw StateError(
        'You can only create up to $maxCustomTags custom tags.',
      );
    }

    final slug = await _uniqueSlug(_slugify(trimmedName));

    await _col.doc(slug).set({
      'name': trimmedName,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return TagModel(id: slug, name: trimmedName);
  }

  Future<void> updateTag(TagModel tag) async {
    if (tag.id.trim().isEmpty) {
      throw ArgumentError('Cannot update a tag without an ID.');
    }

    await _col.doc(tag.id).update({
      'name': tag.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTag(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Cannot delete a tag without an ID.');
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

    return slug.isEmpty ? 'tag' : slug;
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
