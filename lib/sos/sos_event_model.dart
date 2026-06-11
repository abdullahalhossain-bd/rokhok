// lib/data/models/sos_event_model.dart
// Data layer model: knows about Firestore serialization.
// Domain entity knows NOTHING about Firebase — this is the bridge.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'sos_event.dart';

class SOSEventModel extends SOSEvent {
  const SOSEventModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.latitude,
    required super.longitude,
    required super.geohash,
    required super.timestamp,
    required super.status,
    super.videoUrl,
    super.notifiedUserIds,
  });

  /// Deserialize from Firestore document snapshot
  factory SOSEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint;

    return SOSEventModel(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String? ?? 'Unknown',
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      geohash: data['geohash'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: _parseStatus(data['status'] as String?),
      videoUrl: data['videoUrl'] as String?,
      notifiedUserIds: List<String>.from(data['notifiedUserIds'] ?? []),
    );
  }

  /// Serialize to Firestore document map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'location': GeoPoint(latitude, longitude),
      'geohash': geohash,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'videoUrl': videoUrl,
      'notifiedUserIds': notifiedUserIds,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert to domain entity (strips Firestore awareness)
  SOSEvent toEntity() => SOSEvent(
    id: id,
    userId: userId,
    userName: userName,
    latitude: latitude,
    longitude: longitude,
    geohash: geohash,
    timestamp: timestamp,
    status: status,
    videoUrl: videoUrl,
    notifiedUserIds: notifiedUserIds,
  );

  static SOSStatus _parseStatus(String? raw) {
    return SOSStatus.values.firstWhere(
          (s) => s.name == raw,
      orElse: () => SOSStatus.idle,
    );
  }
}