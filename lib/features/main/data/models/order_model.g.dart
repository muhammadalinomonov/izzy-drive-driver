// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
      id: (json['id'] as num?)?.toInt() ?? -1,
      orderTitle: json['order_title'] as String? ?? '',
      price: json['price'] as String? ?? '',
      status: json['status'] as String? ?? '',
      selectedMechanic: json['selected_mechanic'],
      proposal: json['proposal'] == null
          ? const ProposalEntity()
          : const ProposalEntityConverter()
              .fromJson(json['proposal'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String? ?? '',
      distanceKm: json['distance_km'] as String? ?? '',
      description: json['description'] as String? ?? '',
      audio: json['audio'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => const ImageEntityConverter()
                  .fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      distance: json['distance'] as String? ?? '',
    );

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_title': instance.orderTitle,
      'price': instance.price,
      'status': instance.status,
      'selected_mechanic': instance.selectedMechanic,
      'proposal': const ProposalEntityConverter().toJson(instance.proposal),
      'created_at': instance.createdAt,
      'distance_km': instance.distanceKm,
      'description': instance.description,
      'audio': instance.audio,
      'images':
          instance.images.map(const ImageEntityConverter().toJson).toList(),
      'distance': instance.distance,
    };
