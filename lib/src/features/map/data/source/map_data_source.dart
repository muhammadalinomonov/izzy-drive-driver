import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/service_locater.dart';

import '../../../../core/network/dio_model.dart';
import '../model/nearby_masters_response.dart';
import '../model/search_locations_response.dart'; // Ensure this import exists

class MapDataSource {
  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> getNearbyMechanics({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await client.get(
        ApiConstants.nearMechanicsKm,
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
        },
      );

      if (response.isSuccess) {
        final model = NearbyMastersResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        return NetworkResponse(data: model);
      } else {
        return NetworkResponse(errorText: response.statusMessage ?? '');
      }
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse> getNearbyLocations({
    required double latitude,
    required double longitude,
    String? query, // Optional query parameter (e.g., "Fargona")
  }) async {
    try {
      final response = await client.get(
        ApiConstants.searchLocation,
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          if (query != null) 'q': query, // Include 'q' only if provided
        },
      );

      if (response.isSuccess) {
        final model = NearbyLocationsResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        return NetworkResponse(data: model);
      } else {
        return NetworkResponse(errorText: response.statusMessage ?? '');
      }
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }
}
