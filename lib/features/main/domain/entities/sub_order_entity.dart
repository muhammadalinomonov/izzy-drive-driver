import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/data/models/sub_order_model.dart';

class SubOrderEntity extends Equatable{
  final int id;
  final String title;
  final String createdAt;
  final String price;
  final String status;

  const SubOrderEntity({
    this.id = -1,
    this.title = '',
    this.createdAt = '',
    this.price = '',
    this.status = '',
  });

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        price,
        status,
      ];
}

class SubOrderEntityConverter implements JsonConverter<SubOrderEntity, Map<String, dynamic>> {
  const SubOrderEntityConverter();

  @override
  SubOrderEntity fromJson(Map<String, dynamic> json) {
    return SubOrderModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(SubOrderEntity entity) {
    return {
      'id': entity.id,
      'title': entity.title,
      'created_at': entity.createdAt,
      'price': entity.price,
      'status': entity.status,
    };
  }
}