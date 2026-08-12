import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/fuel_station_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// Nearby fuel stations, backed by `GET mobile/fuel-stations` (docs §7.1).
abstract class FuelStationsRepo {
  /// Stations within [radiusMeters] of [currentLocation], nearest first, with
  /// [FuelStationModel.distanceMeters] measured locally - the catalogue is a
  /// bounding-box query and returns no distance of its own.
  ///
  /// An empty list is a valid answer (no stations in range), not an error.
  Future<NetworkResponse<List<FuelStationModel>>> getNearbyFuelStations({
    required TripCoordinate currentLocation,
    required double radiusMeters,
  });
}
