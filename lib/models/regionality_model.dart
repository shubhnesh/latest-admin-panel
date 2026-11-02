import 'package:cloud_firestore/cloud_firestore.dart';

/// A regionality (e.g. "Punjabi", "Indo-Chinese") that a menu item can be
/// tagged with, so items can be searched/filtered by region of origin.
///
/// Unlike [CategoryModel], a regionality has no subcategories — it's a
/// single name.
class RegionalityModel {
  final String id;
  final String name;

  const RegionalityModel({
    required this.id,
    required this.name,
  });

  factory RegionalityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return RegionalityModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {'name': name};

  @override
  bool operator ==(Object other) =>
      other is RegionalityModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
