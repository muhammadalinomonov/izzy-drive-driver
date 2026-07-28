part of 'route_overview_bloc.dart';

sealed class RouteOverviewEvent extends Equatable {
  const RouteOverviewEvent();

  @override
  List<Object?> get props => [];
}

/// A tab in the alternatives row was tapped - purely local, all alternatives
/// already arrived in the `POST /toll-routes` response that created [trip].
class RouteOverviewAlternativeSelected extends RouteOverviewEvent {
  final String alternativeId;

  const RouteOverviewAlternativeSelected(this.alternativeId);

  @override
  List<Object?> get props => [alternativeId];
}

/// "Start" tapped: creates/refreshes the navigation session for the selected
/// alternative.
class RouteOverviewStartPressed extends RouteOverviewEvent {
  const RouteOverviewStartPressed();
}
