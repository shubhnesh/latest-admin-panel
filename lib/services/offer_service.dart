import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/offer_model.dart';

class OfferService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('offers');

  Future<List<OfferModel>> fetchOffers() async {
    final snap = await _col.get();
    final offers = snap.docs.map(OfferModel.fromFirestore).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return offers;
  }

  Future<void> createOffer(OfferModel offer) async {
    final docId = offer.id.isEmpty ? _col.doc().id : offer.id;
    final data = offer.toJson();
    data['created_at'] = FieldValue.serverTimestamp();
    await _col.doc(docId).set(data);
  }

  Future<void> updateOffer(OfferModel offer) async {
    final docId = offer.id.isEmpty ? _col.doc().id : offer.id;
    final data = offer.toJson();
    data['created_at'] = FieldValue.serverTimestamp();
    await _col.doc(docId).set(data, SetOptions(merge: true));
  }

  Future<void> deleteOffer(String id) async {
    if (id.trim().isEmpty) return;
    await _col.doc(id).delete();
  }
}
