import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/order_history_entity.dart';

part 'order_history_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderHistoryModel extends OrderHistoryEntity {
  const OrderHistoryModel({
    super.id,
    super.orderTitle,
    super.orderPrice,
    super.address,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$OrderHistoryModelFromJson(json);
}
