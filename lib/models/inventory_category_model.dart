import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryCategoryModel {
  final String id;
  final String name;

  const InventoryCategoryModel({
    required this.id,
    required this.name,
  });

  factory InventoryCategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return InventoryCategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
      };

  @override
  bool operator ==(Object other) =>
      other is InventoryCategoryModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
