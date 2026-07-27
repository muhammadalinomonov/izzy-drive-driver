import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/trips/data/model/place_model.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';

abstract class TripsRepo {
  Future<NetworkResponse<TripPage>> fetchPage({
    int page,
    int perPage,
    String? status,
  });

  Future<NetworkResponse<List<PlaceModel>>> searchPlaces(
    String query, {
    CancelToken? cancelToken,
  });
}
