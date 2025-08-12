import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/address_entity.dart';
import 'package:mechanic/features/main/domain/entities/current_order_entity.dart';

part 'current_order_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CurrentOrderModel extends CurrentOrderEntity {
  const CurrentOrderModel({
    super.id,
    super.status,
    super.orderTitle,
    super.currentAddress,
    super.price,
    super.acceptedAt,
    super.driverName,
    super.driverPhone,
    super.driverAvatar,
    super.paymentStatus,
    super.totalPrice,
    super.suborders,
  });

  factory CurrentOrderModel.fromJson(Map<String, dynamic> json) => _$CurrentOrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentOrderModelToJson(this);
}
