import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/map_entity.dart';
import 'package:mechanic/features/main/domain/entities/selected_order_entity.dart';

part 'selected_order_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SelectedOrderModel extends SelectedOrderEntity {
  const SelectedOrderModel({
    super.orderId,
    super.orderTitle,
    super.orderAddress,
    super.orderPrice,
    super.proposalPrice,
    super.acceptedTime,
    super.mechanicLat,
    super.map,
  });

  factory SelectedOrderModel.fromJson(Map<String, dynamic> json) => _$SelectedOrderModelFromJson(json);
}
