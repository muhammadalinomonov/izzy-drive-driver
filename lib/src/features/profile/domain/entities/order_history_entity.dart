import 'package:equatable/equatable.dart';
import 'package:taxi_app/src/core/enums/order_enums.dart';
import 'package:taxi_app/src/features/chat/data/model/report_response.dart';
import 'package:taxi_app/src/features/order_proccess/data/model/current_order_model.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/sub_order_entity.dart';
import 'package:taxi_app/src/features/profile/data/model/profile_model.dart';
import 'package:taxi_app/src/features/profile/domain/entities/map_entity.dart';
import 'package:taxi_app/src/features/profile/domain/entities/work_time_entity.dart';

class OrderHistoryEntity extends Equatable {
  final int id;
  final String orderTitle;
  final String price;
  final double totalPrice;
  @OrderStatusConverter()
  final OrderStatus status;
  final String acceptedAt;

  final Address currentAddress;
  final ProfileModel selectedMechanic;
  final List<SubOrderEntity> subOrders;
  final String createdAt;
  @WorkTimeEntityConverter()
  final WorkTimeEntity completedTime;
  final ProfileModel mechanicInfo;
  final MapEntity map;
  final String address;

  const OrderHistoryEntity({
    this.id = -1,
    this.orderTitle = '',
    this.price = '',
    this.totalPrice = 0,
    this.status = OrderStatus.pending,
    this.acceptedAt = '',
    this.currentAddress = const Address(),
    this.selectedMechanic = const ProfileModel(),
    this.subOrders = const [],
    this.createdAt = '',
    this.completedTime = const WorkTimeEntity(),
    this.mechanicInfo = const ProfileModel(),
    this.map = const MapEntity(),
    this.address = '',
  });

  @override
  List<Object?> get props => [
    id,
    orderTitle,
    price,
    status,
    totalPrice,
    acceptedAt,
    currentAddress,
    selectedMechanic,
    subOrders,
    createdAt,
    completedTime,
    mechanicInfo,
    map,
    address,
  ];

  CurrentOrderEntity toCurrentOrderEntity(){
    return CurrentOrderEntity(
      orderTitle: orderTitle,
      price: price,
      subOrders: subOrders,
      totalPrice: totalPrice.toString(),
    );
  }
}
