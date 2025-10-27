import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PointEntity {
  final double lat;
  final double lng;

  const PointEntity({this.lat = 0, this.lng = 0});

  factory PointEntity.fromJson(Map<String, dynamic> json) {
    return PointEntity(lat: json['lat']??0, lng: json['lng']??0);
  }


  Point toPoint() => Point(coordinates: Position(lng, lat));
}
