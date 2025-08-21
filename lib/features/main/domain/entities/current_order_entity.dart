import 'package:equatable/equatable.dart';
import 'package:mechanic/features/main/domain/entities/address_entity.dart';
import 'package:mechanic/features/main/domain/entities/sub_order_entity.dart';
import 'package:mechanic/features/main/domain/entities/work_time_entity.dart';

class CurrentOrderEntity extends Equatable {
  final int id;
  final String status;
  final String orderTitle;
  @CurrentAddressEntityConverter()
  final CurrentAddressEntity currentAddress;
  final String price;
  final String acceptedAt;
  final String driverName;
  final String driverPhone;
  final String driverAvatar;
  final String paymentStatus;
  final String totalPrice;
  @SubOrderEntityConverter()
  final List<SubOrderEntity> suborders;
  @WorkTimeEntityConverter()
  final WorkTimeEntity workTime;
  final String completedAt;

  const CurrentOrderEntity({
    this.id = -1,
    this.status = '',
    this.orderTitle = '',
    this.currentAddress = const CurrentAddressEntity(),
    this.price = '',
    this.acceptedAt = '',
    this.driverName = '',
    this.driverPhone = '',
    this.driverAvatar = '',
    this.paymentStatus = '',
    this.totalPrice = '',
    this.suborders = const [],
    this.workTime = const WorkTimeEntity(),
    this.completedAt = '',
  });

  @override
  List<Object?> get props => [
        id,
        status,
        orderTitle,
        currentAddress,
        price,
        acceptedAt,
        driverName,
        driverPhone,
        driverAvatar,
        paymentStatus,
        totalPrice,
        suborders,
        workTime,
        completedAt,
      ];
}
