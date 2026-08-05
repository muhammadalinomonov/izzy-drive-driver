part of 'route_support_bloc.dart';

abstract class RouteSupportEvent extends Equatable {
  const RouteSupportEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the thread for the route the page was opened with. Also the retry.
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
