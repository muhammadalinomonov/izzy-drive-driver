import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/fuel_station_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/features/trips/data/source/fuel_stations_data_source.dart';
import 'package:taxi_app/features/trips/domain/repo/fuel_stations_repo.dart';

class FuelStationsRepoImpl extends FuelStationsRepo {
  final FuelStationsDataSource dataSource;

  FuelStationsRepoImpl({required this.dataSource});

  @override
  Future<NetworkResponse<List<FuelStationModel>>> getNearbyFuelStations({
    required TripCoordinate currentLocation,
    required double radiusMeters,
  }) {
    return dataSource.getNearbyFuelStations(
      currentLocation: currentLocation,
      radiusMeters: radiusMeters,
    );
  }
}
