
import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/order_detail_entity.dart';
import 'package:mechanic/features/main/domain/entities/order_entity.dart';
import 'package:mechanic/features/main/domain/entities/proposal_entity.dart';

part 'order_detail_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderDetailModel extends OrderDetailEntity{
  const OrderDetailModel({
    super.order,
    super.yourProposal,
    super.proposals,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) => _$OrderDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDetailModelToJson(this);
}