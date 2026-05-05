import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/sub_order_entity.dart';

class SubOrderModel extends SubOrderEntity {
  const SubOrderModel({super.id, super.title, super.status, super.createdAt, super.price});

  factory SubOrderModel.fromJson(Map<String, dynamic> json) {
    return SubOrderModel(
      id: toInt(json['id'], -1),
      title: toStr(json['title']),
      status: toStr(json['status']),
      createdAt: toStr(json['created_at']),
      price: toStr(json['price']),
    );
  }
}
