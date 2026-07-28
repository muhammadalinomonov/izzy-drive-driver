part of 'navigation_bloc.dart';

enum NavigationPageStatus { loading, active, rerouting, closed, error }

/// Why the session ended, so the page can decide where to go next without
/// re-deriving it from [NavigationSessionModel.status].
enum NavigationExitReason { none, completed, cancelled }

class NavigationState extends Equatable {
  final NavigationPageStatus status;
  final NavigationSessionModel? session;
  final Position? lastPosition;
  final String errorMessage;
  final NavigationExitReason exitReason;

  const NavigationState({
    this.status = NavigationPageStatus.loading,
    this.session,
    this.lastPosition,
    this.errorMessage = '',
    this.exitReason = NavigationExitReason.none,
  });

  static const _sentinel = Object();

  NavigationState copyWith({
    NavigationPageStatus? status,
    Object? session = _sentinel,
    Object? lastPosition = _sentinel,
    String? errorMessage,
    NavigationExitReason? exitReason,
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
    );
  }

  @override
  List<Object?> get props => [status, session, lastPosition, errorMessage, exitReason];
}
