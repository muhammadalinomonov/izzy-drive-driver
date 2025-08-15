// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sub_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubOrderModel _$SubOrderModelFromJson(Map<String, dynamic> json) =>
    SubOrderModel(
      id: (json['id'] as num?)?.toInt() ?? -1,
      title: json['title'] as String? ?? '',
      price: json['price'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );

Map<String, dynamic> _$SubOrderModelToJson(SubOrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'created_at': instance.createdAt,
      'price': instance.price,
      'status': instance.status,
    };
