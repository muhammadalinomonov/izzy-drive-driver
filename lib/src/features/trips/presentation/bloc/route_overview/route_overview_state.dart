part of 'route_overview_bloc.dart';

enum RouteOverviewStartStatus { idle, loading, failure }

/// Progress of the initial `GET toll-routes/{id}` + endpoint reverse-geocode.
/// `idle` also covers the planner flow, which arrives with everything already
/// in hand and never hits the network here.
enum RouteOverviewLoadStatus { idle, loading, failure }

class RouteOverviewState extends Equatable {
  final TripModel trip;
  final String selectedAlternativeId;

  /// Human-readable endpoints. Null only while the detail is still loading -
  /// the toll-route payload carries raw coordinates, not geocoded labels.
  final PlaceModel? origin;
  final PlaceModel? destination;

  final RouteOverviewLoadStatus loadStatus;
  final String loadError;

  final RouteOverviewStartStatus startStatus;
  final String startError;

  /// The session created by the last successful Start. The page listens on
  /// [startTick] (not this field alone) so navigating to the same session
  /// twice in a row still fires - mirrors [TripMapState.continueTick].
  final NavigationSessionModel? session;
  final int startTick;

  const RouteOverviewState({
    required this.trip,
    required this.selectedAlternativeId,
    this.origin,
    this.destination,
    this.loadStatus = RouteOverviewLoadStatus.idle,
    this.loadError = '',
    this.startStatus = RouteOverviewStartStatus.idle,
    this.startError = '',
    this.session,
    this.startTick = 0,
  });

  List<TripAlternative> get alternatives => trip.alternatives;

  /// A `calculated` route with no alternatives is a real (if unlikely) API
  /// response, not just a "still loading" state - the page renders an empty
  /// state instead of the map/sheet when this is empty.
  bool get hasAlternatives => alternatives.isNotEmpty;

  /// The map and the waypoint list both need the endpoints, so they only draw
  /// once the detail has landed.
  bool get isReady =>
      loadStatus == RouteOverviewLoadStatus.idle &&
      origin != null &&
      destination != null;

  TripAlternative? get selectedAlternative {
    if (alternatives.isEmpty) return null;
    for (final a in alternatives) {
      if (a.id == selectedAlternativeId) return a;
    }
    return alternatives.first;
  }

  static const _sentinel = Object();

  RouteOverviewState copyWith({
    TripModel? trip,
    String? selectedAlternativeId,
    PlaceModel? origin,
    PlaceModel? destination,
    RouteOverviewLoadStatus? loadStatus,
    String? loadError,
    RouteOverviewStartStatus? startStatus,
    String? startError,
    Object? session = _sentinel,
    int? startTick,
  }) {
    return RouteOverviewState(
      trip: trip ?? this.trip,
      selectedAlternativeId: selectedAlternativeId ?? this.selectedAlternativeId,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      loadStatus: loadStatus ?? this.loadStatus,
      loadError: loadError ?? this.loadError,
      startStatus: startStatus ?? this.startStatus,
      startError: startError ?? this.startError,
      session: identical(session, _sentinel)
          ? this.session
          : session as NavigationSessionModel?,
      startTick: startTick ?? this.startTick,
    );
  }

  @override
  List<Object?> get props => [
        trip,
        selectedAlternativeId,
        origin,
        destination,
        loadStatus,
        loadError,
        startStatus,
        startError,
        session,
        startTick,
      ];
}
