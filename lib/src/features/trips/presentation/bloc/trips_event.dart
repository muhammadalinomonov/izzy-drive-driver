part of 'trips_bloc.dart';

sealed class TripsEvent extends Equatable {
  const TripsEvent();

  @override
  List<Object?> get props => [];
}

class TripsLoaded extends TripsEvent {
  const TripsLoaded();
}

class TripsRefreshed extends TripsEvent {
  const TripsRefreshed();
}

class TripsLoadMore extends TripsEvent {
  const TripsLoadMore();
}

/// Re-checks `GET navigation-sessions/current` so the Continue Route card
/// appears or disappears. Fired on open, on refresh, and whenever Driving Mode
/// pops back - a trip completed or cancelled there must clear the card.
class TripsActiveSessionChecked extends TripsEvent {
  const TripsActiveSessionChecked();
}
