part of 'map_bloc.dart';

@immutable
sealed class MapEvent {}

class FetchNearbyMechanicsEvent extends MapEvent {
  final double latitude;
  final double longitude;

  FetchNearbyMechanicsEvent({
    required this.latitude,
    required this.longitude,
  });
}

class FetchNearbyLocationsEvent extends MapEvent {
  final double latitude;
  final double longitude;
  final String? query;

  FetchNearbyLocationsEvent({
    required this.latitude,
    required this.longitude,
    this.query,
  });
}

class PickerModeChangedEvent extends MapEvent {
  final PickerMode mode;
  PickerModeChangedEvent(this.mode);
}

/// Final selection - used by LocationPickerScreen on "Davom ettirish" /
/// "Tanlash" CTA. State carries the chosen address+coords; the screen
/// then pops or pushes the next route with extras.
class LocationSelectedEvent extends MapEvent {
  final String address;
  final double latitude;
  final double longitude;

  LocationSelectedEvent({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
