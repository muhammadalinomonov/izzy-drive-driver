import 'package:taxi_app/src/features/order_proccess/domain/entities/sub_order_entity.dart';

class SubOrderModel extends SubOrderEntity {
  const SubOrderModel({super.id, super.title, super.status, super.createdAt, super.price});

  factory SubOrderModel.fromJson(Map<String, dynamic> json) {
    return SubOrderModel(
      id: json['id'] as int? ?? -1,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      price: json['price'] as String? ?? '',
    );
  }
}
