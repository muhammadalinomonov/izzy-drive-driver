part of 'route_overview_bloc.dart';

enum RouteOverviewStartStatus { idle, loading, failure }

class RouteOverviewState extends Equatable {
  final TripModel trip;
  final String selectedAlternativeId;

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

  TripAlternative? get selectedAlternative {
    if (alternatives.isEmpty) return null;
    for (final a in alternatives) {
      if (a.id == selectedAlternativeId) return a;
    }
    return alternatives.first;
  }

  static const _sentinel = Object();

  RouteOverviewState copyWith({
    String? selectedAlternativeId,
    RouteOverviewStartStatus? startStatus,
    String? startError,
    Object? session = _sentinel,
    int? startTick,
  }) {
    return RouteOverviewState(
      trip: trip,
      selectedAlternativeId: selectedAlternativeId ?? this.selectedAlternativeId,
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
        startStatus,
        startError,
        session,
        startTick,
      ];
}
