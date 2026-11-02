import 'package:cloud_firestore/cloud_firestore.dart';

/// A preparation style (e.g. "Tandoori", "Gravy") a menu item can be
/// tagged with. Replaces the old hardcoded `PreparationStyle` enum —
/// preparations are now user-created and stored in Firestore.
class PreparationModel {
  final String id;
  final String name;

  const PreparationModel({
    required this.id,
    required this.name,
  });

  factory PreparationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PreparationModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {'name': name};

  @override
  bool operator ==(Object other) =>
      other is PreparationModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
