import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/trips/data/model/place_model.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/src/features/trips/data/source/trips_data_source.dart';
import 'package:taxi_app/src/features/trips/domain/repo/trips_repo.dart';

class TripsRepoImpl extends TripsRepo {
  final TripsDataSource dataSource;

  TripsRepoImpl({required this.dataSource});

  @override
  Future<NetworkResponse<TripPage>> fetchPage({
    int page = 1,
    int perPage = 20,
    String? status,
  }) {
    return dataSource.fetchPage(page: page, perPage: perPage, status: status);
  }

  @override
  Future<NetworkResponse<List<PlaceModel>>> searchPlaces(
    String query, {
    CancelToken? cancelToken,
  }) {
    return dataSource.searchPlaces(query, cancelToken: cancelToken);
  }
}
