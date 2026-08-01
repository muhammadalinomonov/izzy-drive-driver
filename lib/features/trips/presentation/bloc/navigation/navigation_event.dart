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

/// One GPS fix forwarded by [DrivingSession] - internal, not user driven.
///
/// The session owns the GPS subscription (it needs every fix for smoothing and
/// marker animation); the bloc only throttles them out to the server.
class NavigationLocationUpdated extends NavigationEvent {
  final Position position;

  const NavigationLocationUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

/// [DrivingSession] detected the driver off the planned line locally (55 m for
/// three consecutive fixes). Fires a reroute immediately rather than waiting
/// for the server's `off_route` flag to come back on the next report cycle.
class NavigationRerouteRequested extends NavigationEvent {
  final TripCoordinate origin;

  const NavigationRerouteRequested(this.origin);

  @override
  List<Object?> get props => [origin.lat, origin.lng];
}

/// Driver backed out before reaching the destination, and has already
/// confirmed it in the dialog.
class NavigationCancelPressed extends NavigationEvent {
  const NavigationCancelPressed();
}

/// Arrival was detected, or the driver retried after a failed completion.
/// Closes the session with `POST .../complete`, which per docs §5.6 is a
/// different outcome from cancelling - only this one means "arrived".
class NavigationCompleteRequested extends NavigationEvent {
  const NavigationCompleteRequested();
}

/// Done pressed on the trip summary - tear the screen down.
class NavigationCompletionAcknowledged extends NavigationEvent {
  const NavigationCompletionAcknowledged();
}
