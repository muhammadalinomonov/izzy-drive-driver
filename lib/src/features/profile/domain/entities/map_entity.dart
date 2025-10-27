import 'package:equatable/equatable.dart';
import 'package:taxi_app/src/features/profile/domain/entities/point_entity.dart';

class MapEntity extends Equatable {
  final List<PointEntity> route;
  final PointEntity endPoint;
  final PointEntity startPoint;
  final double distanceKm;
  final double durationMin;

  const MapEntity({
    this.route = const [],
    this.startPoint = const PointEntity(),
    this.endPoint = const PointEntity(),
    this.distanceKm = 0,
    this.durationMin = 0,
  });

  factory MapEntity.fromJson(Map<String, dynamic> json) {
    return MapEntity(
      route: ((json['route'] ?? [])as List<dynamic>).map((e) => PointEntity.fromJson(e)).toList(),
      startPoint: PointEntity.fromJson(json['start_point'] ?? {}),
      endPoint: PointEntity.fromJson(json['end_point'] ?? {}),
      distanceKm: json['distance_km'] ?? 0,
      durationMin: json['duration_min'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [route, startPoint, endPoint, distanceKm, durationMin];
}
