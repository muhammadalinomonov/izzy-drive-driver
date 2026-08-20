part of 'route_support_bloc.dart';

abstract class RouteSupportEvent extends Equatable {
  const RouteSupportEvent();

  @override
  List<Object?> get props => [];
}

/// Creates the review for the route the page was opened with. Also the retry
/// - a retry re-sends the same create call under the same idempotency key, so
/// it resolves to the original review rather than duplicating it.
class RouteSupportStarted extends RouteSupportEvent {
  const RouteSupportStarted();
}

/// Re-reads the review. This is the whole reconcile mechanism: a dispatcher's
/// decision, a suggested alternative and a fuel recommendation are never
/// pushed to the client as chat content, they only appear in the review's own
/// REST representation (docs/mobile-chat-route-fuel-drive.md §2.2).
///
/// Silent by design - it runs on a timer and on resume, and must not flash the
/// thread back to a spinner underneath the driver.
class RouteSupportRefreshed extends RouteSupportEvent {
  const RouteSupportRefreshed();
}

/// Driver posted a follow-up from the composer.
class RouteSupportMessageSent extends RouteSupportEvent {
  final String text;

  const RouteSupportMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

/// Driver accepted a dispatcher-recommended fuel stop, putting it on the
/// navigation route (§5).
class RouteSupportFuelConfirmed extends RouteSupportEvent {
  final String recommendationId;

  const RouteSupportFuelConfirmed(this.recommendationId);

  @override
  List<Object?> get props => [recommendationId];
}

/// Driver pressed Drive on an approved route - opens a navigation session for
/// it (§6).
class RouteSupportDrivePressed extends RouteSupportEvent {
  const RouteSupportDrivePressed();
}
