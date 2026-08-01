import 'package:taxi_app/core/utils/json_safe.dart';

class NearbyLocationsResponse {
  final bool status;
  final String message;
  final List<LocationData> data;

  NearbyLocationsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory NearbyLocationsResponse.fromJson(Map<String, dynamic> json) {
    return NearbyLocationsResponse(
      status: toBool(json['status']),
      message: toStr(json['message']),
      data: toList(json['data'], (e) => LocationData.fromJson(toMap(e))),
    );
  }
}

class LocationData {
  final String formatted;
  final double lat;
  final double lon;

  LocationData({
    required this.formatted,
    required this.lat,
    required this.lon,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      formatted: toStr(json['formatted']),
      lat: toDouble(json['lat']),
      lon: toDouble(json['lon']),
    );
  }
}