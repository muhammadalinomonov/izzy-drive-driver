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

  /// Reporting every GPS tick (as often as every 3m, per
  /// [LocationService.watchPosition]) would hit `RATE_LIMIT_EXCEEDED`; this
  /// gates how often a fix is actually sent to `.../locations`.
  static const Duration _reportInterval = Duration(seconds: 5);

  DateTime? _lastReportedAt;

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
  }

  Future<void> _onStarted(NavigationStarted event, Emitter<NavigationState> emit) async {
    if (state.session == null) {
      await _resolveCurrentSession(emit);
    }
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

  Future<void> _onLocationUpdated(
    NavigationLocationUpdated event,
    Emitter<NavigationState> emit,
  ) async {
    final session = state.session;
    if (session == null || !session.isActive) return;

    final now = DateTime.now();
    if (_lastReportedAt != null && now.difference(_lastReportedAt!) < _reportInterval) {
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

    emit(state.copyWith(session: updated));
  }

  /// Local off-route detection beat the server's flag - reroute now.
  Future<void> _onRerouteRequested(
    NavigationRerouteRequested event,
    Emitter<NavigationState> emit,
  ) async {
    final session = state.session;
    if (session == null || !session.isActive) return;
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
      emit(state.copyWith(
        status: NavigationPageStatus.active,
        session: rerouted.data ?? fallback ?? state.session,
      ));
    } finally {
      _rerouteInFlight = false;
    }
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
