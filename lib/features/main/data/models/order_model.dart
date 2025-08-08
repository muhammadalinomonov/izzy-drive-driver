import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/image_entity.dart';
import 'package:mechanic/features/main/domain/entities/order_entity.dart';
import 'package:mechanic/features/main/domain/entities/proposal_entity.dart';

part 'order_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderModel extends OrderEntity {
  const OrderModel({
    super.id,
    super.orderTitle,
    super.price,
    super.status,
    super.selectedMechanic,
    super.proposal,
    super.createdAt,
    super.distanceKm,
    super.description,
    super.audio,
    super.images,
    super.distance,

  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}
