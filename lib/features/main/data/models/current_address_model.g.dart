// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_address_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentAddressModel _$CurrentAddressModelFromJson(Map<String, dynamic> json) =>
    CurrentAddressModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      isStatic: json['is_static'] as bool? ?? false,
    );

Map<String, dynamic> _$CurrentAddressModelToJson(
        CurrentAddressModel instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'is_static': instance.isStatic,
    };
