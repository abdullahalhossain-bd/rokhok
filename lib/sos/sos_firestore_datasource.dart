// lib/data/datasources/remote/sos_firestore_datasource.dart
// Raw Firestore operations. No business logic here — just CRUD.
// The repository layer handles error mapping and domain conversion.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'geohash_util.dart';
import 'sos_event_model.dart';
import 'sos_event.dart';

abstract class ISOSFirestoreDatasource {
  Future<SOSEventModel> createSOSEvent(SOSEventModel model);
  Future<void> updateSOSStatus(String eventId, SOSStatus status);
  Future<void> updateVideoUrl(String eventId, String videoUrl);
  Stream<List<SOSEventModel>> watchActiveSOSEvents();
  Stream<SOSEventModel?> watchSOSEvent(String eventId);
  Future<List<SOSEventModel>> queryNearbySOSEvents(String geohash);
}

class SOSFirestoreDatasource implements ISOSFirestoreDatasource {
  final FirebaseFirestore _firestore;
  static const String _collection = 'sos_events';
  final _uuid = const Uuid();

  SOSFirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collection);

  @override
  Future<SOSEventModel> createSOSEvent(SOSEventModel model) async {
    final id = _uuid.v4();
    final geohash = GeohashUtil.encode(model.latitude, model.longitude);

    final modelWithId = SOSEventModel(
      id: id,
      userId: model.userId,
      userName: model.userName,
      latitude: model.latitude,
      longitude: model.longitude,
      geohash: geohash,
      timestamp: model.timestamp,
      status: SOSStatus.active,
      videoUrl: model.videoUrl,
      notifiedUserIds: model.notifiedUserIds,
    );

    await _col.doc(id).set(modelWithId.toFirestore());
    return modelWithId;
  }

  @override
  Future<void> updateSOSStatus(String eventId, SOSStatus status) async {
    await _col.doc(eventId).update({
      'status': status.name,
      'resolvedAt': status == SOSStatus.resolved || status == SOSStatus.cancelled
          ? FieldValue.serverTimestamp()
          : null,
    });
  }

  @override
  Future<void> updateVideoUrl(String eventId, String videoUrl) async {
    await _col.doc(eventId).update({'videoUrl': videoUrl});
  }

  @override
  Stream<List<SOSEventModel>> watchActiveSOSEvents() {
    return _col
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .limit(50) // Safety cap — never pull unbounded collections
        .snapshots()
        .map((snap) => snap.docs.map(SOSEventModel.fromFirestore).toList());
  }

  @override
  Stream<SOSEventModel?> watchSOSEvent(String eventId) {
    return _col.doc(eventId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SOSEventModel.fromFirestore(doc);
    });
  }

  @override
  Future<List<SOSEventModel>> queryNearbySOSEvents(String geohash) async {
    // Geohash prefix search — prefix length 5 = ~4.9km radius
    final prefix = geohash.substring(0, 5);
    final snap = await _col
        .where('status', isEqualTo: 'active')
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThan: '${prefix}~')
        .limit(20)
        .get();

    return snap.docs.map(SOSEventModel.fromFirestore).toList();
  }
}