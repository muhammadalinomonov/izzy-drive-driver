// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_otp_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestOtpModel _$RequestOtpModelFromJson(Map<String, dynamic> json) =>
    RequestOtpModel(
      email: json['email'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      resendAfter: (json['resend_after'] as num).toInt(),
    );

Map<String, dynamic> _$RequestOtpModelToJson(RequestOtpModel instance) =>
    <String, dynamic>{
      'email': instance.email,
      'expires_in': instance.expiresIn,
      'resend_after': instance.resendAfter,
    };
