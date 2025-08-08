// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDetailModel _$OrderDetailModelFromJson(Map<String, dynamic> json) =>
    OrderDetailModel(
      order: json['order'] == null
          ? const OrderEntity()
          : const OrderEntityConverter()
              .fromJson(json['order'] as Map<String, dynamic>),
      yourProposal: json['your_proposal'] == null
          ? const ProposalEntity()
          : const ProposalEntityConverter()
              .fromJson(json['your_proposal'] as Map<String, dynamic>),
      proposals: (json['proposals'] as List<dynamic>?)
              ?.map((e) => const ProposalEntityConverter()
                  .fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$OrderDetailModelToJson(OrderDetailModel instance) =>
    <String, dynamic>{
      'order': const OrderEntityConverter().toJson(instance.order),
      'your_proposal':
          const ProposalEntityConverter().toJson(instance.yourProposal),
      'proposals': instance.proposals
          .map(const ProposalEntityConverter().toJson)
          .toList(),
    };
