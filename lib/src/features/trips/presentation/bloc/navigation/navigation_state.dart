part of 'navigation_bloc.dart';

enum NavigationPageStatus {
  loading,
  active,
  rerouting,

  /// Cancel confirmed, waiting on `POST .../cancel`. The screen stays up
  /// behind a blocking spinner until the server has actually closed the
  /// session - popping first would leave a trip running server-side.
  cancelling,

  /// Arrival detected, waiting on `POST .../complete`.
  completing,

  /// The trip finished successfully and the summary is on screen. Distinct
  /// from [closed]: the driver still has to acknowledge it.
  completed,

  closed,
  error,
}

/// Why the session ended, so the page can decide where to go next without
/// re-deriving it from [NavigationSessionModel.status].
enum NavigationExitReason { none, completed, cancelled }

class NavigationState extends Equatable {
  final NavigationPageStatus status;
  final NavigationSessionModel? session;
  final Position? lastPosition;
  final String errorMessage;
  final NavigationExitReason exitReason;

  /// True while location reports are failing for network reasons. Navigation
  /// keeps running on locally-computed guidance; this only drives an
  /// indicator, because a tunnel is not a reason to end a trip.
  final bool isOffline;

  /// The closed session returned by `POST .../complete`, carrying the final
  /// `percent`, timestamps and route totals shown in the summary.
  final NavigationSessionModel? completedSession;

  const NavigationState({
    this.status = NavigationPageStatus.loading,
    this.session,
    this.lastPosition,
    this.errorMessage = '',
    this.exitReason = NavigationExitReason.none,
    this.isOffline = false,
    this.completedSession,
  });

  static const _sentinel = Object();

  /// True while a blocking request is in flight and the driver must wait.
  bool get isBusy =>
      status == NavigationPageStatus.cancelling ||
      status == NavigationPageStatus.completing;

  /// True once the trip is over by any route - nothing more should be
  /// uploaded for this session.
  bool get isFinished =>
      status == NavigationPageStatus.completed ||
      status == NavigationPageStatus.closed;

  NavigationState copyWith({
    NavigationPageStatus? status,
    Object? session = _sentinel,
    Object? lastPosition = _sentinel,
    String? errorMessage,
    NavigationExitReason? exitReason,
    bool? isOffline,
    Object? completedSession = _sentinel,
  }) {
    return NavigationState(
      status: status ?? this.status,
      session: identical(session, _sentinel)
          ? this.session
          : session as NavigationSessionModel?,
      lastPosition: identical(lastPosition, _sentinel)
          ? this.lastPosition
          : lastPosition as Position?,
      errorMessage: errorMessage ?? this.errorMessage,
      exitReason: exitReason ?? this.exitReason,
      isOffline: isOffline ?? this.isOffline,
      completedSession: identical(completedSession, _sentinel)
          ? this.completedSession
          : completedSession as NavigationSessionModel?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        session,
        lastPosition,
        errorMessage,
        exitReason,
        isOffline,
        completedSession,
      ];
}
