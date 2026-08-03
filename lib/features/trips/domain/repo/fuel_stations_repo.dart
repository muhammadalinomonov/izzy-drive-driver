import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/fuel_station_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// Nearby fuel stations.
///
/// The backing endpoint is not built yet; [FuelStationsRepoImpl] currently
/// serves generated data. This interface is the seam - when the API ships,
/// only the implementation changes.
abstract class FuelStationsRepo {
  /// Stations within [radiusMeters] of [currentLocation], nearest first.
  ///
  /// An empty list is a valid answer (no stations in range), not an error.
  Future<NetworkResponse<List<FuelStationModel>>> getNearbyFuelStations({
    required TripCoordinate currentLocation,
    required double radiusMeters,
  });
}
