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
      status: json['status'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => LocationData.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
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
      formatted: json['formatted'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}