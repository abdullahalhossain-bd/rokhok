// lib/services/platform/location_channel.dart
// Dart bridge for GPS / location operations.
// Uses both MethodChannel (one-shot) and EventChannel (stream).

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'sos_failures.dart';

class LocationChannel {
  static const _method  = MethodChannel('com.rokhok.app/location');
  static const _events  = EventChannel('com.rokhok.app/location/stream');

  /// One-shot: get current GPS fix.
  /// Returns map with keys: latitude, longitude, accuracy, altitude.
  Future<Either<Failure, Map<String, dynamic>>> getCurrentLocation() async {
    try {
      final result = await _method.invokeMapMethod<String, dynamic>(
        'getCurrentLocation',
      );
      if (result == null) {
        return Left(const LocationServiceFailure());
      }
      return Right(result);
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        return Left(const LocationPermissionFailure());
      }
      if (e.code == 'SERVICE_DISABLED') {
        return Left(const LocationServiceFailure());
      }
      return Left(NativeChannelFailure(e.message ?? 'Location error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Continuous stream of location updates.
  /// In normal mode: updates every 10 seconds.
  /// In SOS mode: updates every 3 seconds (set via startSOSServices).
  Stream<Map<String, dynamic>> get locationStream {
    return _events.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
  }

  /// Request location permissions explicitly (call before first use)
  Future<Either<Failure, Unit>> requestPermissions() async {
    try {
      final granted = await _method.invokeMethod<bool>('requestPermissions');
      if (granted == true) return const Right(unit);
      return Left(const LocationPermissionFailure());
    } on PlatformException catch (e) {
      return Left(NativeChannelFailure(e.message ?? 'Permission error'));
    }
  }
}