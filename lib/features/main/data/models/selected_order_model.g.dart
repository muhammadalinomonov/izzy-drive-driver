// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SelectedOrderModel _$SelectedOrderModelFromJson(Map<String, dynamic> json) =>
    SelectedOrderModel(
      orderId: (json['order_id'] as num?)?.toInt() ?? -1,
      orderTitle: json['order_title'] as String? ?? '',
      orderAddress: json['order_address'] as String? ?? '',
      orderPrice: (json['order_price'] as num?)?.toDouble() ?? 0.0,
      proposalPrice: (json['proposal_price'] as num?)?.toDouble() ?? 0.0,
      acceptedTime: (json['accepted_time'] as num?)?.toInt() ?? 0,
      mechanicLat: (json['mechanic_lat'] as num?)?.toDouble() ?? 0.0,
      map: json['map'] == null
          ? const MapEntity()
          : const MapEntityConverter()
              .fromJson(json['map'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SelectedOrderModelToJson(SelectedOrderModel instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'order_title': instance.orderTitle,
      'order_address': instance.orderAddress,
      'order_price': instance.orderPrice,
      'proposal_price': instance.proposalPrice,
      'accepted_time': instance.acceptedTime,
      'mechanic_lat': instance.mechanicLat,
      'map': const MapEntityConverter().toJson(instance.map),
    };
