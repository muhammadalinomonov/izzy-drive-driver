import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/data/models/current_address_model.dart';

class CurrentAddressEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String address;
  final bool isStatic;

  const CurrentAddressEntity({
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.address = '',
    this.isStatic = false,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        address,
        isStatic,
      ];
}

class CurrentAddressEntityConverter implements JsonConverter<CurrentAddressEntity, Map<String, dynamic>> {
  const CurrentAddressEntityConverter();

  @override
  CurrentAddressEntity fromJson(Map<String, dynamic> json) {
    return CurrentAddressModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(CurrentAddressEntity entity) {
    return {
      'latitude': entity.latitude,
      'longitude': entity.longitude,
      'address': entity.address,
      'is_static': entity.isStatic,
    };
  }
}
