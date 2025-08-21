// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderHistoryModel _$OrderHistoryModelFromJson(Map<String, dynamic> json) =>
    OrderHistoryModel(
      id: (json['id'] as num?)?.toInt() ?? -1,
      orderTitle: json['order_title'] as String? ?? '',
      orderPrice: (json['order_price'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
    );

Map<String, dynamic> _$OrderHistoryModelToJson(OrderHistoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_title': instance.orderTitle,
      'order_price': instance.orderPrice,
      'address': instance.address,
    };
