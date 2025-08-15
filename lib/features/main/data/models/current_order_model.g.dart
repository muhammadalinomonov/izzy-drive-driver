// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentOrderModel _$CurrentOrderModelFromJson(Map<String, dynamic> json) =>
    CurrentOrderModel(
      id: (json['id'] as num?)?.toInt() ?? -1,
      status: json['status'] as String? ?? '',
      orderTitle: json['order_title'] as String? ?? '',
      currentAddress: json['current_address'] == null
          ? const CurrentAddressEntity()
          : const CurrentAddressEntityConverter()
              .fromJson(json['current_address'] as Map<String, dynamic>),
      price: json['price'] as String? ?? '',
      acceptedAt: json['accepted_at'] as String? ?? '',
      driverName: json['driver_name'] as String? ?? '',
      driverPhone: json['driver_phone'] as String? ?? '',
      driverAvatar: json['driver_avatar'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? '',
      totalPrice: json['total_price'] as String? ?? '',
      suborders: (json['suborders'] as List<dynamic>?)
              ?.map((e) => const SubOrderEntityConverter()
                  .fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CurrentOrderModelToJson(CurrentOrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'order_title': instance.orderTitle,
      'current_address':
          const CurrentAddressEntityConverter().toJson(instance.currentAddress),
      'price': instance.price,
      'accepted_at': instance.acceptedAt,
      'driver_name': instance.driverName,
      'driver_phone': instance.driverPhone,
      'driver_avatar': instance.driverAvatar,
      'payment_status': instance.paymentStatus,
      'total_price': instance.totalPrice,
      'suborders': instance.suborders
          .map(const SubOrderEntityConverter().toJson)
          .toList(),
    };
