import 'package:dartz/dartz.dart';
import 'i_sos_repository.dart';
import 'location_channel.dart';
import 'sos_channel.dart';
import 'sos_event.dart';
import 'sos_failures.dart';

class TriggerSOSUseCase {
  final ISOSRepository _sosRepository;
  final SOSChannel _sosChannel;
  final LocationChannel _locationChannel;

  TriggerSOSUseCase({
    required ISOSRepository sosRepository,
    required SOSChannel sosChannel,
    required LocationChannel locationChannel,
  })  : _sosRepository = sosRepository,
        _sosChannel = sosChannel,
        _locationChannel = locationChannel;

  Future<Either<Failure, SOSEvent>> call({
    required String userId,
    required String userName,
    required List<Map<String, String>> emergencyContacts,
  }) async {
    if (emergencyContacts.isEmpty) {
      return const Left(NoEmergencyContactsFailure());
    }

    final locationResult = await _locationChannel.getCurrentLocation();

    return locationResult.fold(
      Left.new,
      (location) async {
        final latitude = (location['latitude'] as num).toDouble();
        final longitude = (location['longitude'] as num).toDouble();

        final sosResult = await _sosRepository.triggerSOS(
          userId: userId,
          userName: userName,
          latitude: latitude,
          longitude: longitude,
        );

        return sosResult.fold(
          Left.new,
          (sosEvent) async {
            final nativeResult = await _sosChannel.startSOSServices(
              eventId: sosEvent.id,
              contacts: emergencyContacts,
              latitude: latitude,
              longitude: longitude,
            );

            return nativeResult.fold(
              Left.new,
              (_) => Right(sosEvent),
            );
          },
        );
      },
    );
  }
}
