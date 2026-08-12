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
///
/// [startRouting] additionally prices the trip right away, which is what the
/// information sheet's action button does - the driver has already stated where
/// they want to go, so making them press Continue as well is a dead step.
class TripMapFuelStationSelected extends TripMapEvent {
  final FuelStationModel station;
  final bool startRouting;

  const TripMapFuelStationSelected(this.station, {this.startRouting = false});

  @override
  List<Object?> get props => [station.id, startRouting];
}

/// The "my location" control was pressed: take a fresh GPS fix and move the
/// camera to it.
class TripMapRecenterRequested extends TripMapEvent {
  const TripMapRecenterRequested();
}

/// A marker was tapped but not yet acted on - highlights it while its
/// information sheet is open. An empty id clears the highlight.
class TripMapMarkerHighlighted extends TripMapEvent {
  final String stationId;

  const TripMapMarkerHighlighted(this.stationId);

  @override
  List<Object?> get props => [stationId];
}
