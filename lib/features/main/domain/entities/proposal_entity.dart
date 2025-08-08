import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/data/models/proposal_model.dart';

class ProposalEntity extends Equatable {
  final int id;
  final int orderId;
  final String proposedPrice;
  final String comment;
  final bool isArchived;
  final String createdAt;
  final double price;
  final String balance;
  final double changePercent;

  const ProposalEntity({
    this.id = -1,
    this.orderId = -1,
    this.proposedPrice = '',
    this.comment = '',
    this.isArchived = false,
    this.createdAt = '',
    this.price = 0.0,
    this.balance = '',
    this.changePercent = 0.0,
  });
  
  @override
  List<Object?> get props => [
        id,
        orderId,
        proposedPrice,
        comment,
        isArchived,
        createdAt,
        price,
        balance,
        changePercent,
      ];
}
class ProposalEntityConverter implements JsonConverter<ProposalEntity, Map<String, dynamic>> {
  const ProposalEntityConverter();

  @override
  ProposalEntity fromJson(Map<String, dynamic> json) {
    return ProposalModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(ProposalEntity entity) {
    return {
      'id': entity.id,
      'order_id': entity.orderId,
      'proposed_price': entity.proposedPrice,
      'comment': entity.comment,
      'is_archived': entity.isArchived,
      'created_at': entity.createdAt,
      'price': entity.price,
      'balance': entity.balance,
      'change_percent': entity.changePercent,
    };
  }
}
