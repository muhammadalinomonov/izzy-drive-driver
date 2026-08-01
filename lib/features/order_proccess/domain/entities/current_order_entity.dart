import 'package:equatable/equatable.dart';
import 'package:taxi_app/core/enums/order_enums.dart';
import 'package:taxi_app/features/chat/data/model/report_response.dart';
import 'package:taxi_app/features/order_proccess/domain/entities/sub_order_entity.dart';
import 'package:taxi_app/features/profile/data/model/profile_model.dart';
import 'package:taxi_app/features/profile/domain/entities/map_entity.dart';
import 'package:taxi_app/features/profile/domain/entities/work_time_entity.dart';

class CurrentOrderEntity extends Equatable {
  final int id;
  final String orderTitle;
  final String price;
  final String totalPrice;
  @OrderStatusConverter()
  final OrderStatus status;
  final String acceptedAt;
  final String completedAt;

  final Address currentAddress;
  final ProfileModel selectedMechanic;
  final List<SubOrderEntity> subOrders;
  final String createdAt;
  @WorkTimeEntityConverter()
  final WorkTimeEntity workTime;
  final ProfileModel mechanicInfo;
  final MapEntity map;
  final int? workTimeEstimateMin;

  const CurrentOrderEntity({
    this.id = -1,
    this.orderTitle = '',
    this.price = '',
    this.totalPrice = '',
    this.status = OrderStatus.pending,
    this.acceptedAt = '',
    this.completedAt = '',
    this.currentAddress = const Address(),
    this.selectedMechanic = const ProfileModel(),
    this.subOrders = const [],
    this.createdAt = '',
    this.workTime = const WorkTimeEntity(),
    this.mechanicInfo = const ProfileModel(),
    this.map = const MapEntity(),
    this.workTimeEstimateMin,
  });

  @override
  List<Object?> get props => [
    id,
    orderTitle,
    price,
    status,
    totalPrice,
    acceptedAt,
    completedAt,
    currentAddress,
    selectedMechanic,
    subOrders,
    createdAt,
    workTime,
    mechanicInfo,
    map,
    workTimeEstimateMin,
  ];
}
