import 'package:cloud_firestore/cloud_firestore.dart';

class UnitModel {
  final String id;
  final String name;

  const UnitModel({
    required this.id,
    required this.name,
  });

  factory UnitModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return UnitModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
      };

  @override
  bool operator ==(Object other) => other is UnitModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
