import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/proposal_entity.dart';

part 'proposal_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProposalModel extends ProposalEntity {
  const ProposalModel({
    super.id,
    super.orderId,
    super.proposedPrice,
    super.comment,
    super.isArchived,
    super.createdAt,
    super.price,
    super.balance,
    super.changePercent,
  });

  factory ProposalModel.fromJson(Map<String, dynamic> json) => _$ProposalModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProposalModelToJson(this);
}
