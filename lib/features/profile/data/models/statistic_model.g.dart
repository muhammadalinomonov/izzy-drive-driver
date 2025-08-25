// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatisticModel _$StatisticModelFromJson(Map<String, dynamic> json) =>
    StatisticModel(
      date: json['date'] as String? ?? '',
      dateStr: json['date_str'] as String? ?? '',
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      totalSum: (json['total_sum'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      selected: json['selected'] as bool? ?? false,
    );

Map<String, dynamic> _$StatisticModelToJson(StatisticModel instance) =>
    <String, dynamic>{
      'date': instance.date,
      'date_str': instance.dateStr,
      'orders_count': instance.ordersCount,
      'total_sum': instance.totalSum,
      'percentage': instance.percentage,
      'selected': instance.selected,
    };
