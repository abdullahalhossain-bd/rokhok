// lib/presentation/sos/bloc/sos_bloc.dart
// Single file for events + states + bloc (split into 3 files in large teams).
// The BLoC owns NO business logic — it delegates entirely to use cases.

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'sos_event.dart' as sos_entity;
import 'trigger_sos_usecase.dart';
import 'cancel_sos_usecase.dart';
import 'i_sos_repository.dart';
import 'sos_failures.dart';

// ─────────────────────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────────────────────
abstract class SOSEvent extends Equatable {
  const SOSEvent();
  @override
  List<Object?> get props => [];
}

/// User presses the SOS button
class SOSTriggerRequested extends SOSEvent {
  final String userId;
  final String userName;
  final List<Map<String, String>> emergencyContacts;

  const SOSTriggerRequested({
    required this.userId,
    required this.userName,
    required this.emergencyContacts,
  });

  @override
  List<Object?> get props => [userId, userName, emergencyContacts];
}

/// User confirms cancellation in the dialog
class SOSCancelRequested extends SOSEvent {
  final String eventId;
  const SOSCancelRequested(this.eventId);
  @override
  List<Object?> get props => [eventId];
}

/// Firestore real-time update arrives
class SOSEventUpdated extends SOSEvent {
  final SOSEventEntity? updatedEvent;
  const SOSEventUpdated(this.updatedEvent);
  @override
  List<Object?> get props => [updatedEvent];
}

/// Subscribe to live updates for an active SOS
class SOSWatchStarted extends SOSEvent {
  final String eventId;
  const SOSWatchStarted(this.eventId);
  @override
  List<Object?> get props => [eventId];
}

// ─────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────
abstract class SOSState extends Equatable {
  const SOSState();
  @override
  List<Object?> get props => [];
}

/// Nothing happening — button is ready
class SOSIdle extends SOSState {
  const SOSIdle();
}

/// SOS button pressed, waiting for location + Firestore write
class SOSTriggering extends SOSState {
  const SOSTriggering();
}

/// SOS is live — background services running, Firestore event active
class SOSActive extends SOSState {
  final SOSEventEntity event;
  final Duration elapsed;

  const SOSActive({required this.event, this.elapsed = Duration.zero});

  SOSActive copyWith({SOSEventEntity? event, Duration? elapsed}) {
    return SOSActive(
      event: event ?? this.event,
      elapsed: elapsed ?? this.elapsed,
    );
  }

  @override
  List<Object?> get props => [event, elapsed];
}

/// Cancel in progress
class SOSCancelling extends SOSState {
  final SOSEventEntity event;
  const SOSCancelling({required this.event});
  @override
  List<Object?> get props => [event];
}

/// SOS was successfully cancelled/resolved
class SOSResolved extends SOSState {
  const SOSResolved();
}

/// Any error state — message shown to user
class SOSFailureState extends SOSState {
  final Failure failure;
  const SOSFailureState(this.failure);
  @override
  List<Object?> get props => [failure];
}

typedef SOSEventEntity = sos_entity.SOSEvent;

// ─────────────────────────────────────────────────────────────
// BLOC
// ─────────────────────────────────────────────────────────────
class SOSBloc extends Bloc<SOSEvent, SOSState> {
  final TriggerSOSUseCase _triggerSOS;
  final CancelSOSUseCase _cancelSOS;
  final ISOSRepository _sosRepository;

  StreamSubscription<sos_entity.SOSEvent?>? _eventSubscription;
  Timer? _elapsedTimer;

  SOSBloc({
    required TriggerSOSUseCase triggerSOS,
    required CancelSOSUseCase cancelSOS,
    required ISOSRepository sosRepository,
  })  : _triggerSOS = triggerSOS,
        _cancelSOS = cancelSOS,
        _sosRepository = sosRepository,
        super(const SOSIdle()) {
    on<SOSTriggerRequested>(_onTriggerRequested);
    on<SOSCancelRequested>(_onCancelRequested);
    on<SOSEventUpdated>(_onEventUpdated);
    on<SOSWatchStarted>(_onWatchStarted);
  }

  // ── Handle trigger ──────────────────────────────────────
  Future<void> _onTriggerRequested(
      SOSTriggerRequested event,
      Emitter<SOSState> emit,
      ) async {
    emit(const SOSTriggering());

    final result = await _triggerSOS(
      userId: event.userId,
      userName: event.userName,
      emergencyContacts: event.emergencyContacts,
    );

    result.fold(
          (failure) => emit(SOSFailureState(failure)),
          (sosEvent) {
        emit(SOSActive(event: sosEvent));
        add(SOSWatchStarted(sosEvent.id));
        _startElapsedTimer(sosEvent);
      },
    );
  }

  // ── Handle cancel ───────────────────────────────────────
  Future<void> _onCancelRequested(
      SOSCancelRequested event,
      Emitter<SOSState> emit,
      ) async {
    final currentState = state;
    if (currentState is! SOSActive) return;

    emit(SOSCancelling(event: currentState.event));
    _stopElapsedTimer();
    _eventSubscription?.cancel();

    final result = await _cancelSOS(event.eventId);
    result.fold(
          (failure) => emit(SOSFailureState(failure)),
          (_) => emit(const SOSResolved()),
    );
  }

  // ── Handle real-time updates ────────────────────────────
  void _onEventUpdated(SOSEventUpdated event, Emitter<SOSState> emit) {
    final current = state;
    if (current is! SOSActive) return;
    if (event.updatedEvent == null) return;

    final updated = event.updatedEvent!;
    // If someone else resolved the SOS (e.g. admin), reflect it
    if (updated.status == sos_entity.SOSStatus.resolved ||
        updated.status == sos_entity.SOSStatus.cancelled) {
      _stopElapsedTimer();
      emit(const SOSResolved());
      return;
    }
    emit(current.copyWith(event: updated));
  }

  // ── Subscribe to Firestore stream ───────────────────────
  void _onWatchStarted(SOSWatchStarted event, Emitter<SOSState> emit) {
    _eventSubscription?.cancel();
    _eventSubscription = _sosRepository
        .watchSOSEvent(event.eventId)
        .listen((updatedEvent) => add(SOSEventUpdated(updatedEvent)));
  }

  // ── Elapsed time ticker ─────────────────────────────────
  void _startElapsedTimer(sos_entity.SOSEvent sosEvent) {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current is SOSActive) {
        final elapsed = DateTime.now().difference(sosEvent.timestamp);
        add(SOSEventUpdated(current.event)); // re-emit to rebuild timer display
      }
    });
  }

  void _stopElapsedTimer() => _elapsedTimer?.cancel();

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    _elapsedTimer?.cancel();
    return super.close();
  }
}