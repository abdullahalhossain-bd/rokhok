import 'package:dartz/dartz.dart';
import 'sos_event.dart';
import 'sos_failures.dart';

abstract class ISOSRepository {
  Future<Either<Failure, SOSEvent>> triggerSOS({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, Unit>> cancelSOS(String eventId);

  Stream<List<SOSEvent>> watchActiveSOSEvents();

  Stream<SOSEvent?> watchSOSEvent(String eventId);

  Future<Either<Failure, Unit>> updateVideoUrl({
    required String eventId,
    required String videoUrl,
  });

  Future<Either<Failure, List<SOSEvent>>> getNearbySOSEvents({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
}
