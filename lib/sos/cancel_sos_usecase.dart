// lib/domain/usecases/sos/cancel_sos_usecase.dart

import 'package:dartz/dartz.dart';
import 'i_sos_repository.dart';
import 'sos_failures.dart';
import 'sos_channel.dart';

class CancelSOSUseCase {
  final ISOSRepository _sosRepository;
  final SOSChannel _sosChannel;

  CancelSOSUseCase({
    required ISOSRepository sosRepository,
    required SOSChannel sosChannel,
  })  : _sosRepository = sosRepository,
        _sosChannel = sosChannel;

  Future<Either<Failure, Unit>> call(String eventId) async {
    // Stop all native background services first
    await _sosChannel.stopSOSServices();

    // Then mark Firestore event as cancelled
    return _sosRepository.cancelSOS(eventId);
  }
}