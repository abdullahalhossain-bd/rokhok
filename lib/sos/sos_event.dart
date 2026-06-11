// lib/domain/entities/sos_event.dart
// Pure domain entity — no Firebase, no JSON. Just business truth.

import 'package:equatable/equatable.dart';

enum SOSStatus { idle, active, cancelled, resolved }

class SOSEvent extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final String geohash;
  final DateTime timestamp;
  final SOSStatus status;
  final String? videoUrl;
  final List<String> notifiedUserIds;

  const SOSEvent({
    required this.id,
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.timestamp,
    required this.status,
    this.videoUrl,
    this.notifiedUserIds = const [],
  });

  SOSEvent copyWith({
    String? id,
    String? userId,
    String? userName,
    double? latitude,
    double? longitude,
    String? geohash,
    DateTime? timestamp,
    SOSStatus? status,
    String? videoUrl,
    List<String>? notifiedUserIds,
  }) {
    return SOSEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      videoUrl: videoUrl ?? this.videoUrl,
      notifiedUserIds: notifiedUserIds ?? this.notifiedUserIds,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, userName, latitude, longitude,
    geohash, timestamp, status, videoUrl, notifiedUserIds,
  ];
}