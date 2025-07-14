part of 'map_bloc.dart';

@immutable
sealed class MapState {
  const MapState();
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapSuccess extends MapState {
  final NearbyMastersResponse nearbyMechanics;

  const MapSuccess({required this.nearbyMechanics});
}

class LocationsSuccess extends MapState {
  final NearbyLocationsResponse nearbyLocations;

  const LocationsSuccess({required this.nearbyLocations});
}

class MapFailure extends MapState {
  final String errorMessage;

  const MapFailure({required this.errorMessage});
}