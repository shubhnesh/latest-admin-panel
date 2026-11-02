import 'package:cloud_firestore/cloud_firestore.dart';

/// A user-created tag (in addition to the fixed built-in tags — Featured,
/// Bestseller, New, Popular — which are not stored here and can't be
/// edited/deleted). Up to 4 custom tags are allowed; see [TagService].
class TagModel {
  final String id;
  final String name;

  const TagModel({
    required this.id,
    required this.name,
  });

  factory TagModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return TagModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {'name': name};

  @override
  bool operator ==(Object other) => other is TagModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
