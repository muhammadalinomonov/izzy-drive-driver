// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_time_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkTimeModel _$WorkTimeModelFromJson(Map<String, dynamic> json) =>
    WorkTimeModel(
      days: (json['days'] as num?)?.toInt() ?? 0,
      hours: (json['hours'] as num?)?.toInt() ?? 0,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WorkTimeModelToJson(WorkTimeModel instance) =>
    <String, dynamic>{
      'days': instance.days,
      'hours': instance.hours,
      'minutes': instance.minutes,
    };
