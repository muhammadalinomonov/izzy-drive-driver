

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mechanic/features/main/data/models/lat_lng_model.dart';

class LatLngEntity extends Equatable {
  final double lat;
  final double lng;

  const LatLngEntity({
    this.lat = 0,
    this.lng = 0,
  });

  @override
  List<Object?> get props => [lat, lng];

  Point toPoint() => Point(coordinates: Position(lng, lat));
}

class LatLngEntityConverter implements JsonConverter<LatLngEntity, Map<String, dynamic>> {
  const LatLngEntityConverter();

  @override
  LatLngEntity fromJson(Map<String, dynamic> json) {
    return LatLngModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(LatLngEntity entity) {
    return {
      'lat': entity.lat,
      'lng': entity.lng,
    };
  }

}
