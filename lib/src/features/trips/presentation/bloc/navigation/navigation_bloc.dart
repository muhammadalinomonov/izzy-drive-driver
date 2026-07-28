import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_app/src/core/location_service.dart';
import 'package:taxi_app/src/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/src/features/trips/domain/repo/trips_repo.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

/// Backs Driving Mode (docs/ui/9.png): live GPS following, throttled progress
/// reporting to `POST .../locations`, auto-reroute on `off_route`, and
/// completion/cancellation of the session.
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final TripsRepo repo;
  final LocationService locationService;

  /// A route stops being "just picked" and becomes "reached" once this close
  /// - the API returns `percent`/`remaining_distance_meters` continuously
  /// rather than an explicit arrival flag, so arrival is inferred locally.
  static const double _arrivalRemainingMeters = 40;

  /// Reporting every GPS tick (as often as every 15m, per
  /// [LocationService.watchPosition]) would hit `RATE_LIMIT_EXCEEDED`; this
  /// gates how often a fix is actually sent to `.../locations`.
  static const Duration _reportInterval = Duration(seconds: 5);

  StreamSubscription<Position>? _positionSub;
  DateTime? _lastReportedAt;

  NavigationBloc({
    NavigationSessionModel? initialSession,
    required this.repo,
    required this.locationService,
  }) : super(NavigationState(
          status: initialSession == null
              ? NavigationPageStatus.loading
              : NavigationPageStatus.active,
          session: initialSession,
        )) {
    on<NavigationStarted>(_onStarted);
    on<NavigationResumeRequested>(_onResumeRequested);
    on<NavigationLocationUpdated>(_onLocationUpdated);
    on<NavigationCancelPressed>(_onCancelPressed);
  }

  @override
  Future<void> close() {
    _positionSub?.cancel();
    return super.close();
  }

  Future<void> _onStarted(NavigationStarted event, Emitter<NavigationState> emit) async {
    if (state.session == null) {
      await _resolveCurrentSession(emit);
    }
    _startWatchingPosition();
  }

  Future<void> _onResumeRequested(
    NavigationResumeRequested event,
    Emitter<NavigationState> emit,
  ) async {
    if (state.status == NavigationPageStatus.closed) return;
    await _resolveCurrentSession(emit);
  }

  Future<void> _resolveCurrentSession(Emitter<NavigationState> emit) async {
    final response = await repo.getCurrentNavigationSession();
    if (response.errorText.isNotEmpty) {
      emit(state.copyWith(
        status: NavigationPageStatus.error,
        errorMessage: response.errorText,
      ));
      return;
    }
    final session = response.data;
    if (session == null || !session.isActive) {
      emit(state.copyWith(
        status: NavigationPageStatus.closed,
        exitReason: NavigationExitReason.none,
      ));
      return;
    }
    emit(state.copyWith(status: NavigationPageStatus.active, session: session));
  }

  void _startWatchingPosition() {
    _positionSub ??= locationService.watchPosition().listen(
          (position) => add(NavigationLocationUpdated(position)),
        );
  }

  Future<void> _onLocationUpdated(
    NavigationLocationUpdated event,
    Emitter<NavigationState> emit,
  ) async {
    // Camera should track every fix even when the server report is throttled.
    emit(state.copyWith(lastPosition: event.position));

    final session = state.session;
    if (session == null || !session.isActive) return;

    final now = DateTime.now();
    if (_lastReportedAt != null && now.difference(_lastReportedAt!) < _reportInterval) {
      return;
    }
    _lastReportedAt = now;

    final response = await repo.sendNavigationLocation(
      session.id,
      occurredAt: now,
      latitude: event.position.latitude,
      longitude: event.position.longitude,
      speedMph: event.position.speed >= 0 ? event.position.speed * 2.23694 : null,
      headingDegrees: event.position.heading >= 0 ? event.position.heading : null,
      accuracyMeters: event.position.accuracy,
    );

    if (response.errorText.isNotEmpty || response.data == null) {
      // A closed/missing session on the server means the trip already ended
      // elsewhere (e.g. completed from another device) - reflect that
      // locally instead of surfacing a transient error.
      if (response.errorCode == 'NAVIGATION_SESSION_CLOSED' ||
          response.errorCode == 'RESOURCE_NOT_FOUND') {
        emit(state.copyWith(status: NavigationPageStatus.closed));
      }
      return;
    }

    final updated = response.data!;
    if (updated.progress.remainingDistanceMeters <= _arrivalRemainingMeters) {
      await _complete(emit, updated);
      return;
    }

    if (updated.progress.offRoute) {
      emit(state.copyWith(status: NavigationPageStatus.rerouting, session: updated));
      final rerouted = await repo.rerouteNavigationSession(
        session.id,
        currentLocation:
            TripCoordinate(lat: event.position.latitude, lng: event.position.longitude),
      );
      emit(state.copyWith(
        status: NavigationPageStatus.active,
        session: rerouted.data ?? updated,
      ));
      return;
    }

    emit(state.copyWith(session: updated));
  }

  Future<void> _complete(Emitter<NavigationState> emit, NavigationSessionModel session) async {
    await repo.completeNavigationSession(session.id);
    emit(state.copyWith(
      status: NavigationPageStatus.closed,
      exitReason: NavigationExitReason.completed,
    ));
  }

  Future<void> _onCancelPressed(
    NavigationCancelPressed event,
    Emitter<NavigationState> emit,
  ) async {
    final session = state.session;
    if (session == null) {
      emit(state.copyWith(
        status: NavigationPageStatus.closed,
        exitReason: NavigationExitReason.cancelled,
      ));
      return;
    }
    await repo.cancelNavigationSession(session.id);
    emit(state.copyWith(
      status: NavigationPageStatus.closed,
      exitReason: NavigationExitReason.cancelled,
    ));
  }
}
