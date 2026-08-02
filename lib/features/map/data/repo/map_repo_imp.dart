// src/features/mechanics/data/repo/mechanics_repo_impl.dart

import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/map/data/source/map_data_source.dart';

import '../../domain/map_repo.dart';

@LazySingleton(as: MapRepo)
class MapRepoImpl extends MapRepo {
  final MapDataSource dataSource;

  MapRepoImpl({required this.dataSource});

  @override
  Future<NetworkResponse> getNearbyMechanics({
    required double latitude,
    required double longitude,
  })  {
    return  dataSource.getNearbyMechanics(
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<NetworkResponse> getNearbyLocations({required double latitude, required double longitude, String? query}) {
    return dataSource.getNearbyLocations(
      latitude: latitude,
      longitude: longitude,
      query: query,
    );
  }
}
