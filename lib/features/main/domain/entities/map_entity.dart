import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/data/models/map_model.dart';
import 'package:mechanic/features/main/domain/entities/lat_lng_entity.dart';

class MapEntity extends Equatable {
  final double distanceKm;
  final double durationMin;
  @LatLngEntityConverter()
  final LatLngEntity startPoint;
  @LatLngEntityConverter()
  final LatLngEntity endPoint;
  @LatLngEntityConverter()
  final List<LatLngEntity> route;

  const MapEntity({
    this.distanceKm = 0,
    this.durationMin = 0,
    this.startPoint = const LatLngEntity(),
    this.endPoint = const LatLngEntity(),
    this.route = const [],
  });

  @override
  List<Object?> get props => [
        distanceKm,
        durationMin,
        startPoint,
        endPoint,
        route,
      ];
}

class MapEntityConverter implements JsonConverter<MapEntity, Map<String, dynamic>> {
  const MapEntityConverter();

  @override
  MapEntity fromJson(Map<String, dynamic> json) {
    return MapModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(MapEntity entity) {
    return {
      'distance_km': entity.distanceKm,
      'duration_min': entity.durationMin,
      'start_point': LatLngEntityConverter().toJson(entity.startPoint),
      'end_point': LatLngEntityConverter().toJson(entity.endPoint),
      'route': entity.route.map((e) => LatLngEntityConverter().toJson(e)).toList(),
    };
  }
}
