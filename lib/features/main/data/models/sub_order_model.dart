import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/sub_order_entity.dart';

part 'sub_order_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SubOrderModel extends SubOrderEntity {
  const SubOrderModel({
    super.id,
    super.title,
    super.price,
    super.status,
    super.createdAt,
  });

  factory SubOrderModel.fromJson(Map<String, dynamic> json) => _$SubOrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$SubOrderModelToJson(this);
}
