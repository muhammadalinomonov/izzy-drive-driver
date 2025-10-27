import 'package:taxi_app/src/core/enums/order_enums.dart';
import 'package:taxi_app/src/features/chat/data/model/report_response.dart';
import 'package:taxi_app/src/features/order_proccess/data/model/sub_order_model.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/src/features/profile/data/model/profile_model.dart';
import 'package:taxi_app/src/features/profile/domain/entities/map_entity.dart';
import 'package:taxi_app/src/features/profile/domain/entities/work_time_entity.dart';

class CurrentOrderModel extends CurrentOrderEntity {
  const CurrentOrderModel({
    super.id,
    super.orderTitle,
    super.price,
    super.totalPrice,
    super.status,
    super.acceptedAt,
    super.completedAt,
    super.currentAddress,
    super.selectedMechanic,
    super.subOrders,
    super.createdAt,
    super.workTime,
    super.mechanicInfo,
    super.map,
  });

  factory CurrentOrderModel.fromJson(Map<String, dynamic> json) {
    return CurrentOrderModel(
      id: json['id'] as int? ?? -1,
      orderTitle: json['order_title'] as String? ?? '',
      price: json['price'] as String? ?? '',
      totalPrice: json['total_price'] as String? ?? '',
      status: OrderStatusConverter().fromJson(json['status'] as String? ?? 'pending'),
      acceptedAt: json['accepted_at'] as String? ?? '',
      completedAt: json['completed_at'] as String? ?? '',
      currentAddress: Address.fromJson(json['current_address'] ?? {}),
      selectedMechanic: ProfileModel.fromJson(json['selected_mechanic'] ?? {}),
      subOrders: (json['sub_orders'] as List<dynamic>?)?.map((e) => SubOrderModel.fromJson(e)).toList() ?? [],
      createdAt: json['created_at'] as String? ?? '',
      workTime: WorkTimeEntityConverter().fromJson(json['work_time'] ?? {}),
      mechanicInfo: ProfileModel.fromJson(json['mechanic_info'] ?? {}),
      map: MapEntity.fromJson(json['map'] ?? {}),
    );
  }
}
