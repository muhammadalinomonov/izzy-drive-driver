// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: (json['id'] as num?)?.toInt() ?? -1,
      phoneNumber: json['phone_number'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      balance: json['balance'] as String? ?? '',
      deviceToken: json['device_token'] as String? ?? '',
      wsId: (json['ws_id'] as num?)?.toInt() ?? -1,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'phone_number': instance.phoneNumber,
      'status': instance.status,
      'photo': instance.photo,
      'balance': instance.balance,
      'device_token': instance.deviceToken,
      'ws_id': instance.wsId,
    };
