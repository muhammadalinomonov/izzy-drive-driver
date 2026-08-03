part of 'trip_map_bloc.dart';

sealed class TripMapEvent extends Equatable {
  const TripMapEvent();

  @override
  List<Object?> get props => [];
}

/// Page opened: load recents and resolve the driver's GPS origin.
class TripMapStarted extends TripMapEvent {
  const TripMapStarted();
}

class TripMapFieldFocused extends TripMapEvent {
  final TripMapField field;

  const TripMapFieldFocused(this.field);

  @override
  List<Object?> get props => [field];
}

/// Raw keystrokes. The bloc debounces these into [TripMapSearchRequested].
class TripMapQueryChanged extends TripMapEvent {
  final String query;

  const TripMapQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Fired by the debounce timer - not by the UI.
class TripMapSearchRequested extends TripMapEvent {
  final String query;

  const TripMapSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

/// A suggestion or history row was tapped. [field] targets a specific field;
/// when null the currently active one is used.
class TripMapPlaceSelected extends TripMapEvent {
  final PlaceModel place;
  final TripMapField? field;

  const TripMapPlaceSelected(this.place, {this.field});

  @override
  List<Object?> get props => [place, field];
}

/// Keyboard dismissed / search cancelled without picking anything.
class TripMapSearchDismissed extends TripMapEvent {
  const TripMapSearchDismissed();
}

/// "Continue" tapped with both locations selected - prices the trip via
/// `POST /toll-routes`.
class TripMapContinuePressed extends TripMapEvent {
  const TripMapContinuePressed();
}

/// The Gas Station button was tapped. Toggles "Nearby Fuel Stations" mode:
/// entering it loads stations around the driver, leaving it clears them.
class TripMapGasStationModeToggled extends TripMapEvent {
  const TripMapGasStationModeToggled();
}

/// Retry for a failed nearby-stations load, without leaving the mode.
class TripMapFuelStationsRequested extends TripMapEvent {
  const TripMapFuelStationsRequested();
}

/// A station marker (or list row) was tapped. The bloc sets the driver's
/// current location as origin and the station as destination, so Continue
/// becomes available without any manual search.
class TripMapFuelStationSelected extends TripMapEvent {
  final FuelStationModel station;

  const TripMapFuelStationSelected(this.station);

  @override
  List<Object?> get props => [station.id];
}
