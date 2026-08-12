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

/// Driver posted a follow-up from the composer.
class RouteSupportMessageSent extends RouteSupportEvent {
  final String text;

  const RouteSupportMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}
