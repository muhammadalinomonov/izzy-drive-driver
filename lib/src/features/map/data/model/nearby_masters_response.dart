import 'package:taxi_app/src/core/utils/json_safe.dart';

class NearbyMastersResponse {
  final bool status;
  final String message;
  final NearbyMastersData data;

  NearbyMastersResponse({required this.status, required this.message, required this.data});

  factory NearbyMastersResponse.fromJson(Map<String, dynamic> json) {
    return NearbyMastersResponse(
      status: toBool(json['status']),
      message: toStr(json['message']),
      data: NearbyMastersData.fromJson(toMap(json['data'])),
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
      driverCurrentAddress: DriverCurrentAddress.fromJson(toMap(json['driver_current_address'])),
      mechanics: toList(json['mechanics'], (e) => Mechanic.fromJson(toMap(e))),
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
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      address: toStr(json['address']),
    );
  }

  factory DriverCurrentAddress.fromSearchApiJson(Map<String, dynamic> json) {
    return DriverCurrentAddress(
      latitude: toDouble(json['lat']),
      longitude: toDouble(json['lon']),
      address: toStr(json['formatted']),
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
      id: toInt(json['id']),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      distance: toDouble(json['distance']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'latitude': latitude, 'longitude': longitude, 'distance': distance};
}