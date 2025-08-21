// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_with_date_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrdersWithDateModel _$OrdersWithDateModelFromJson(Map<String, dynamic> json) =>
    OrdersWithDateModel(
      date: json['date'] as String? ?? '',
      orders: (json['orders'] as List<dynamic>?)
              ?.map((e) => const OrderHistoryEntityConverter()
                  .fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$OrdersWithDateModelToJson(
        OrdersWithDateModel instance) =>
    <String, dynamic>{
      'date': instance.date,
      'orders': instance.orders
          .map(const OrderHistoryEntityConverter().toJson)
          .toList(),
    };
