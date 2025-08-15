import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/lat_lng_entity.dart';
import 'package:mechanic/features/main/domain/entities/map_entity.dart';

part 'map_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MapModel extends MapEntity {
  const MapModel({
    super.distanceKm,
    super.durationMin,
    super.startPoint,
    super.endPoint,
    super.route,
  });

  factory MapModel.fromJson(Map<String, dynamic> json) => _$MapModelFromJson(json);
}
