import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/order_history_entity.dart';
import 'package:mechanic/features/main/domain/entities/order_with_date_entity.dart';

part 'orders_with_date_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrdersWithDateModel extends OrdersWithDataEntity{
  const OrdersWithDateModel({
    super.date,
    super.orders,
  });

  factory OrdersWithDateModel.fromJson(Map<String, dynamic> json) =>
      _$OrdersWithDateModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrdersWithDateModelToJson(this);
}