import 'package:taxi_app/core/network/network_response.dart';

abstract class MapRepo{
  Future<NetworkResponse> getNearbyMechanics({required double latitude, required double longitude});
  Future<NetworkResponse> getNearbyLocations({
    required double latitude,
    required double longitude,
    String? query, // Optional query parameter (e.g., "Fargona")
  });
}