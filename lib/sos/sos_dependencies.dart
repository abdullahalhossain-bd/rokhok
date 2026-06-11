import 'cancel_sos_usecase.dart';
import 'location_channel.dart';
import 'sos_bloc.dart';
import 'sos_channel.dart';
import 'sos_firestore_datasource.dart';
import 'sos_repository_impl.dart';
import 'trigger_sos_usecase.dart';

class SOSDependencies {
  static SOSBloc createBloc() {
    final datasource = SOSFirestoreDatasource();
    final repository = SOSRepositoryImpl(datasource: datasource);
    final sosChannel = SOSChannel();
    final locationChannel = LocationChannel();

    return SOSBloc(
      triggerSOS: TriggerSOSUseCase(
        sosRepository: repository,
        sosChannel: sosChannel,
        locationChannel: locationChannel,
      ),
      cancelSOS: CancelSOSUseCase(
        sosRepository: repository,
        sosChannel: sosChannel,
      ),
      sosRepository: repository,
    );
  }
}
