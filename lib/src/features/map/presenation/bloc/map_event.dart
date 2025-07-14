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