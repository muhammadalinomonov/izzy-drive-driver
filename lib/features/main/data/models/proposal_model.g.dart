// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProposalModel _$ProposalModelFromJson(Map<String, dynamic> json) =>
    ProposalModel(
      id: (json['id'] as num?)?.toInt() ?? -1,
      orderId: (json['order_id'] as num?)?.toInt() ?? -1,
      proposedPrice: json['proposed_price'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      balance: json['balance'] as String? ?? '',
      changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$ProposalModelToJson(ProposalModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'proposed_price': instance.proposedPrice,
      'comment': instance.comment,
      'is_archived': instance.isArchived,
      'created_at': instance.createdAt,
      'price': instance.price,
      'balance': instance.balance,
      'change_percent': instance.changePercent,
    };
