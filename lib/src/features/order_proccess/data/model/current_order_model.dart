import 'package:taxi_app/src/core/enums/order_enums.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';
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
    super.workTimeEstimateMin,
  });

  factory CurrentOrderModel.fromJson(Map<String, dynamic> json) {
    return CurrentOrderModel(
      id: toInt(json['id'], -1),
      orderTitle: toStr(json['order_title']),
      price: toStr(json['price']),
      totalPrice: toStr(json['total_price']),
      status: OrderStatusConverter().fromJson(toStr(json['status'], 'pending')),
      acceptedAt: toStr(json['accepted_at']),
      completedAt: toStr(json['completed_at']),
      currentAddress: Address.fromJson(toMap(json['current_address'])),
      selectedMechanic: ProfileModel.fromJson(toMap(json['selected_mechanic'])),
      subOrders: toList(json['sub_orders'], (e) => SubOrderModel.fromJson(toMap(e))),
      createdAt: toStr(json['created_at']),
      workTime: WorkTimeEntityConverter().fromJson(toMap(json['work_time'])),
      mechanicInfo: ProfileModel.fromJson(toMap(json['mechanic_info'])),
      map: MapEntity.fromJson(toMap(json['map'])),
      workTimeEstimateMin: (json['work_time_estimate_min'] as num?)?.toInt(),
    );
  }
}
