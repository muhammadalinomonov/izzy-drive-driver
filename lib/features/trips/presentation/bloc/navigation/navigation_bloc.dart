import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_app/core/location_service.dart';
import 'package:taxi_app/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/features/trips/domain/repo/trips_repo.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

/// Backs Driving Mode: throttled progress reporting, auto-reroute, arrival
/// detection, and completion/cancellation of the session.
///
/// The GPS subscription itself belongs to `DrivingSession` (it needs every fix
/// for smoothing and marker animation); the bloc only receives forwarded fixes
/// and decides what reaches the server.
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final TripsRepo repo;
  final LocationService locationService;

  /// Arrival threshold. The API exposes no explicit "arrived" flag - it
  /// returns `percent` and `remaining_distance_meters` continuously (docs
  /// §5.3) - so arrival is inferred locally and then confirmed by calling
  /// `complete`.
  static const double _arrivalRemainingMeters = 40;

  /// Reporting every GPS tick (as often as every 3m, per
  /// [LocationService.watchPosition]) would hit `RATE_LIMIT_EXCEEDED`; this
  /// gates how often a fix is actually sent to `.../locations`.
  static const Duration _reportInterval = Duration(seconds: 5);

  /// Background fleet GPS is a much coarser signal than turn-by-turn progress
  /// - it exists so dispatch can see where the truck is, not to guide anyone -
  /// so it posts far less often and on its own clock.
  static const Duration _fleetReportInterval = Duration(seconds: 30);

  /// Consecutive failed progress posts before the UI admits to being offline.
  /// One miss is a blip; three in a row across ~15s is a real outage.
  static const int _offlineThreshold = 3;

  DateTime? _lastReportedAt;
  DateTime? _lastFleetReportedAt;
  int _consecutiveFailures = 0;

  /// Truck to attribute background GPS to. Null when the driver has no
  /// vehicle assigned, which docs §3.4 treats as normal - fleet posting is
  /// then skipped and navigation continues unaffected.
  String? _vehicleId;

  /// Guards the two paths that can ask for a reroute - the server's
  /// `off_route` flag and [DrivingSession]'s local detection - from firing
  /// overlapping requests for the same divergence.
  bool _rerouteInFlight = false;

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
    on<NavigationRerouteRequested>(_onRerouteRequested);
    on<NavigationCancelPressed>(_onCancelPressed);
    on<NavigationCompleteRequested>(_onCompleteRequested);
    on<NavigationCompletionAcknowledged>(_onCompletionAcknowledged);
  }

  Future<void> _onStarted(
    NavigationStarted event,
    Emitter<NavigationState> emit,
  ) async {
    if (state.session == null) {
      await _resolveCurrentSession(emit);
    }
    // Fire-and-forget: a missing vehicle only disables fleet posting, so this
    // must never gate the trip starting.
    unawaited(_resolveVehicle());
  }

  Future<void> _onResumeRequested(
    NavigationResumeRequested event,
    Emitter<NavigationState> emit,
  ) async {
    if (state.isFinished || state.isBusy) return;
    await _resolveCurrentSession(emit);
  }

  /// Re-syncs with `GET .../current`, used on open and on app resume.
  ///
  /// Per docs §5.2 a `200` with `data: null` means "nothing active" and is not
  /// an error - the trip ended elsewhere, so the screen closes rather than
  /// showing a failure.
  Future<void> _resolveCurrentSession(Emitter<NavigationState> emit) async {
    final response = await repo.getCurrentNavigationSession();
    if (response.errorText.isNotEmpty) {
      // A resume failure with a session already on screen is survivable: keep
      // navigating on what we have rather than blanking a live trip.
      if (state.session != null) {
        emit(state.copyWith(isOffline: true));
        return;
      }
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
    emit(state.copyWith(
      status: NavigationPageStatus.active,
      session: session,
      isOffline: false,
      errorMessage: '',
    ));
  }

  /// Caches the driver's assigned truck id for background GPS.
  Future<void> _resolveVehicle() async {
    if (_vehicleId != null) return;
    final response = await repo.fetchVehicles();
    if (response.errorText.isNotEmpty) return;
    final vehicles = response.data ?? const [];
    if (vehicles.isEmpty) return;
    _vehicleId = vehicles.firstWhere(
      (v) => v.isActive,
      orElse: () => vehicles.first,
    ).id;
  }

  Future<void> _onLocationUpdated(
    NavigationLocationUpdated event,
    Emitter<NavigationState> emit,
  ) async {
    final session = state.session;
    // Nothing is uploaded once the trip is over, or while a close request is
    // in flight - the session is about to stop accepting posts (409).
    if (session == null ||
        !session.isActive ||
        state.isFinished ||
        state.isBusy) {
      return;
    }

    final now = DateTime.now();
    unawaited(_reportFleetLocation(event.position, now));

    if (_lastReportedAt != null &&
        now.difference(_lastReportedAt!) < _reportInterval) {
      return;
    }
    _lastReportedAt = now;

    // `lastPosition` deliberately rides the throttle rather than every fix.
    // At a 3 m filter and highway speed the stream delivers ~9 fixes/second,
    // and emitting each one would rebuild the whole map stack that often. The
    // marker and camera don't need it: they run off [MarkerAnimator]'s 60 fps
    // snapshot, which never touches bloc state.
    emit(state.copyWith(lastPosition: event.position));

    final response = await repo.sendNavigationLocation(
      session.id,
      occurredAt: now,
      latitude: event.position.latitude,
      longitude: event.position.longitude,
      speedMph:
          event.position.speed >= 0 ? event.position.speed * 2.23694 : null,
      headingDegrees:
          event.position.heading >= 0 ? event.position.heading : null,
      accuracyMeters: event.position.accuracy,
    );

    if (response.errorText.isNotEmpty || response.data == null) {
      // A closed/missing session on the server means the trip already ended
      // elsewhere (e.g. completed from another device) - reflect that locally
      // instead of retrying into a wall.
      if (response.errorCode == 'NAVIGATION_SESSION_CLOSED' ||
          response.errorCode == 'RESOURCE_NOT_FOUND') {
        emit(state.copyWith(status: NavigationPageStatus.closed));
        return;
      }

      // Everything else - dropped connection, rate limit, a 5xx - is treated
      // as transient. Guidance keeps running off the locally-snapped route,
      // and the next fix retries naturally; no backoff timer needed because
      // fixes keep arriving on their own.
      _consecutiveFailures++;
      if (_consecutiveFailures >= _offlineThreshold && !state.isOffline) {
        emit(state.copyWith(isOffline: true));
      }
      return;
    }

    // Connectivity restored.
    if (_consecutiveFailures > 0 || state.isOffline) {
      _consecutiveFailures = 0;
    }

    final updated = response.data!;
    if (updated.progress.remainingDistanceMeters <= _arrivalRemainingMeters) {
      emit(state.copyWith(session: updated, isOffline: false));
      add(const NavigationCompleteRequested());
      return;
    }

    if (updated.progress.offRoute) {
      emit(state.copyWith(session: updated, isOffline: false));
      await _reroute(
        emit,
        sessionId: session.id,
        origin: TripCoordinate(
          lat: event.position.latitude,
          lng: event.position.longitude,
        ),
        fallback: updated,
      );
      return;
    }

    emit(state.copyWith(session: updated, isOffline: false));
  }

  /// Posts the truck's position to `mobile/locations` (docs §6.1).
  ///
  /// Deliberately separate from the progress report above: per §6.1 this
  /// endpoint does **not** advance navigation progress, off-route state or the
  /// next maneuver - it only records where the vehicle is, whether or not a
  /// trip is running. Failures are silent; fleet tracking must never disturb
  /// turn-by-turn guidance.
  Future<void> _reportFleetLocation(Position position, DateTime now) async {
    final vehicleId = _vehicleId;
    if (vehicleId == null) return;
    if (_lastFleetReportedAt != null &&
        now.difference(_lastFleetReportedAt!) < _fleetReportInterval) {
      return;
    }
    _lastFleetReportedAt = now;

    await repo.sendFleetLocation(
      vehicleId: vehicleId,
      // Doubles as the idempotency key, so a retry of the same fix is safe.
      occurredAt: now,
      latitude: position.latitude,
      longitude: position.longitude,
      speedMph: position.speed >= 0 ? position.speed * 2.23694 : null,
      headingDegrees: position.heading >= 0 ? position.heading : null,
      accuracyMeters: position.accuracy,
    );
  }

  /// Local off-route detection beat the server's flag - reroute now.
  Future<void> _onRerouteRequested(
    NavigationRerouteRequested event,
    Emitter<NavigationState> emit,
  ) async {
    final session = state.session;
    if (session == null ||
        !session.isActive ||
        state.isFinished ||
        state.isBusy) {
      return;
    }
    await _reroute(emit, sessionId: session.id, origin: event.origin);
  }

  /// Single reroute path shared by the server flag and local detection.
  ///
  /// The server remains authoritative for the new geometry either way; local
  /// detection only decides *when* to ask, saving up to a full report interval
  /// of driving down the wrong road.
  Future<void> _reroute(
    Emitter<NavigationState> emit, {
    required String sessionId,
    required TripCoordinate origin,
    NavigationSessionModel? fallback,
  }) async {
    if (_rerouteInFlight) {
      if (fallback != null) emit(state.copyWith(session: fallback));
      return;
    }
    _rerouteInFlight = true;
    emit(state.copyWith(
      status: NavigationPageStatus.rerouting,
      session: fallback ?? state.session,
    ));
    try {
      final rerouted = await repo.rerouteNavigationSession(
        sessionId,
        currentLocation: origin,
      );
      if (rerouted.errorText.isEmpty && rerouted.data != null) {
        emit(state.copyWith(
          status: NavigationPageStatus.active,
          session: rerouted.data,
          isOffline: false,
        ));
        return;
      }
      if (rerouted.errorCode == 'NAVIGATION_SESSION_CLOSED' ||
          rerouted.errorCode == 'RESOURCE_NOT_FOUND') {
        emit(state.copyWith(status: NavigationPageStatus.closed));
        return;
      }
      // Reroute failed but the trip is fine - keep navigating the old line and
      // let the next off-route detection try again.
      emit(state.copyWith(
        status: NavigationPageStatus.active,
        session: fallback ?? state.session,
        isOffline: true,
      ));
    } finally {
      _rerouteInFlight = false;
    }
  }

  /// Closes the session as completed. Shows the summary rather than popping,
  /// so the driver gets confirmation the trip was recorded.
  Future<void> _onCompleteRequested(
    NavigationCompleteRequested event,
    Emitter<NavigationState> emit,
  ) async {
    final session = state.session;
    if (session == null || state.isFinished) return;
    if (state.status == NavigationPageStatus.completing) return;

    emit(state.copyWith(
      status: NavigationPageStatus.completing,
      errorMessage: '',
    ));

    final response = await repo.completeNavigationSession(session.id);

    if (response.errorText.isEmpty && response.data != null) {
      emit(state.copyWith(
        status: NavigationPageStatus.completed,
        session: response.data,
        completedSession: response.data,
        exitReason: NavigationExitReason.completed,
        isOffline: false,
      ));
      return;
    }

    // Already closed server-side counts as done - the trip is over either way,
    // and showing an error over a finished trip would be a lie.
    if (response.errorCode == 'NAVIGATION_SESSION_CLOSED') {
      emit(state.copyWith(
        status: NavigationPageStatus.completed,
        completedSession: state.session,
        exitReason: NavigationExitReason.completed,
      ));
      return;
    }

    // Otherwise stay on the road: back to active with the error surfaced, so
    // the next arrival-range fix retries and the driver can retry by hand.
    emit(state.copyWith(
      status: NavigationPageStatus.active,
      errorMessage: response.errorText,
    ));
  }

  void _onCompletionAcknowledged(
    NavigationCompletionAcknowledged event,
    Emitter<NavigationState> emit,
  ) {
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
    if (state.isBusy || state.isFinished) return;

    // Hold the screen with a spinner until the server confirms. Popping first
    // would leave the driver on the Trips page with a Continue Route card for
    // a trip they just cancelled.
    emit(state.copyWith(
      status: NavigationPageStatus.cancelling,
      errorMessage: '',
    ));

    final response = await repo.cancelNavigationSession(session.id);

    // An already-closed session is a successful cancel from the driver's point
    // of view - the trip is not running any more.
    if (response.errorText.isEmpty ||
        response.errorCode == 'NAVIGATION_SESSION_CLOSED' ||
        response.errorCode == 'RESOURCE_NOT_FOUND') {
      emit(state.copyWith(
        status: NavigationPageStatus.closed,
        exitReason: NavigationExitReason.cancelled,
      ));
      return;
    }

    // Cancel genuinely failed - stay in the trip and say so, rather than
    // pretending it stopped.
    emit(state.copyWith(
      status: NavigationPageStatus.active,
      errorMessage: response.errorText,
    ));
  }
}
