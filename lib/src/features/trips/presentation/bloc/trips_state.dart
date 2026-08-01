part of 'trips_bloc.dart';

enum TripsListStatus { initial, loading, success, failure }

class TripsState extends Equatable {
  final TripsListStatus listStatus;
  final TripsListStatus loadMoreStatus;
  final List<TripModel> items;
  final int page;
  final int lastPage;
  final int total;
  final String errorMessage;

  /// Toll-API error code (e.g. `DRIVER_SUSPENDED`, `TOLL_SESSION_MISSING`).
  /// Lets the error view special-case a missing toll account without string
  /// matching on the message.
  final String errorCode;

  /// The driver's in-progress navigation session, if any. Null means no active
  /// trip, which per docs §5.2 is a normal `200` with `data: null` and not an
  /// error - so a null here is indistinguishable from "not checked yet" by
  /// design: both hide the Continue Route card.
  final NavigationSessionModel? activeSession;

  const TripsState({
    this.listStatus = TripsListStatus.initial,
    this.loadMoreStatus = TripsListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
    this.errorMessage = '',
    this.errorCode = '',
    this.activeSession,
  });

  bool get hasMore => page < lastPage;

  /// Drives the Continue Route card. A session that has completed or been
  /// cancelled server-side must never offer to resume.
  bool get hasActiveSession => activeSession?.isActive == true;

  static const _sentinel = Object();

  TripsState copyWith({
    TripsListStatus? listStatus,
    TripsListStatus? loadMoreStatus,
    List<TripModel>? items,
    int? page,
    int? lastPage,
    int? total,
    String? errorMessage,
    String? errorCode,
    // Sentinel-guarded: clearing the session back to null is a real state
    // change (trip finished), which a plain `?? this.activeSession` would
    // silently ignore.
    Object? activeSession = _sentinel,
  }) {
    return TripsState(
      listStatus: listStatus ?? this.listStatus,
      loadMoreStatus: loadMoreStatus ?? this.loadMoreStatus,
      items: items ?? this.items,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      activeSession: identical(activeSession, _sentinel)
          ? this.activeSession
          : activeSession as NavigationSessionModel?,
    );
  }

  @override
  List<Object?> get props => [
        listStatus,
        loadMoreStatus,
        items,
        page,
        lastPage,
        total,
        errorMessage,
        errorCode,
        activeSession?.id,
        activeSession?.status,
      ];
}
