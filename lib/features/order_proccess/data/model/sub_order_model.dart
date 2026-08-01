import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/order_proccess/domain/entities/sub_order_entity.dart';

class SubOrderModel extends SubOrderEntity {
  const SubOrderModel({super.id, super.title, super.status, super.createdAt, super.price});

  factory SubOrderModel.fromJson(Map<String, dynamic> json) {
    // Backend ikki xil shaklda id qaytaradi:
    //  - REST `current_order` orqali SubOrderSerializer → `id`
    //  - WS `new-suborder` event → `suborder_id`
    // Birinchi mavjudini olamiz, ikkalasi yo'q bo'lsa -1.
    final rawId = json['id'] ?? json['suborder_id'];
    return SubOrderModel(
      id: toInt(rawId, -1),
      title: toStr(json['title']),
      status: toStr(json['status']),
      createdAt: toStr(json['created_at']),
      price: toStr(json['price']),
    );
  }
}
