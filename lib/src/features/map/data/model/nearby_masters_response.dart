class NearbyMastersResponse {
  final bool status;
  final String message;
  final NearbyMastersData data;

  NearbyMastersResponse({required this.status, required this.message, required this.data});

  factory NearbyMastersResponse.fromJson(Map<String, dynamic> json) {
    return NearbyMastersResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: NearbyMastersData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {'status': status, 'message': message, 'data': data.toJson()};
}

class NearbyMastersData {
  final DriverCurrentAddress driverCurrentAddress;
  final List<Mechanic> mechanics;

  NearbyMastersData({required this.driverCurrentAddress, required this.mechanics});

  factory NearbyMastersData.fromJson(Map<String, dynamic> json) {
    return NearbyMastersData(
      driverCurrentAddress: DriverCurrentAddress.fromJson(json['driver_current_address'] as Map<String, dynamic>),
      mechanics: (json['mechanics'] as List<dynamic>).map((e) => Mechanic.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'driver_current_address': driverCurrentAddress.toJson(),
    'mechanics': mechanics.map((e) => e.toJson()).toList(),
  };
}

class DriverCurrentAddress {
  final double latitude;
  final double longitude;
  final String address;

  DriverCurrentAddress({required this.latitude, required this.longitude, required this.address});

  factory DriverCurrentAddress.fromJson(Map<String, dynamic> json) {
    return DriverCurrentAddress(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
    );
  }

  factory DriverCurrentAddress.fromSearchApiJson(Map<String, dynamic> json) {
    return DriverCurrentAddress(
      latitude: (json['lat'] as num?)?.toDouble() ?? 0,
      longitude: (json['lon'] as num?)?.toDouble() ?? 0,
      address: json['formatted'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude, 'address': address};
}

class Mechanic {
  final int id;
  final double latitude;
  final double longitude;
  final double distance;

  Mechanic({required this.id, required this.latitude, required this.longitude, required this.distance});

  factory Mechanic.fromJson(Map<String, dynamic> json) {
    return Mechanic(
      id: json['id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'latitude': latitude, 'longitude': longitude, 'distance': distance};
}
