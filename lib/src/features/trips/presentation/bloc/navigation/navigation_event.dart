part of 'navigation_bloc.dart';

sealed class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Page opened with either a freshly-created session (Start was just
/// pressed) or nothing (cold open / deep link) - in the latter case the bloc
/// resolves the active session itself via `GET .../current`.
class NavigationStarted extends NavigationEvent {
  const NavigationStarted();
}

/// The app came back to the foreground, or the page was reopened - re-syncs
/// with the server per the task's resume requirement.
class NavigationResumeRequested extends NavigationEvent {
  const NavigationResumeRequested();
}

/// One GPS fix from [LocationService.watchPosition] - internal, not user
/// driven.
class NavigationLocationUpdated extends NavigationEvent {
  final Position position;

  const NavigationLocationUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

/// Driver backed out before reaching the destination.
class NavigationCancelPressed extends NavigationEvent {
  const NavigationCancelPressed();
}
