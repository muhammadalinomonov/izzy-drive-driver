import 'package:taxi_app/src/core/enums/order_enums.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/chat/data/model/report_response.dart';
import 'package:taxi_app/src/features/order_proccess/data/model/sub_order_model.dart';
import 'package:taxi_app/src/features/profile/data/model/profile_model.dart';
import 'package:taxi_app/src/features/profile/domain/entities/map_entity.dart';
import 'package:taxi_app/src/features/profile/domain/entities/order_history_entity.dart';
import 'package:taxi_app/src/features/profile/domain/entities/work_time_entity.dart';

class OrderHistoryModel extends OrderHistoryEntity {
  const OrderHistoryModel({
    super.id,
    super.orderTitle,
    super.price,
    super.totalPrice,
    super.status,
    super.acceptedAt,
    super.currentAddress,
    super.selectedMechanic,
    super.subOrders,
    super.createdAt,
    super.completedTime,
    super.mechanicInfo,
    super.map,
    super.address,
    super.workTimeEstimateMin,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    final orderMap = toMap(json['order']);
    return OrderHistoryModel(
      id: toInt(json['order_id'], -1),
      orderTitle: toStr(orderMap['title']),
      price: toDouble(orderMap['price']).toString(),
      totalPrice: toDouble(json['total_price']),
      status: OrderStatusConverter().fromJson(toStr(json['status'], 'pending')),
      acceptedAt: toStr(json['accepted_at']),
      completedTime: WorkTimeEntityConverter().fromJson(toMap(json['completed_time'])),
      address: toStr(json['address']),
      currentAddress: Address.fromJson(toMap(json['current_address'])),
      selectedMechanic: ProfileModel.fromJson(toMap(json['selected_mechanic'])),
      subOrders: toList(json['sub_orders'], (e) => SubOrderModel.fromJson(toMap(e))),
      createdAt: toStr(json['created_at']),
      mechanicInfo: ProfileModel.fromJson(toMap(json['mechanic_info'])),
      map: MapEntity.fromJson(toMap(json['map'])),
      workTimeEstimateMin: (json['work_time_estimate_min'] as num?)?.toInt() ??
          (toMap(json['order'])['work_time_estimate_min'] as num?)?.toInt(),
    );
  }
}
