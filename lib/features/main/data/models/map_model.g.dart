// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MapModel _$MapModelFromJson(Map<String, dynamic> json) => MapModel(
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      durationMin: (json['duration_min'] as num?)?.toDouble() ?? 0,
      startPoint: json['start_point'] == null
          ? const LatLngEntity()
          : const LatLngEntityConverter().fromJson(json['start_point'] as Map<String, dynamic>),
      endPoint: json['end_point'] == null
          ? const LatLngEntity()
          : const LatLngEntityConverter().fromJson(json['end_point'] as Map<String, dynamic>),
      route: (json['route'] as List<dynamic>?)
              ?.map((e) => const LatLngEntityConverter().fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MapModelToJson(MapModel instance) => <String, dynamic>{
      'distance_km': instance.distanceKm,
      'duration_min': instance.durationMin,
      'start_point': const LatLngEntityConverter().toJson(instance.startPoint),
      'end_point': const LatLngEntityConverter().toJson(instance.endPoint),
      'route': instance.route.map(const LatLngEntityConverter().toJson).toList(),
    };
