// lib/data/repositories/sos_repository_impl.dart
// Implements ISOSRepository. Maps datasource exceptions → typed Failures.
// The BLoC never sees a raw Firebase exception — only clean Failure objects.

import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sos_event.dart';
import 'i_sos_repository.dart';
import 'sos_failures.dart';
import 'geohash_util.dart';
import 'sos_firestore_datasource.dart';
import 'sos_event_model.dart';

class SOSRepositoryImpl implements ISOSRepository {
  final ISOSFirestoreDatasource _datasource;

  SOSRepositoryImpl({required ISOSFirestoreDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Either<Failure, SOSEvent>> triggerSOS({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final geohash = GeohashUtil.encode(latitude, longitude);
      final model = SOSEventModel(
        id: '',
        userId: userId,
        userName: userName,
        latitude: latitude,
        longitude: longitude,
        geohash: geohash,
        timestamp: DateTime.now(),
        status: SOSStatus.active,
      );
      final created = await _datasource.createSOSEvent(model);
      return Right(created.toEntity());
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelSOS(String eventId) async {
    try {
      await _datasource.updateSOSStatus(eventId, SOSStatus.cancelled);
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<List<SOSEvent>> watchActiveSOSEvents() {
    return _datasource.watchActiveSOSEvents().map(
          (models) => models.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Stream<SOSEvent?> watchSOSEvent(String eventId) {
    return _datasource
        .watchSOSEvent(eventId)
        .map((m) => m?.toEntity());
  }

  @override
  Future<Either<Failure, Unit>> updateVideoUrl({
    required String eventId,
    required String videoUrl,
  }) async {
    try {
      await _datasource.updateVideoUrl(eventId, videoUrl);
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SOSEvent>>> getNearbySOSEvents({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final geohash = GeohashUtil.encode(latitude, longitude);
      final models = await _datasource.queryNearbySOSEvents(geohash);
      // Fine-filter by actual Haversine distance
      final filtered = models
          .map((m) => m.toEntity())
          .where((e) =>
      GeohashUtil.distanceKm(latitude, longitude, e.latitude, e.longitude) <= radiusKm)
          .toList();
      return Right(filtered);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}