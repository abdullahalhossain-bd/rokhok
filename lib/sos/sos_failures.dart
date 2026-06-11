// lib/core/errors/sos_failures.dart
// Typed failures — every repo returns Either<Failure, T>.
// This forces the UI to handle every error path at compile time.

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  List<Object> get props => [message];
}

class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure()
      : super('Location permission denied. Please enable it in Settings.');
}

class LocationServiceFailure extends Failure {
  const LocationServiceFailure()
      : super('Location services are disabled. Please turn on GPS.');
}

class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}

class SMSFailure extends Failure {
  const SMSFailure(super.message);
}

class NativeChannelFailure extends Failure {
  const NativeChannelFailure(super.message);
}

class NoEmergencyContactsFailure extends Failure {
  const NoEmergencyContactsFailure()
      : super('No emergency contacts set. Please add contacts in your profile.');
}

class VideoRecordFailure extends Failure {
  const VideoRecordFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure()
      : super('No internet connection. SMS will still be sent.');
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}