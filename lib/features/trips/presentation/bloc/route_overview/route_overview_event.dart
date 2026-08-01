part of 'route_overview_bloc.dart';

sealed class RouteOverviewEvent extends Equatable {
  const RouteOverviewEvent();

  @override
  List<Object?> get props => [];
}

/// Page opened (and the retry button). Only does work when the route arrived
/// without its endpoint labels - i.e. from the history list, where the tap
/// navigates immediately and the full detail is fetched here. Carries the
/// fallback labels so the localization stays in the UI layer.
class RouteOverviewStarted extends RouteOverviewEvent {
  final String originFallbackLabel;
  final String destinationFallbackLabel;

  const RouteOverviewStarted({
    required this.originFallbackLabel,
    required this.destinationFallbackLabel,
  });

  @override
  List<Object?> get props => [originFallbackLabel, destinationFallbackLabel];
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
