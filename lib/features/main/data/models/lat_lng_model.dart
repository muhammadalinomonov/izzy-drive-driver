import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/lat_lng_entity.dart';

part 'lat_lng_model.g.dart';
@JsonSerializable(fieldRename: FieldRename.snake)
class LatLngModel extends LatLngEntity{
  const LatLngModel({
     super.lat,
     super.lng,
  });

  factory LatLngModel.fromJson(Map<String, dynamic> json) => _$LatLngModelFromJson(json);

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}