// lib/services/platform/sos_channel.dart
// Dart-side MethodChannel bridge to the Java background services.
// All native calls are wrapped in try/catch and return Either<Failure, T>.
//
// CHANNEL NAMES must match exactly in MainActivity.java.
// Convention: reverse-domain + feature, all lowercase.

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'sos_failures.dart';

class SOSChannel {
  static const _channel = MethodChannel('com.rokhok.app/sos');

  /// Tell the Java side to:
  ///   1. Start RokhokForegroundService (persistent notification)
  ///   2. Start LocationTrackingService (high-frequency GPS)
  ///   3. Send SMS to emergency contacts
  ///   4. Start VideoRecordService (silent capture)
  Future<Either<Failure, Unit>> startSOSServices({
    required String eventId,
    required List<Map<String, String>> contacts,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _channel.invokeMethod('startSOS', {
        'eventId': eventId,
        'contacts': contacts, // [{name, phone}]
        'latitude': latitude,
        'longitude': longitude,
      });
      return const Right(unit);
    } on PlatformException catch (e) {
      return Left(NativeChannelFailure(e.message ?? 'Native SOS start failed'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Stop all SOS background services
  Future<Either<Failure, Unit>> stopSOSServices() async {
    try {
      await _channel.invokeMethod('stopSOS');
      return const Right(unit);
    } on PlatformException catch (e) {
      return Left(NativeChannelFailure(e.message ?? 'Native SOS stop failed'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Check if SOS services are currently running (useful on app resume)
  Future<bool> isSOSActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSOSActive');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Send a test SMS to verify contacts (used in profile setup)
  Future<Either<Failure, Unit>> sendTestSMS({
    required String phone,
    required String name,
  }) async {
    try {
      await _channel.invokeMethod('sendTestSMS', {
        'phone': phone,
        'name': name,
      });
      return const Right(unit);
    } on PlatformException catch (e) {
      return Left(SMSFailure(e.message ?? 'SMS failed'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}